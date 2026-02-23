import Foundation
import MusicKit
import Combine
import MediaPlayer

@Observable
class MusicManager {
    static let shared = MusicManager()
    
    var authorizationStatus: MusicAuthorization.Status = .notDetermined
    
    // 最近播放数据
    var recentSongs: [MusicKit.Song] = []
    var recentAlbums: [MusicKit.Album] = []
    var recentPlaylists: [MusicKit.Playlist] = []
    
    // 资料库歌单
    var favoriteSongs: [MusicKit.Song] = []
    var libraryPlaylists: [MusicKit.Playlist] = []
    
    // 播放状态
    private let musicPlayer = SystemMusicPlayer.shared
    var currentEntry: MusicKit.MusicPlayer.Queue.Entry?
    var isPlaying: Bool = false
    
    private init() {
        authorizationStatus = MusicAuthorization.currentStatus
        
        // Start generating notifications for SystemMusicPlayer
        MPMusicPlayerController.systemMusicPlayer.beginGeneratingPlaybackNotifications()
        
        // Use NotificationCenter for SystemMusicPlayer as it is most reliable for system-wide sync
        NotificationCenter.default.addObserver(forName: .MPMusicPlayerControllerPlaybackStateDidChange, object: nil, queue: .main) { _ in
            self.updatePlaybackState()
        }
        
        NotificationCenter.default.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: nil, queue: .main) { _ in
            self.updateCurrentEntry()
        }
        
        NotificationCenter.default.addObserver(forName: .MPMusicPlayerControllerQueueDidChange, object: nil, queue: .main) { _ in
            self.updateCurrentEntry()
        }
        
        // Modern MusicKit AsyncSequence as a backup
        Task {
            for await _ in musicPlayer.state.objectWillChange.values {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay to get the 'did' state
                await MainActor.run {
                    self.isPlaying = self.musicPlayer.state.playbackStatus == .playing
                }
            }
        }
        
