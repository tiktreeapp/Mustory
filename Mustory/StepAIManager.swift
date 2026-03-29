import Foundation

class StepAIManager {
    static let shared = StepAIManager()
    private let apiKey = "5TQV73fpRPouGAncwRzvAoubV1DEnYnt0SK5CepInnWIMdVnPvaRLxEjMA9HjUQvK"
    private let endpoint = "https://api.stepfun.com/v1/chat/completions"
    
    struct SongInfo: Codable {
        var background: String = ""
        var writtenFor: String = ""
        var whatHappening: String = ""
        var sceneMood: String = ""
    }
    
    /// Detect the user's preferred language for localized AI responses
    private var userLanguage: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        if lang.hasPrefix("zh") { return "中文" }
        if lang.hasPrefix("ja") { return "日本語" }
        if lang.hasPrefix("ko") { return "한국어" }
        if lang.hasPrefix("fr") { return "Français" }
        if lang.hasPrefix("de") { return "Deutsch" }
        if lang.hasPrefix("es") { return "Español" }
        return "English"
    }
    
    private var currentContext: String {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let month = Calendar.current.component(.month, from: now)
        
        let season: String
        switch month {
        case 3...5: season = "Spring（春季）"
        case 6...8: season = "Summer（夏季）"
        case 9...11: season = "Autumn（秋季）"
        default: season = "Winter（冬季）"
        }
        
        let timeOfDay: String
        switch hour {
        case 5..<11: timeOfDay = "Morning（上午）"
        case 11..<14: timeOfDay = "Noon/Afternoon（中午/午后）"
        case 14..<18: timeOfDay = "Late Afternoon（傍晚）"
        case 18..<22: timeOfDay = "Evening（晚上）"
        default: timeOfDay = "Late Night（深夜）"
        }
        
        return "当前环境上下文：现在是\(season)，时间段是\(timeOfDay)。"
    }
    
    func fetchSongStory(songName: String, artistName: String) async -> SongInfo {
        let language = userLanguage
        let cacheKey = "SongAI_Cache_\(songName)_\(artistName)"
        
        // 尝试从本地读取缓存
        if let cacheData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedInfo = try? JSONDecoder().decode(SongInfo.self, from: cacheData) {
            print("Using cached AI story for \(songName)")
            return cachedInfo
        }
        
        let context = currentContext
        
        let prompt = """
        你是一位精通世界各种音乐的超级大师，拥有极其丰富的音乐知识和文学素养。
        
        根据歌名《\(songName)》、演唱者\(artistName)信息，请用\(language)语言详细告诉我这首歌的解析。
        
        特别注意：当前季节时间上下文是 \(context) 
        在输出第 4 点 "Scene mood" 时，请务必要将其内化为背景要素，而不要每次都用时间词语作为开头。
        
        1. Background（创作背景）：包括创作年代、风格演变、制作细节等。写3-5句话，深入专业。
        
        2. Written for（为谁而写）：灵感来源、传达的情感。写3-5句话，要有洞察力。
        
        3. What happening（背后的故事）：艺术家的人生经历或重要时刻。写3-5句话，有故事感。
        
        4. Scene mood（场景化描述）：你现在是一位擅长描写生活瞬间的文学作家。
        写一段非常具有画面感、安静的生活瞬间，传达这首歌最适合的现实心境。
        
        要求：
        - 必须合并成一段连贯的话（2-3句即可），自然过渡。
        - ⚠️极度重要：句式必须每次随机变化！绝对不要每次都以时间作为开头（比如“在十一月的清晨里”、“某个深夜”等）。
        - ⚠️绝对不要在回答中出现“第一部分”、“第二部分”、“场景化描述”等结构性字眼。
        - 严禁出现“也许你”“此刻你”“听歌”“耳机”“音乐”等提示用户行为的词汇。
        - 从随意的细节切入（可能是光影的变化、微风的温度、咖啡机发出的声响或是远处的车流），让 \(context) 的时间要素自然融入其中，接着引出这首歌适合的内心情绪。
        - 文风自然、安静、有很强的电影长镜头感，不要解释，不要总结。
        
        请严格按照 JSON 格式返回：
        {
          "background": "...",
          "writtenFor": "...",
          "whatHappening": "...",
          "sceneMood": "..."
        }
        """
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "step-1-8k",
            "messages": [
                ["role": "system", "content": "You are a world-class music expert and literary writer. Always respond in \(language)."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String,
               let contentData = content.data(using: .utf8) {
                let info = try JSONDecoder().decode(SongInfo.self, from: contentData)
                
                // 存入缓存
                if let encoded = try? JSONEncoder().encode(info) {
                    UserDefaults.standard.set(encoded, forKey: cacheKey)
                }
                
                return info
            }
        } catch {
            print("Step AI Error: \(error)")
        }
        
        return SongInfo(
            background: "Failed to load story details.",
            writtenFor: "Please check your network connection.",
            whatHappening: "Wait a moment and try again.",
            sceneMood: ""
        )
    }
}
