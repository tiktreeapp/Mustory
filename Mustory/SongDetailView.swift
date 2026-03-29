import SwiftUI
import MusicKit
import Combine
import MediaPlayer

// MARK: - Falling Emoji Model & View (Isolated Animation)
struct FallingEmojiData: Identifiable {
    let id = UUID()
    let emoji: String
    let x: CGFloat
    let scale: CGFloat
    let delay: Double
}

struct FallingEmojiView: View {
    let emojiData: FallingEmojiData
    
    @State private var y: CGFloat = -40
    @State private var opacity: Double = 0.6 // 彻底确保只有 60%
    
    var body: some View {
        Text(emojiData.emoji)
            .font(.system(size: 32 * emojiData.scale))
            .opacity(opacity) // 强制作用透明度
            .position(x: emojiData.x, y: y)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + emojiData.delay) {
                    // 🚀 掉落时间增加一倍，改为 12 秒，极其缓慢
                    withAnimation(.linear(duration: 12.0)) {
                        y = UIScreen.main.bounds.height + 100
                    }
                    
                    // 最后 2 秒渐隐
                    withAnimation(.easeOut(duration: 2.0).delay(10.0)) {
                        opacity = 0
                    }
                }
            }
    }
}


struct SongDetailView: View {
    let song: MusicKit.Song
    var songQueue: [MusicKit.Song] = []
    
    @State private var currentSong: MusicKit.Song
    @State private var musicManager = MusicManager.shared
    @State private var aiStory: StepAIManager.SongInfo = StepAIManager.SongInfo()
    @State private var isLoadingAI = true
    @State private var scrollOffset: CGFloat = 0
    @State private var fallingEmojis: [FallingEmojiData] = []
    
    @Environment(\.dismiss) var dismiss
    
    init(song: MusicKit.Song, songQueue: [MusicKit.Song] = []) {
        self.song = song
        self.songQueue = songQueue
        self._currentSong = State(initialValue: song)
    }
    
