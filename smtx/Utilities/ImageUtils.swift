import Foundation
import UIKit

enum ImageError: Error {
    case invalidImageData
    case thumbnailGenerationFailed
}

class ImageUtils {
    /// 生成缩略图
    /// - Parameters:
    ///   - imageData: 原始图片数据
    ///   - maxSize: 缩略图的最大边长
    ///   - compressionQuality: JPEG压缩质量 (0.0 - 1.0)
    /// - Returns: 缩略图数据
    static func generateThumbnail(
        from imageData: Data,
        maxSize: CGFloat = 300,
        compressionQuality: CGFloat = 0.8
    ) throws -> Data {
        guard let uiImage = UIImage(data: imageData) else {
            throw ImageError.invalidImageData
        }
        
        // 计算缩放比例，确保最大边不超过指定尺寸
        let scale = min(maxSize / uiImage.size.width, maxSize / uiImage.size.height, 1.0)
        let newSize = CGSize(
            width: min(round(uiImage.size.width * scale), maxSize),
            height: min(round(uiImage.size.height * scale), maxSize)
        )
        
        print("DEBUG - Original size: \(uiImage.size), New size: \(newSize), Scale: \(scale)")
        
        // 创建缩略图
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // 使用 1.0 scale 避免 Retina 分辨率
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let thumbnailImage = renderer.image { context in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // 转换为 JPEG 数据
        guard let thumbnailData = thumbnailImage.jpegData(compressionQuality: compressionQuality) else {
            throw ImageError.thumbnailGenerationFailed
        }
        
        print("DEBUG - Thumbnail size: \(thumbnailImage.size), Data size: \(thumbnailData.count) bytes")
        return thumbnailData
    }
} 