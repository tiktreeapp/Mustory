import SwiftUI
import MusicKit

struct PlaylistDetailView: View {
    let playlist: MusicKit.Playlist
    @State private var songs: MusicItemCollection<Track>?
    @State private var musicManager = MusicManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Playlist artwork and info
                if let artwork = playlist.artwork {
                    ArtworkImage(artwork, width: 240, height: 240)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                VStack(spacing: 8) {
                    Text(playlist.name)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    if let curator = playlist.curatorName {
                        Text(curator)
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                // Track list
                if let songs = songs {
                    VStack(spacing: 0) {
                        ForEach(Array(songs.enumerated()), id: \.element.id) { index, track in
                            if case .song(let song) = track {
                                NavigationLink(destination: SongDetailView(song: song)) {
                                    SongRow(index: index + 1, song: track)
                                }
                                .buttonStyle(.plain)
                            } else {
                                SongRow(index: index + 1, song: track)
                                    .onTapGesture {
                                        musicManager.play(track)
                                    }
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
                
                Spacer(minLength: 120)
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Load playlist tracks
            do {
                let detailedPlaylist = try await playlist.with([.tracks])
                self.songs = detailedPlaylist.tracks
            } catch {
                print("Failed to load playlist tracks: \(error)")
            }
        }
    }
}
