import SwiftUI
import MusicKit

struct MusicPlayerBar: View {
    @State private var musicManager = MusicManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side: Artwork and Info (Interactive Link)
            Group {
                if let entry = musicManager.currentEntry,
                   case .song(let song) = entry.item {
                    NavigationLink(destination: SongDetailView(song: song)) {
                        leftContent
                    }
                    .buttonStyle(.plain)
                } else {
                    leftContent
                }
            }
            
            Spacer()
            
            // Right side: Player Controls (Non-interactive with Link)
            HStack(spacing: 20) {
                Button {
                    musicManager.previous()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                
                Button {
                    musicManager.togglePlayback()
                } label: {
                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                
                Button {
                    musicManager.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
            }
            .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 35)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay {
                    RoundedRectangle(cornerRadius: 35)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var leftContent: some View {
        HStack(spacing: 12) {
            if let artwork = musicManager.currentEntry?.artwork {
                ArtworkImage(artwork, width: 48, height: 48)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .overlay(Image(systemName: "music.note").foregroundColor(.gray))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(musicManager.currentEntry?.title ?? "Not Playing")
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(musicManager.currentEntry?.subtitle ?? "Select a song to start")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()
            MusicPlayerBar()
        }
    }
}