    var body: some View {
        ZStack {
            // Background
            ZStack {
                if let artwork = currentSong.artwork {
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
            
            ScrollView {
                VStack(spacing: 8) { 
                    // Geometry Tracker for Scroll Offset
                    GeometryReader { proxy in
                        let minY = proxy.frame(in: .global).minY
                        Color.clear.preference(key: ScrollOffsetKey.self, value: minY)
                    }
                    .frame(height: 0)
                    
                    // 1. Top Artwork (Scaling)
                    if let artwork = currentSong.artwork {
                        let scale = max(0.5, 1.0 - (scrollOffset < 50 ? (50 - scrollOffset) / 500.0 : 0))
                        
                        ArtworkImage(artwork, width: 260, height: 260)
                            .cornerRadius(12 * scale)
                            .shadow(color: .black.opacity(0.4), radius: 15 * scale, x: 0, y: 8 * scale)
                            .scaleEffect(scale)
                            .padding(.top, 150) // Spacing slightly adjusted
                            .padding(.bottom, 8) 
                            .animation(.spring(), value: scale)
                    }
                    
                    // 2. Song & Artist Name
                    VStack(spacing: 4) {
                        Text(currentSong.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                        
                        Text(currentSong.artistName)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 24)
                    
                    // 3. Player Controls - 宽度对齐
                    HStack {
                        Button(action: { musicManager.toggleFavorite(currentSong) }) {
                            Image(systemName: musicManager.isFavorite(currentSong) ? "star.fill" : "star")
                                .font(.system(size: 20))
                                .foregroundColor(musicManager.isFavorite(currentSong) ? .yellow : .white)
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: { musicManager.previous() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        
                        Spacer()
                        
                        Button(action: { musicManager.togglePlayback() }) {
                            Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                .frame(width: 40)
                                .padding(10)
                        }
                        
                        Spacer()
                        
                        Button(action: { musicManager.next() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        
                        Spacer()
                        
                        Button(action: { shareSong() }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    
                    // 4. Metadata
                    HStack(alignment: .top, spacing: 16) {
                        MetadataBlock(label: "Album", value: currentSong.albumTitle ?? "Unknown")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        MetadataBlock(label: "Time", value: formatDuration(currentSong.duration))
                            .frame(width: 60, alignment: .leading)
                        MetadataBlock(label: "Publish Date", value: formatDate(currentSong.releaseDate))
                            .frame(width: 90, alignment: .leading)
                    }
                    .padding(.horizontal, 24)
                    
                    // 5. AI Sections
                    VStack(alignment: .leading, spacing: 25) {
                        if !aiStory.sceneMood.isEmpty || isLoadingAI {
                            SceneMoodSection(content: aiStory.sceneMood, isLoading: isLoadingAI)
                                .padding(.top, 12) // 增加了 Top 数值 12 像素
                        }
                        
                        StorySection(title: "Background", content: aiStory.background, isLoading: isLoadingAI)
                        StorySection(title: "Written for", content: aiStory.writtenFor, isLoading: isLoadingAI)
                        StorySection(title: "What Happening", content: aiStory.whatHappening, isLoading: isLoadingAI)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 200)
                }
                .frame(width: UIScreen.main.bounds.width)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                let diff = value - scrollOffset
                // 只要有明显的向上滚动就触发
                if diff < -5 {
                    triggerEmojiAnimation()
                }
                scrollOffset = value
            }
            
            // Custom Pull bar indicator (Should stay on top)
            VStack {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 16)
                    .padding(.bottom, 0)
                Spacer()
            }
            
            // ✅ Falling Emojis layer (Top-most inside ZStack, NOT overlay)
            ZStack {
                ForEach(fallingEmojis) { emojiData in
                    FallingEmojiView(emojiData: emojiData)
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .task {
            // Initial play
            if songQueue.isEmpty {
                musicManager.play(song)
            } else {
                musicManager.playSongInContext(song: song, queue: songQueue)
            }
            await fetchAIStory()
            
            // Sync current song with music manager
            for await entry in NotificationCenter.default.publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange).values {
                if let newEntry = musicManager.currentEntry,
                   case .song(let newSong) = newEntry.item {
                    await MainActor.run {
                        self.currentSong = newSong
                        Task { await fetchAIStory() }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func fetchAIStory() async {
        isLoadingAI = true
        let result = await StepAIManager.shared.fetchSongStory(songName: currentSong.title, artistName: currentSong.artistName)
        
        await MainActor.run {
            aiStory = result
            isLoadingAI = false
            
            // ✅ 强制触发（无论场景有没有文字内容，立刻产生兜底特效）
            print("🔥 fetchAIStory fetched end. Triggering Emoji Animation")
            triggerEmojiAnimation()
        }
    }
    
    @State private var lastAnimationTimestamp: Date = Date.distantPast
    
    private func triggerEmojiAnimation() {
        guard Date().timeIntervalSince(lastAnimationTimestamp) > 0.6 else {
            print("🔥 triggerEmojiAnimation throttled!")
            return
        }
        lastAnimationTimestamp = Date()
        print("🔥 triggerEmojiAnimation started!")
        
        let foodEmojis = ["☕️", "🍷", "🍰", "🍔", "🍕", "🍦", "🍓", "🍺", "🍵", "🍎"]
        let animalEmojis = ["🐱", "🐶", "🐦", "🦋", "🐰", "🐻", "🐟", "🐢", "🦊", "🐬"]
        let activityEmojis = ["📖", "🎬", "🎮", "🚴‍♂️", "🚶", "🏃‍♂️", "🎨", "⛺️", "🎧", "📷"]
        
        let foundEmojis = EmojiManager.findEmojis(in: aiStory.sceneMood)
        var contextualEmojis = foundEmojis
        
        // 1. 获取基础表情（如果有匹配，混入默认✨🎵；如果没匹配，用兜底库）
        if contextualEmojis.isEmpty {
            contextualEmojis = ["✨", "🎵", "🎶", "🎈", "🌟", "🍂", "🍃", "🌸"]
        } else {
            contextualEmojis.append(contentsOf: ["✨", "🎵"]) 
        }
        
        contextualEmojis.shuffle()
        
        // 2. 组装最终要掉落的表情库
        var emojisToDrop: [String] = []
        emojisToDrop.append(contentsOf: contextualEmojis.prefix(3)) // 选前3个意境/默认
        
        // 3. 增加三个新维度的随机表情
        if let food = foodEmojis.randomElement() { emojisToDrop.append(food) }
        if let animal = animalEmojis.randomElement() { emojisToDrop.append(animal) }
        if let activity = activityEmojis.randomElement() { emojisToDrop.append(activity) }
        
        // 打乱最终这 6 个表情的掉落顺序
        emojisToDrop.shuffle()
        
        let screenWidth = UIScreen.main.bounds.width
        
        for (i, emojiStr) in emojisToDrop.enumerated() {
            let newEmoji = FallingEmojiData(
                emoji: emojiStr,
                x: screenWidth / 2.0 + CGFloat.random(in: -70...70), // 绝对居中附近随机偏移
                scale: CGFloat.random(in: 1.0...2.0), // 缩放比例
                delay: Double(i) * 1.5 // 掉落间隔拉长到 1.5 秒一个，非常舒缓
            )
            
            fallingEmojis.append(newEmoji)
        }
        print("🔥 Emojis appended, count is now: \(fallingEmojis.count)")
        
        // 清理越界的旧元素，保持性能
        if fallingEmojis.count > 15 {
            fallingEmojis.removeFirst(fallingEmojis.count - 15)
        }
    }
    
    private func shareSong() {
        let shareText = "Know the story, Feel the Music by Mustory https://apps.apple.com/app/mustory-play-favorite-music/id6759556508"
        var items: [Any] = [shareText]
        if let url = currentSong.url {
            items.append(url)
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // 寻找最顶层的 ViewController
        if let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
           var topController = keyWindow.rootViewController {
            
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            // 如果是 iPad，需要配置 popoverPresentationController
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topController.present(activityVC, animated: true)
        }
    }
    
    // ... helpers formatDuration, formatDate remain same ...
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

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
                HStack {
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                Text(content)
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(7)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct SceneMoodSection: View {
    let content: String
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                Text("Scene")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            if isLoading {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                Text(content)
                    .font(.system(size: 17))
                    .italic()
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(7)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
            }
        }
    }
}

