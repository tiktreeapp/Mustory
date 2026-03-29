import SwiftUI
import MusicKit

struct RecentView: View {
    @State private var musicManager = MusicManager.shared
    @State private var selectedSong: MusicKit.Song? // New state for sheet
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Recently Played Songs Section
                SectionView(title: "Songs", items: musicManager.recentSongs) { song in
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            selectedSong = song
                        } label: {
                            if let artwork = song.artwork {
                                ArtworkImage(artwork, width: 140, height: 140)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 140, height: 140)
                                    .overlay(Image(systemName: "music.note").foregroundColor(.gray))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            
                            Text(song.artistName)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 140, alignment: .leading)
                    }
                }
                
                // Recently Played Albums Section
                SectionView(title: "Albums", items: musicManager.recentAlbums) { album in
                    VStack(alignment: .leading, spacing: 8) {
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            if let artwork = album.artwork {
                                ArtworkImage(artwork, width: 140, height: 140)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 140, height: 140)
                                    .overlay(Image(systemName: "music.note").foregroundColor(.gray))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(album.title)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            
                            Text(album.artistName)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 140, alignment: .leading)
                    }
                }
                
                // Favorites Section (Songs) moved from Playlist
                SectionView(title: "Favorites", items: musicManager.favoriteSongs) { song in
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            selectedSong = song
                        } label: {
                            if let artwork = song.artwork {
                                ArtworkImage(artwork, width: 140, height: 140)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 140, height: 140)
                                    .overlay(Image(systemName: "music.note").foregroundColor(.gray))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            
                            Text(song.artistName)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 140, alignment: .leading)
                    }
                }
                
                Spacer(minLength: 120) // Space for bottom player bar
            }
            .padding(.top, 10)
        }
        .refreshable {
            await musicManager.fetchAllData()
        }
        .sheet(item: $selectedSong) { song in
            let queue = musicManager.favoriteSongs.contains(song) ? musicManager.favoriteSongs : musicManager.recentSongs
            SongDetailView(song: song, songQueue: queue)
                .presentationDragIndicator(.visible)
        }
    }
}

// 通用的 Section 视图
struct SectionView<T: MusicItem, Content: View>: View {
    let title: String
    let items: [T]
    let content: (T) -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No items found.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            
                            Button {
                                Task {
                                    await MusicManager.shared.fetchAllData()
                                }
                            } label: {
                                Text("Refresh")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 20)
                    } else {
                        ForEach(items, id: \.id) { item in
                            content(item)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecentView()
    }
}
