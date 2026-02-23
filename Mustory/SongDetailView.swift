import SwiftUI
import MusicKit

struct SongDetailView: View {
    let song: MusicKit.Song
    @State private var musicManager = MusicManager.shared
    @State private var aiStory: StepAIManager.SongInfo = StepAIManager.SongInfo()
    @State private var isLoadingAI = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Top Artwork
                    if let artwork = song.artwork {
                        ArtworkImage(artwork, width: 260, height: 260)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
                            .padding(.top, 10)
                    }
                    
                    // 2. Song & Artist Name
                    VStack(spacing: 4) {
                        Text(song.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(song.artistName)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal)
                    
                    // 3. Player Controls
                    HStack(spacing: 32) {
                        Button(action: { musicManager.toggleFavorite(song) }) {
                            Image(systemName: musicManager.isFavorite(song) ? "star.fill" : "star")
                                .font(.system(size: 20))
                                .foregroundColor(musicManager.isFavorite(song) ? .yellow : .white)
                        }
                        
                        Button(action: { musicManager.previous() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: { musicManager.togglePlayback() }) {
                            Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                        
                        Button(action: { musicManager.next() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: { shareSong() }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // 4. Metadata (Album, Time, Date)
                    HStack(alignment: .top, spacing: 16) {
                        MetadataBlock(label: "Album", value: song.albumTitle ?? "Unknown")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        MetadataBlock(label: "Time", value: formatDuration(song.duration))
                            .frame(width: 60, alignment: .leading)
                        MetadataBlock(label: "Publish Date", value: formatDate(song.releaseDate))
                            .frame(width: 90, alignment: .leading)
                    }
                    .padding(.horizontal, 24)
                    
                    // 5. AI Sections
                    VStack(alignment: .leading, spacing: 25) {
                        StorySection(title: "Background", content: aiStory.background, isLoading: isLoadingAI)
                        StorySection(title: "Written for", content: aiStory.writtenFor, isLoading: isLoadingAI)
                        StorySection(title: "What Happening", content: aiStory.whatHappening, isLoading: isLoadingAI)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
                .frame(width: geo.size.width) // ← 关键：用屏幕实际宽度约束，强制文本换行
            }
        }
        .background {
            // 背景层：模糊封面 + 渐变，单独 ignoresSafeArea
            ZStack {
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 1000, height: 1000)
                        .blur(radius: 60)
                        .scaleEffect(1.5)
                }
                Color.black.opacity(0.5)
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
        .task {
            musicManager.play(song)
            await fetchAIStory()
        }
    }
    
    private func fetchAIStory() async {
        isLoadingAI = true
        aiStory = await StepAIManager.shared.fetchSongStory(songName: song.title, artistName: song.artistName)
        isLoadingAI = false
    }
    
    private func shareSong() {
        guard let url = song.url else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "00:00" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

struct MetadataBlock: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }
}

struct StorySection: View {
    let title: String
    let content: String
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.vertical)
            } else {
                Text(content)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
