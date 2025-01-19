import Foundation

struct TimelineDisplayData: Identifiable, Equatable {
    let id = UUID()
    let script: String
    let imageData: Data?
    let lastImageData: Data?  // 用于存储上一个有图片的时间点的图片
    let provider: TimelineProvider
    let timestamp: Double
    
    static func == (lhs: TimelineDisplayData, rhs: TimelineDisplayData) -> Bool {
        return lhs.script == rhs.script &&
               lhs.imageData == rhs.imageData &&
               lhs.lastImageData == rhs.lastImageData &&
               lhs.timestamp == rhs.timestamp
    }
    
    var displayImage: Data? {
        imageData ?? lastImageData
    }
}

// 时间轴项目数据模型
struct TimelineItemData: Identifiable, Equatable, Hashable {
    let id: String
    var script: String
    var imageData: Data?
    var timestamp: Double
    var createdAt: Date
    var updatedAt: Date
    var imageUpdatedAt: Date?
    
    // 实现 Equatable 协议
    static func == (lhs: TimelineItemData, rhs: TimelineItemData) -> Bool {
        return lhs.script == rhs.script &&
               lhs.imageData == rhs.imageData &&
               lhs.timestamp == rhs.timestamp &&
               lhs.createdAt == rhs.createdAt &&
               lhs.updatedAt == rhs.updatedAt &&
               lhs.imageUpdatedAt == rhs.imageUpdatedAt
    }
    
    // 实现 Hashable 协议
    func hash(into hasher: inout Hasher) {
        hasher.combine(script)
        hasher.combine(imageData)
        hasher.combine(timestamp)
        hasher.combine(createdAt)
        hasher.combine(updatedAt)
        hasher.combine(imageUpdatedAt)
    }
}