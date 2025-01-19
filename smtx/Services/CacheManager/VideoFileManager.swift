import Foundation
import AVFoundation
import SwiftUI
import CryptoKit

enum VideoFileError: Error {
    case directoryCreationFailed
    case fileWriteFailed
    case fileNotFound
    case thumbnailGenerationFailed
    case invalidVideoURL
}

class VideoFileManager {
    static let shared = VideoFileManager()
    
    let videoDirectory: URL
    // 添加帧缓存
    private var frameGenerators: [String: AVAssetImageGenerator] = [:]
    private var frameCache: [String: [Double: UIImage]] = [:]
    
    private init() {
        // 在 Documents 目录下创建 Videos 文件夹
        videoDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Videos")
        
        try? FileManager.default.createDirectory(at: videoDirectory, 
                                               withIntermediateDirectories: true)
    }
    
    private func cleanVideoUrl(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return urlString
        }
        
        // 保留基本参数，移除动态参数
        let keepParams = ["bvid", "aid", "cid", "qn", "platform", "bw"]
        components.queryItems = components.queryItems?.filter { item in
            keepParams.contains(item.name)
        }
        
        // 如果是B站视频，提取基本路径和视频ID
        if components.host?.contains("bilivideo.com") == true,
           let path = components.path.split(separator: "/").last {
            return "\(path)" // 只使用视频ID部分作为缓存键
        }
        
