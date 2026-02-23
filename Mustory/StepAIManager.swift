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
    
    func fetchSongStory(songName: String, artistName: String) async -> SongInfo {
        let language = userLanguage
        
        let prompt = """
        你是一位精通世界各种音乐的超级大师，拥有极其丰富的音乐知识和文学素养。你了解各种音乐、歌曲、歌手相关的各类信息，擅长用文艺而深刻的语言来解读音乐。
        
        根据歌名《\(songName)》、演唱者\(artistName)信息，请用\(language)语言详细告诉我这首歌的：
        
        1. Background（创作背景）：深入挖掘这首歌的创作背景，包括创作的年代背景、音乐风格的演变、制作人和编曲信息等。请写3-5句话，有深度有细节。
        
        2. Written for（为谁而写/创作目的）：详细分析这首歌是写给谁的，创作的灵感来源是什么，歌词想要传达怎样的情感和意义。请写3-5句话，有情感有洞察。
        
        3. What happening（背后的故事/当时发生了什么）：讲述这首歌创作时艺术家的人生经历、音乐生涯中的重要时刻，或歌曲发布后产生的文化影响。请写3-5句话，有故事有深意。
        
        4. Scene mood（场景化描述）：用文艺的笔触，描绘一个最适合聆听这首歌的生活场景。比如在某个时刻、某种天气、某种心情下，这首歌会成为最好的陪伴。请写2-3句话，有画面感，要文艺。
        
        请严格按照 JSON 格式返回，不要包含任何其他文字。格式如下：
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
                ["role": "system", "content": "You are a world-class music expert and literary writer. You provide deep, insightful, and poetic analysis of music. Always respond in \(language)."],
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
                return try JSONDecoder().decode(SongInfo.self, from: contentData)
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