        // Initial state
        self.isPlaying = self.musicPlayer.state.playbackStatus == .playing
        self.currentEntry = self.musicPlayer.queue.currentEntry
    }
    
    func requestAuthorization() async {
        // 使用 Task 包装以防主线程意外阻塞，且设置超时保护思维
        let status = await withDefaultTimeout(await MusicAuthorization.request(), seconds: 10) ?? .denied
        
        await MainActor.run {
            self.authorizationStatus = status
        }
        
        if status == .authorized {
            await fetchAllData()
        }
    }
    
    // Refresh authorization status (e.g. when opening Settings)
    @MainActor
    func refreshAuthorizationStatus() async {
        let current = MusicAuthorization.currentStatus
        self.authorizationStatus = current
    }
    
    // 私有辅助：超时机制
    private func withDefaultTimeout<T>(_ operation: @autoclosure @escaping () async -> T, seconds: TimeInterval) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
    
    func fetchAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchRecentlyPlayed() }
            group.addTask { await self.fetchLibraryPlaylists() }
            group.addTask { await self.fetchFavoriteSongs() }
        }
    }
    
    // Fetch recently played content categorized
    func fetchRecentlyPlayed() async {
        await withTaskGroup(of: Void.self) { group in
            // Request 1: Songs (Directly requestable)
            group.addTask {
                do {
                    var request = MusicRecentlyPlayedRequest<MusicKit.Song>()
                    request.limit = 30
                    let response = try await request.response()
                    await MainActor.run {
                        self.recentSongs = Array(response.items)
                    }
                } catch {
                    print("Recently played songs fetch error: \(error)")
                }
            }
            
            // Request 2: Albums (Server-side + Library Fallback)
            group.addTask {
                do {
                    // Try server-side first
                    let serverRequest = MusicRecentlyPlayedRequest<MusicKit.RecentlyPlayedMusicItem>()
                    let serverResponse = try await serverRequest.response()
                    
                    // Also try Library-side (often more reliable for containers)
                    var libraryRequest = MusicLibraryRequest<MusicKit.Album>()
                    libraryRequest.limit = 20
                    libraryRequest.sort(by: \.lastPlayedDate, ascending: false)
                    let libraryResponse = try await libraryRequest.response()
                    
                    await MainActor.run {
                        var combined = [MusicKit.Album]()
                        // Add server items
                        for item in serverResponse.items {
                            if case .album(let album) = item {
                                combined.append(album)
                            }
                        }
                        // Add library items (deduplicating by ID)
                        for album in libraryResponse.items {
                            if !combined.contains(where: { $0.id == album.id }) {
                                combined.append(album)
                            }
                        }
                        self.recentAlbums = combined
                    }
                } catch {
                    print("Recently played albums fetch error: \(error)")
                }
            }
            
            // Request 3: Playlists (Server-side + Library Fallback)
            group.addTask {
                do {
                    // Try server-side first
                    let serverRequest = MusicRecentlyPlayedRequest<MusicKit.RecentlyPlayedMusicItem>()
                    let serverResponse = try await serverRequest.response()
                    
                    // Also try Library-side
                    var libraryRequest = MusicLibraryRequest<MusicKit.Playlist>()
                    libraryRequest.limit = 20
                    libraryRequest.sort(by: \.lastPlayedDate, ascending: false)
                    let libraryResponse = try await libraryRequest.response()
                    
                    await MainActor.run {
                        var combined = [MusicKit.Playlist]()
                        // Add server items
                        for item in serverResponse.items {
                            if case .playlist(let playlist) = item {
                                combined.append(playlist)
                            }
                        }
                        // Add library items
                        for playlist in libraryResponse.items {
                            if !combined.contains(where: { $0.id == playlist.id }) {
                                combined.append(playlist)
                            }
                        }
                        self.recentPlaylists = combined
                    }
                } catch {
                    print("Recently played playlists fetch error: \(error)")
                }
            }
        }
    }
    
    // 获取资料库播放列表
    func fetchLibraryPlaylists() async {
        let request = MusicLibraryRequest<MusicKit.Playlist>()
        do {
            let response = try await request.response()
            await MainActor.run {
                self.libraryPlaylists = Array(response.items)
            }
        } catch {
            print("Fetch library playlists failed: \(error)")
        }
    }
    
    // Favorites management
    @MainActor
    func isFavorite(_ song: MusicKit.Song) -> Bool {
        return favoriteSongs.contains(where: { $0.id == song.id })
    }
    
    @MainActor
    func toggleFavorite(_ song: MusicKit.Song) {
        if let index = favoriteSongs.firstIndex(where: { $0.id == song.id }) {
            favoriteSongs.remove(at: index)
        } else {
            favoriteSongs.append(song)
        }
    }
    
    // Fetch library favorite songs
    func fetchFavoriteSongs() async {
        let request = MusicLibraryRequest<MusicKit.Playlist>()
        do {
            let response = try await request.response()
            // Try to match system "Favorites" playlist by various localized names
            let favoritesPlaylist = response.items.first(where: {
                let name = $0.name.lowercased()
                return name == "favorites" ||
                       name == "favorite songs" ||
                       name == "favourites" ||
                       name == "favourite songs" ||
                       name == "收藏" ||
                       name == "喜爱的歌曲" ||
                       name == "喜爱歌曲" ||
                       name == "お気に入り" ||
                       name == "즐겨찾기"
            })
            
            if let playlist = favoritesPlaylist {
                let detailedPlaylist = try await playlist.with([.tracks])
                await MainActor.run {
                    self.favoriteSongs = detailedPlaylist.tracks?.compactMap { track in
                        if case .song(let song) = track { return song }
                        return nil
                    } ?? []
                }
            } else {
                // Fallback: fetch recently added songs from library as "favorites"
                var songRequest = MusicLibraryRequest<MusicKit.Song>()
                songRequest.limit = 50
                songRequest.sort(by: \.libraryAddedDate, ascending: false)
                let songResponse = try await songRequest.response()
                await MainActor.run {
                    self.favoriteSongs = Array(songResponse.items)
                }
            }
        } catch {
            print("Fetch favorite songs failed: \(error)")
        }
    }
    
    // 播放控制
    func play(_ item: any PlayableMusicItem) {
        Task {
            do {
                musicPlayer.queue = [item]
                try await musicPlayer.play()
            } catch {
                print("Playback failed: \(error)")
            }
        }
    }
    
    /// Play a song within a list context so next/previous buttons work through the queue
    func playSongInContext(song: MusicKit.Song, queue: [MusicKit.Song]) {
        Task {
            do {
                musicPlayer.queue = MusicPlayer.Queue(for: queue, startingAt: song)
                try await musicPlayer.play()
            } catch {
                print("Playback in context failed: \(error)")
            }
        }
    }
    
    func togglePlayback() {
        if isPlaying {
            musicPlayer.pause()
        } else {
            Task {
                try? await musicPlayer.play()
            }
        }
    }
    
    func next() {
        Task {
            try? await musicPlayer.skipToNextEntry()
        }
    }
    
    func previous() {
        Task {
            if musicPlayer.playbackTime > 3 {
                musicPlayer.playbackTime = 0
            } else {
                try? await musicPlayer.skipToPreviousEntry()
            }
        }
    }
    
    private func updatePlaybackState() {
        Task { @MainActor in
            self.isPlaying = self.musicPlayer.state.playbackStatus == .playing
        }
    }
    
    private func updateCurrentEntry() {
        Task { @MainActor in
            self.currentEntry = self.musicPlayer.queue.currentEntry
        }
    }
}

