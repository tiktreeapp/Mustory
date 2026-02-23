import SwiftUI
import MusicKit

struct PlaylistListView: View {
    @State private var musicManager = MusicManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Favorites Section (Songs)
                SectionView(title: "Favorites", items: musicManager.favoriteSongs) { song in
                    NavigationLink(destination: SongDetailView(song: song, songQueue: musicManager.favoriteSongs)) {
                        MusicItemCell(
                            title: song.title,
                            subtitle: song.albumTitle ?? "",
                            artwork: song.artwork
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // My Playlists Section
                // Here we simplify by showing all playlists in one section.
                SectionView(title: "All Playlists", items: musicManager.libraryPlaylists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        MusicItemCell(
                            title: playlist.name,
                            subtitle: playlist.curatorName ?? "My Playlist",
                            artwork: playlist.artwork
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 120)
            }
            .padding(.top, 10)
        }
        .refreshable {
            await musicManager.fetchAllData()
        }
    }
}

#Preview {
    NavigationStack {
        PlaylistListView()
    }
}
