import SwiftUI
import MusicKit

struct PlaylistListView: View {
    @State private var musicManager = MusicManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 20) {
                    ForEach(musicManager.libraryPlaylists, id: \.id) { playlist in
                        VStack(alignment: .leading, spacing: 8) {
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                if let artwork = playlist.artwork {
                                    ArtworkImage(artwork, width: 170, height: 170)
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 170, height: 170)
                                        .overlay(Image(systemName: "music.note").foregroundColor(.gray))
                                }
                            }
                            .buttonStyle(.plain)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(playlist.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                
                                Text(playlist.curatorName ?? "My Playlist")
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 170, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
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
