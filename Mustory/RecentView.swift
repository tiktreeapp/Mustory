import SwiftUI
import MusicKit

struct RecentView: View {
    @State private var musicManager = MusicManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Recently Played Songs Section
                SectionView(title: "Songs", items: musicManager.recentSongs) { song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        MusicItemCell(
                            title: song.title,
                            subtitle: song.albumTitle ?? "",
                            artwork: song.artwork
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Recently Played Albums Section
                SectionView(title: "Albums", items: musicManager.recentAlbums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        MusicItemCell(
                            title: album.title,
                            subtitle: album.artistName,
                            artwork: album.artwork
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Recently Played Playlists Section
                SectionView(title: "Playlists", items: musicManager.recentPlaylists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        MusicItemCell(
                            title: playlist.name,
                            subtitle: playlist.curatorName ?? "",
                            artwork: playlist.artwork
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 120) // Space for bottom player bar
            }
            .padding(.top, 10)
        }
        .refreshable {
            await musicManager.fetchAllData()
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
