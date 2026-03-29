import SwiftUI
import MusicKit

struct AlbumDetailView: View {
    let album: MusicKit.Album
    @State private var songs: MusicItemCollection<Track>?
    @State private var musicManager = MusicManager.shared
    @State private var selectedTrack: MusicKit.Song?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    // Album artwork and info
                    if let artwork = album.artwork {
                        ArtworkImage(artwork, width: 240, height: 240)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    
                    VStack(spacing: 8) {
                        Text(album.title)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text(album.artistName)
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                        
                        if let songs = songs {
                            Button {
                                if let firstTrack = songs.first, case .song(let firstSong) = firstTrack {
                                    musicManager.playSongInContext(song: firstSong, queue: songs.compactMap { if case .song(let s) = $0 { return s }; return nil })
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Play All")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            }
                            .padding(.top, 10)
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Track list
                    if let tracks = songs {
                        VStack(spacing: 0) {
                            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                                if case .song(let song) = track {
                                    Button {
                                        selectedTrack = song
                                    } label: {
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
            
            // Floating Bottom Player Bar
            MusicPlayerBar()
                .padding(.bottom, 10)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTrack) { song in
            SongDetailView(song: song, songQueue: songs?.compactMap { if case .song(let s) = $0 { return s }; return nil } ?? [])
                .presentationDragIndicator(.visible)
        }
        .task {
            // Load album tracks
            do {
                let detailedAlbum = try await album.with([.tracks])
                self.songs = detailedAlbum.tracks
            } catch {
                print("Failed to load album tracks: \(error)")
            }
        }
    }
}

