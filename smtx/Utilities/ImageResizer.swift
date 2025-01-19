import UIKit

enum ImageResizeError: Error {
    case invalidImage
    case resizeFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "无效的图片数据"
        case .resizeFailed:
            return "图片缩放失败"
        }
    }
}

class ImageResizer {
    /// 时间轴图片最大尺寸
    static let maxTimelineSize = CGSize(width: 1000, height: 563)
    
    /// 封面图片最大尺寸
    static let maxCoverSize = CGSize(width: 800, height: 600)
    
    /// 缩放时间轴图片
    /// - Parameter imageData: 原始图片数据
    /// - Returns: 缩放后的图片数据
    static func resizeTimelineImage(_ imageData: Data) throws -> Data {
        return try resizeImage(imageData, to: maxTimelineSize)
    }
    
    /// 缩放封面图片
    /// - Parameter imageData: 原始图片数据
    /// - Returns: 缩放后的图片数据
    static func resizeCoverImage(_ imageData: Data) throws -> Data {
        return try resizeImage(imageData, to: maxCoverSize)
    }
    
    /// 缩放图片到指定最大尺寸
    /// - Parameters:
    ///   - imageData: 原始图片数据
    ///   - maxSize: 最大尺寸
    /// - Returns: 缩放后的图片数据
    private static func resizeImage(_ imageData: Data, to maxSize: CGSize) throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw ImageResizeError.invalidImage
        }
        
        // 计算缩放比例
        let widthRatio = maxSize.width / image.size.width
        let heightRatio = maxSize.height / image.size.height
        
        // 如果图片尺寸已经小于最大尺寸，直接返回原图数据
        if widthRatio >= 1 && heightRatio >= 1 {
            return imageData
        }
        
        // 使用较小的缩放比例，保持宽高比
        let scale = min(widthRatio, heightRatio)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        // 创建绘图上下文
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制缩放后的图片
        image.draw(in: CGRect(origin: .zero, size: newSize))
        
        // 获取结果图片
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext(),
              let resizedData = resizedImage.jpegData(compressionQuality: 0.9) else {
            throw ImageResizeError.resizeFailed
        }
        
        return resizedData
    }
} 