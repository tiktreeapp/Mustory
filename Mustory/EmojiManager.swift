import Foundation

struct EmojiManager {
    static let keywordToEmoji: [String: String] = [
        // Feelings & Emotions
        "love": "❤️", "heart": "❤️", "愛": "❤️", "爱": "❤️",
        "love you": "🤟", "爱你": "🤟",
        "miss": "💔", "missing": "💔", "lost": "💔", "pain": "💔", "伤心": "💔", "痛": "💔", "想念": "💔",
        "kiss": "💋", "吻": "💋",
        "hug": "🤗", "抱": "🤗",
        "happy": "😊", "smile": "😊", "喜": "😊", "笑": "😊", "开心": "😊", "快乐": "😊",
        "sad": "😢", "cry": "😢", "伤": "😢", "哭": "😢", "难过": "😢",
        "angry": "😡", "mad": "😡", "怒": "😡", "生气": "😡",
        "fear": "😨", "scared": "😨", "怕": "😨", "害怕": "😨",
        "tired": "😴", "sleepy": "😴", "累": "😴", "困": "😴",
        "relax": "😌", "calm": "😌", "放松": "😌", "静": "😌",
        "surprise": "😮", "wow": "😮", "惊": "😮", "惊讶": "😮",
        "regret": "😔", "sorry": "😔", "后悔": "😔", "对不起": "😔",
        "hope": "🌈", "wish": "🌈", "希望": "🌈", "愿望": "🌈",
        "dream": "🌟", "sleep": "🌟", "梦": "🌟", "梦想": "🌟",

        // Nature & Weather
        "fire": "🔥", "hot": "🔥", "火": "🔥", "热": "🔥",
        "sun": "☀️", "light": "☀️", "日": "☀️", "阳": "☀️", "阳光": "☀️",
        "night": "🌙", "dark": "🌙", "夜": "🌙", "黑": "🌙",
        "star": "✨", "shine": "✨", "星": "✨", "闪": "✨",
        "rain": "🌧️", "water": "🌧️", "雨": "🌧️", "水": "🌧️",
        "snow": "❄️", "cold": "❄️", "雪": "❄️", "冷": "❄️",
        "wind": "🌬️", "风": "🌬️",
        "storm": "⛈️", "thunder": "⛈️", "雷": "⛈️",
        "fog": "🌫️", "mist": "🌫️", "雾": "🌫️",
        "sky": "☁️", "cloud": "☁️", "天": "☁️", "天空": "☁️", "云": "☁️",
        "sea": "🌊", "ocean": "🌊", "海": "🌊", "大海": "🌊",
        "spring": "🌸", "春": "🌸",
        "summer": "🌞", "夏": "🌞",
        "autumn": "🍂", "fall": "🍂", "秋": "🍂",
        "winter": "❄️", "冬": "❄️",

        // Time & Abstract
        "morning": "🌅", "早": "🌅",
        "noon": "🏙️", "中午": "🏙️",
        "evening": "🌇", "黄昏": "🌇",
        "tonight": "🌃", "今晚": "🌃",
        "midnight": "🌌", "深夜": "🌌",
        "today": "📅", "今天": "📅",
        "tomorrow": "➡️", "明天": "➡️",
        "yesterday": "⏪", "昨天": "⏪",
        "forever": "♾️", "永远": "♾️",
        "time": "⌛", "clock": "⌛", "时间": "⌛", "钟": "⌛",
        "world": "🌍", "earth": "🌍", "世界": "🌍", "地球": "🌍",

        // Actions & Entities
        "run": "🏃", "running": "🏃", "跑": "🏃",
        "walk": "🚶", "walking": "🚶", "走": "🚶", "漫步": "🚶",
        "stop": "✋", "停": "✋",
        "wait": "⏳", "waiting": "⏳", "等": "⏳", "等待": "⏳",
        "leave": "👋", "left": "👋", "离开": "👋", "别": "👋",
        "come": "➡️", "back": "⬅️", "回来": "⬅️",
        "fly": "🕊️", "flying": "🕊️", "飞": "🕊️", "飞行": "🕊️",
        "dance": "💃", "party": "💃", "舞": "💃", "跳舞": "💃",
        "music": "🎵", "song": "🎵", "歌": "🎵", "乐": "🎵", "旋律": "🎵",
        "look": "👀", "see": "👀", "看": "👀", "凝视": "👀",
        "listen": "👂", "hear": "👂", "听": "👂",
        "say": "🗣️", "tell": "🗣️", "说": "🗣️", "道": "🗣️",
        "king": "👑", "王": "👑", "帝": "👑",
        "we": "🤝", "us": "🤝", "我们": "🤝",
        "baby": "💖", "dear": "💖", "宝贝": "💖", "亲爱的": "💖",
        "girl": "👧", "boy": "👦", "女孩": "👧", "男孩": "👦",
        "friend": "🧑🤝🧑", "朋友": "🧑🤝🧑",
        "together": "👫", "一起": "👫", "陪伴": "👫",

        // Festivals & Celebrations
        "spring festival": "🧧", "chinese new year": "🧧", "春节": "🧧", "过年": "🧧",
        "lantern festival": "🏮", "元宵": "🏮",
        "qingming": "🌿", "tomb sweeping": "🌿", "清明": "🌿",
        "dragon boat festival": "🐉", "端午": "🐉",
        "mid autumn festival": "🌕", "mid-autumn": "🌕", "中秋": "🌕", "月圆": "🌕",
        "double seventh": "💞", "qixi": "💞", "七夕": "💞",
        "double ninth": "⛰️", "重阳": "⛰️",
        "national day": "🇨🇳", "national day of china": "🇨🇳", "国庆": "🇨🇳", "国庆节": "🇨🇳", "十一": "🇨🇳",
        "new year's day": "🎉", "yuan dan": "🎉", "元旦": "🎉",
        "dongzhi": "🥟", "winter solstice": "🥟", "冬至": "🥟", "饺子": "🥟",
        "new year": "🎆", "new year's eve": "🎆", "新年": "🎆",
        "valentine": "💘", "valentine's day": "💘", "情人节": "💘",
        "christmas": "🎄", "xmas": "🎄", "圣诞": "🎄",
        "halloween": "🎃", "万圣节": "🎃",
        "easter": "🐣", "复活节": "🐣",
        "thanksgiving": "🦃", "感恩节": "🦃",
        "independence day": "🇺🇸", "4th of july": "🇺🇸",
        "birthday": "🎂", "生日": "🎂",
        "wedding": "💍", "marry": "💍", "婚礼": "💍",

        // Objects & Places
        "road": "🛣️", "way": "🛣️", "路": "🛣️", "道路": "🛣️",
        "home": "🏠", "house": "🏠", "家": "🏠",
        "city": "🌆", "town": "🌆", "城市": "🌆", "镇": "🌆",
        "street": "🏙️", "街": "🏙️", "街道": "🏙️",
        "car": "🚗", "drive": "🚗", "车": "🚗", "开车": "🚗",
        "subway": "🚆", "train": "🚆", "地铁": "🚆", "火车": "🚆",
        "money": "💰", "cash": "💰", "钱": "💰", "财富": "💰",
        "drink": "🍷", "wine": "🍷", "酒": "🍷", "醉": "🍷",
        "coffee": "☕", "咖啡": "☕",
        "phone": "📱", "call": "📱", "电话": "📱"
    ]
    
    static func findEmojis(in text: String) -> [String] {
        var found: [String] = []
        let lowerText = text.lowercased()
        
        for (keyword, emoji) in keywordToEmoji {
            if lowerText.contains(keyword.lowercased()) {
                found.append(emoji)
            }
        }
        
        return found
    }
}
