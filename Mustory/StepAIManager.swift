import Foundation

class StepAIManager {
    static let shared = StepAIManager()
    private let apiKey = "5TQV73fpRPouGAncwRzvAoubV1DEnYnt0SK5CepInnWIMdVnPvaRLxEjMA9HjUQvK"
    private let endpoint = "https://api.stepfun.com/v1/chat/completions"
    
    struct SongInfo: Codable {
        var background: String = ""
        var writtenFor: String = ""
        var whatHappening: String = ""
    }
    
    func fetchSongStory(songName: String, artistName: String) async -> SongInfo {
        let prompt = """
        你是一位精通世界各种音乐的超级大师，了解各种音乐、歌曲、歌手相关的各类信息。
        根据歌名《\(songName)》、演唱者\(artistName)信息，请告诉我这首歌的：
        1. Background (创作背景)
        2. Written for (为谁而写/创作目的)
        3. What happening (背后的故事/当时发生了什么)
        
        请严格按照 JSON 格式返回，不要包含任何其他文字。格式如下：
        {
          "background": "...",
          "writtenFor": "...",
          "whatHappening": "..."
        }
        要求简洁一点。
        """
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "step-1-8k",
            "messages": [
                ["role": "system", "content": "You are a music expert assistant."],
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
            whatHappening: "Wait a moment and try again."
        )
    }
}
