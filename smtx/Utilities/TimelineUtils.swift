import Foundation

enum TimelineError: Error {
    case invalidTimelineItems
}

class TimelineUtils {
    /// 生成时间轴数据
    /// - Parameters:
    ///   - items: 时间轴项目列表
    ///   - duration: 总时长
    ///   - imageNames: 时间戳到图片名称的映射（可选）
    ///   - includeImages: 是否在返回值中包含图片数据
    /// - Returns: 时间轴数据和图片字典
    static func generateTimelineData(
        from items: [TimelineItem]?,
        duration: TimeInterval,
        imageNames: [String: String]? = nil,
        includeImages: Bool = true
    ) throws -> (timelineData: Data, images: [String: Data]) {
        var timelineData = Data()
        var timelineImages: [String: Data] = [:]
        
        if let items = items {
            var timelineJson: [String: Any] = [:]
            var images: [String] = []
            var events: [[String: Any]] = []
            
            for item in items {
                var event: [String: Any] = [
                    "time": item.timestamp,
                    "id": item.id ?? ""
                ]
                
                // 添加文本内容
                if let script = item.script, !script.isEmpty {
                    event["text"] = script
                }
                
                // 处理图片
                if let imageData = item.image {
                    // 如果提供了图片名称映射，使用映射的名称
                    let imageName: String
                    if let providedName = imageNames?[item.id ?? UUID().uuidString] {
                        // 使用提供的名称（基于imageUpdatedAt的时间戳）
                        imageName = providedName
                        print("📝 Using image name for timestamp \(item.timestamp): \(imageName)")
                    } else {
                        print("❌ No image name provided for timestamp \(item.timestamp)")
                        return (Data(), [:])
                    }
                    
                    // 只有在需要包含图片时才添加到返回值中
                    if includeImages {
                        timelineImages[imageName] = imageData
                        print("📝 Added image data for \(imageName)")
                    }
                    images.append(imageName)
                    event["image"] = imageName
                }
                
                // 无论是否有图片，都添加事件
                events.append(event)
            }
            
            timelineJson["duration"] = duration
            timelineJson["images"] = images
            timelineJson["events"] = events
            timelineData = try JSONSerialization.data(withJSONObject: timelineJson)
            
            // 打印生成的 JSON 数据
            if let jsonString = String(data: timelineData, encoding: .utf8) {
                print("📝 Generated timeline JSON: \(jsonString)")
            }
        }
        
        return (timelineData, timelineImages)
    }
} 