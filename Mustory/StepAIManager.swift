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

    func cachedSongStory(songId: String, songName: String, artistName: String) -> SongInfo? {
        for key in cacheKeys(songId: songId, songName: songName, artistName: artistName) {
            if let cacheData = UserDefaults.standard.data(forKey: key),
               let cachedInfo = try? JSONDecoder().decode(SongInfo.self, from: cacheData) {
                print("Using cached AI story for \(songName)")
                return cachedInfo
            }
        }

        return nil
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

    private func currentContext(language: String) -> String {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let month = Calendar.current.component(.month, from: now)

        if language == "中文" {
            let season: String
            switch month {
            case 3...5: season = "春季"
            case 6...8: season = "夏季"
            case 9...11: season = "秋季"
            default: season = "冬季"
            }

            let timeOfDay: String
            switch hour {
            case 5..<11: timeOfDay = "上午"
            case 11..<14: timeOfDay = "中午或午后"
            case 14..<18: timeOfDay = "傍晚"
            case 18..<22: timeOfDay = "晚上"
            default: timeOfDay = "深夜"
            }

            return "当前环境上下文：现在是\(season)，时间段是\(timeOfDay)。"
        }

        let season: String
        switch month {
        case 3...5: season = "spring"
        case 6...8: season = "summer"
        case 9...11: season = "autumn"
        default: season = "winter"
        }

        let timeOfDay: String
        switch hour {
        case 5..<11: timeOfDay = "morning"
        case 11..<14: timeOfDay = "noon or early afternoon"
        case 14..<18: timeOfDay = "late afternoon"
        case 18..<22: timeOfDay = "evening"
        default: timeOfDay = "late night"
        }

        return "Current context: it is \(season), during the \(timeOfDay)."
    }

    func fetchSongStory(songId: String, songName: String, artistName: String) async -> SongInfo {
        let language = userLanguage

        if let cachedInfo = cachedSongStory(songId: songId, songName: songName, artistName: artistName) {
            return cachedInfo
        }

        let context = currentContext(language: language)

        let prompt = """
        你是一位精通世界各种音乐的超级大师，拥有极其丰富的音乐知识和文学素养。

        输出语言硬性规则：
        - JSON 中所有字符串 value 必须只使用\(language)，并与用户系统语言保持一致。
        - 除歌名、艺人名、专辑名等专有名词外，禁止混用其它语言。
        - 不要因为下面的字段名或说明里出现中文/英文，就在结果里混用中英文。

        根据歌名《\(songName)》、演唱者\(artistName)信息，请用\(language)详细告诉我这首歌的解析。

        特别注意：当前季节时间上下文是 \(context)
        在输出第 4 点 "Scene mood" 时，请务必要将其内化为背景要素，而不要每次都用时间词语作为开头。

        1. Background（创作背景）：包括创作年代、风格演变、制作细节等。写3-5句话，深入专业。

        2. Written for（为谁而写）：灵感来源、传达的情感。写3-5句话，要有洞察力。

        3. What happening（背后的故事）：艺术家的人生经历或重要时刻。写3-5句话，有故事感。

        4. Scene mood（场景化描述）：你现在是一位擅长描写生活瞬间的文学作家。
        请结合当前播放歌曲的歌词主题、旋律气质、歌手表达和 \(context)，从心情、理想、小浪漫、小惬意、小思念、小故事这些角度中自然选取 2-3 个融合成一段。

        要求：
        - 必须合并成一段连贯的话，2-4 句即可，中文控制在 80-140 字左右，英文控制在 35-70 words 左右。
        - 内容要明显贴合这首歌本身，不要只写泛泛的生活氛围。
        - ⚠️极度重要：句式、切入角度和画面必须每首歌都变化！绝对不要每次都以时间、季节、光线、风、咖啡、窗边、街道作为开头。
        - ⚠️绝对不要在回答中出现“第一部分”、“第二部分”、“场景化描述”等结构性字眼。
        - 严禁出现“也许你”“此刻你”“听歌”“耳机”“音乐”等提示用户行为的词汇。
        - 可以从一个具体的小动作、一个未说出口的念头、一段关系里的细节、一次短暂出走、一个被藏起来的愿望切入。
        - 文风自然、安静、轻盈，有生活感和一点电影感，不要解释，不要总结，不要冗长。

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
            "model": "step-3.5-flash",
            "messages": [
                ["role": "system", "content": "You are a world-class music expert and literary writer. All JSON string values must be written only in \(language), matching the user's system language. Do not mix languages except proper nouns such as song titles and artist names."],
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

                if let encoded = try? JSONEncoder().encode(info) {
                    for key in cacheKeys(songId: songId, songName: songName, artistName: artistName) {
                        UserDefaults.standard.set(encoded, forKey: key)
                    }
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

    func cacheKey(songId: String, songName: String, artistName: String) -> String {
        "SongAI_Cache_v4_\(normalizedCacheValue(userLanguage))_\(songId)_\(normalizedCacheValue(songName))_\(normalizedCacheValue(artistName))"
    }

    private func cacheKeys(songId: String, songName: String, artistName: String) -> [String] {
        [
            cacheKey(songId: songId, songName: songName, artistName: artistName)
        ]
    }

    private func normalizedCacheValue(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }
}
