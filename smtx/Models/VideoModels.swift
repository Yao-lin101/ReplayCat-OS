import Foundation

// 视频平台枚举
enum VideoPlatform: String, Codable {
    case bilibili
    case douyin
    case kuaishou
}

// 解析结果模型
struct VideoInfo: Codable, Hashable {
    let title: String
    let description: String
    let videoUrl: String
    let coverUrl: String
    let duration: Int
    let platform: VideoPlatform
    let originalId: String
    let authorName: String?
    let authorId: String?
    let platformExtra: [String: String]?  // 修改为 [String: String] 以支持 Codable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(videoUrl)
        hasher.combine(coverUrl)
        hasher.combine(duration)
        hasher.combine(platform)
        hasher.combine(originalId)
        hasher.combine(authorName)
        hasher.combine(authorId)
    }
    
    // 添加 JSON 转换方法
    func toJSONString() -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return ""
        }
        return jsonString
    }
    
    static func fromJSONString(_ jsonString: String) -> VideoInfo? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(VideoInfo.self, from: data)
    }
    
    static func == (lhs: VideoInfo, rhs: VideoInfo) -> Bool {
        return lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.videoUrl == rhs.videoUrl &&
               lhs.coverUrl == rhs.coverUrl &&
               lhs.duration == rhs.duration &&
               lhs.platform == rhs.platform &&
               lhs.originalId == rhs.originalId &&
               lhs.authorName == rhs.authorName &&
               lhs.authorId == rhs.authorId
    }
} 