        return components.string ?? urlString
    }
    
    /// 从网络URL下载并保存视频，带进度回调
    func downloadAndSaveVideo(from urlString: String, progress: ((Double) -> Void)? = nil) async throws -> String {
        // 检查是否已下载
        let fileName = getExpectedUrl(from: urlString)
        let fileURL = videoDirectory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("✅ 视频已存在，跳过下载")
            return fileName
        }
        
        // 开始下载
        print("⬇️ 开始下载视频: \(urlString)")
        let startTime = Date()
        
        guard let url = URL(string: urlString) else {
            throw VideoFileError.invalidVideoURL
        }
        
        // 创建下载任务
        let (bytes, response) = try await URLSession.shared.bytes(from: url)
        let expectedLength = Int(response.expectedContentLength)
        var downloadedData = Data()
        downloadedData.reserveCapacity(expectedLength)
        
        var downloadedBytes = 0
        for try await byte in bytes {
            downloadedData.append(byte)
            downloadedBytes += 1
            if expectedLength > 0 {
                let currentProgress = Double(downloadedBytes) / Double(expectedLength)
                progress?(currentProgress)
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // 保存视频
        do {
            try downloadedData.write(to: fileURL)
            print("✅ 视频下载完成")
            print("⏱️ 下载用时: \(String(format: "%.2f", duration))秒")
            print("📊 文件大小: \(ByteCountFormatter.string(fromByteCount: Int64(downloadedData.count), countStyle: .file))")
            progress?(1.0)
            return fileName
        } catch {
            print("❌ 视频保存失败: \(error.localizedDescription)")
            throw VideoFileError.fileWriteFailed
        }
    }
    
    /// 删除视频文件
    func deleteVideo(at path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw VideoFileError.fileNotFound
        }
        
        try FileManager.default.removeItem(atPath: path)
    }
    
    /// 检查视频文件是否存在
    func videoExists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    /// 获取预期URL
    func getExpectedUrl(from urlString: String) -> String {
        // 打印原始URL
        print("🔍 处理视频URL: \(urlString)")
        
        // 清理URL并生成视频ID
        let cleanedUrl = cleanVideoUrl(urlString)
        print("🧹 清理后的URL: \(cleanedUrl)")
        let videoId = SHA256.hash(data: cleanedUrl.data(using: .utf8)!).map { String(format: "%02x", $0) }.joined()
        print("🔑 生成的视频ID: \(videoId)")
        
        // 返回相对路径（文件名）
        let fileName = "\(videoId).mp4"
        print("📂 目标文件名: \(fileName)")
        return fileName
    }

    /// 获取视频的完整 URL
    func getVideoUrl(for relativePath: String) -> URL {
        // 如果传入的是完整路径,提取文件名
        let fileName = (relativePath as NSString).lastPathComponent
        return videoDirectory.appendingPathComponent(fileName)
    }
    
    /// 生成视频缩略图
    func generateThumbnail(from videoPath: String) throws -> Data {
        let url = URL(fileURLWithPath: videoPath)
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // 获取视频第一帧作为封面
        let time = CMTime(seconds: 0, preferredTimescale: 1)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            
            guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
                throw VideoFileError.thumbnailGenerationFailed
            }
            
            return imageData
        } catch {
            throw VideoFileError.thumbnailGenerationFailed
        }
    }
    
    /// 获取未使用的视频缓存大小（字节）
    func getUnusedCacheSize(usedFileNames: Set<String>) -> Int64 {
        let fileManager = FileManager.default
        
        // 获取视频目录下的所有文件
        guard let files = try? fileManager.contentsOfDirectory(
            at: videoDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        
        return files.reduce(0) { total, file in
            let fileName = file.lastPathComponent
            
            // 如果文件正在被使用，不计入缓存大小
            if usedFileNames.contains(fileName) {
                return total
            }
            
            guard let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                  let size = attributes[.size] as? Int64 else {
                return total
            }
            return total + size
        }
    }
    
    /// 清理未被任何模板使用的视频文件
    func cleanupUnusedVideos(usedFileNames: Set<String>) {
        let fileManager = FileManager.default
        
        // 获取视频目录下的所有文件
        guard let files = try? fileManager.contentsOfDirectory(
            at: videoDirectory,
            includingPropertiesForKeys: nil
        ) else { return }
        
        for file in files {
            let fileName = file.lastPathComponent
            
            // 如果文件不在使用中的列表中，则删除
            if !usedFileNames.contains(fileName) {
                do {
                    try fileManager.removeItem(at: file)
                    print("🗑️ 删除未使用的视频文件: \(fileName)")
                } catch {
                    print("❌ 删除视频文件失败: \(fileName)")
                }
            }
        }
    }
    
    /// 清理过期视频文件
    func cleanupExpiredVideos(olderThan days: Int = 7, usedPaths: Set<String>) {
        let fileManager = FileManager.default
        
        // 标准化所有使用中的路径
        let standardizedUsedPaths = Set(usedPaths.map { path -> String in
            return (path as NSString).standardizingPath
        })
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: videoDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else {
            print("⚠️ 无法访问视频目录")
            return
        }
        
        let expirationDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))
        
        for file in files {
            let standardizedPath = (file.path as NSString).standardizingPath
            
            // 如果文件正在被使用，跳过
            if standardizedUsedPaths.contains(standardizedPath) {
                continue
            }
            
            // 检查文件是否过期
            guard let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                  let creationDate = attributes[.creationDate] as? Date else {
                continue
            }
            
            if creationDate < expirationDate {
                do {
                    // 再次检查文件是否存在（以防并发访问）
                    if fileManager.fileExists(atPath: file.path) {
                        try fileManager.removeItem(at: file)
                        print("🗑️ 删除过期视频文件: \(file.lastPathComponent), 创建于: \(creationDate)")
                    }
                } catch {
                    print("❌ 删除视频文件失败: \(file.lastPathComponent), 错误: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 获取视频时长
    func getVideoDuration(at path: String) async throws -> Double {
        let url = URL(fileURLWithPath: path)
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }
    
    /// 获取视频文件大小
    func getVideoFileSize(at path: String) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
    
    /// 获取视频缓存总大小（字节）
    func getTotalCacheSize() -> Int64 {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: videoDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        
        return files.reduce(0) { total, file in
            guard let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                  let size = attributes[.size] as? Int64 else {
                return total
            }
            return total + size
        }
    }
    
    /// 获取视频帧
    func getVideoFrame(from path: String, at time: Double) -> UIImage? {
        // 先检查缓存
        if let cachedFrames = frameCache[path],
           let cachedFrame = cachedFrames[time] {
            return cachedFrame
        }
        
        // 获取或创建 generator
        let generator: AVAssetImageGenerator
        if let existingGenerator = frameGenerators[path] {
            generator = existingGenerator
        } else {
            let url = URL(fileURLWithPath: path)
            let asset = AVAsset(url: url)
            generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 480, height: 270) // 16:9
            frameGenerators[path] = generator
        }
        
        // 生成帧
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        do {
            let cgImage = try generator.copyCGImage(at: cmTime, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            
            // 缓存帧
            if frameCache[path] == nil {
                frameCache[path] = [:]
            }
            frameCache[path]?[time] = image
            
            return image
        } catch {
            print("Error generating video frame: \(error)")
            return nil
        }
    }
    
    /// 清理指定视频的帧缓存
    func clearFrameCache(for path: String) {
        frameCache.removeValue(forKey: path)
        frameGenerators.removeValue(forKey: path)
    }
    
    /// 清理所有帧缓存
    func clearAllFrameCaches() {
        frameCache.removeAll()
        frameGenerators.removeAll()
    }
    
    /// 清理过期的帧缓存
    func cleanupFrameCache() {
        // 可以根据需要设置清理策略
        // 比如保留最近使用的N个视频的缓存
        let maxCachedVideos = 5
        if frameCache.count > maxCachedVideos {
            let sortedPaths = frameCache.keys.sorted { path1, path2 in
                // 这里可以添加排序逻辑，比如按最后访问时间
                return false
            }
            
            // 删除多余的缓存
            for path in sortedPaths.dropFirst(maxCachedVideos) {
                clearFrameCache(for: path)
            }
        }
    }
} 
