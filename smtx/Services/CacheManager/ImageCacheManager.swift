import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private var loadingTasks: [URL: Task<UIImage?, Error>] = [:]
    private let lock = NSLock()
    
    private init() {
        cache.countLimit = 100  // 最多缓存100张图片
        cache.totalCostLimit = 1024 * 1024 * 100  // 100 MB
    }
    
    private func withLock<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
    
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url.absoluteString as NSString)
    }
    
    func loadImage(from url: URL) async throws -> UIImage {
        // 1. 检查内存缓存
        if let cachedImage = image(for: url) {
            return cachedImage
        }
        
        // 2. 如果已经有相同URL的加载任务，等待其完成
        let existingTask = withLock { loadingTasks[url] }
        if let task = existingTask {
            return try await task.value ?? UIImage()
        }
        
        // 3. 创建新的加载任务
        let task = Task<UIImage?, Error> {
            let request = URLRequest(url: url)
            
            // 检查是否有磁盘缓存
            if let cachedResponse = URLCache.shared.cachedResponse(for: request),
               let image = UIImage(data: cachedResponse.data) {
                cache.setObject(image, forKey: url.absoluteString as NSString)
                return image
            }
            
            // 从网络加载
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                throw URLError(.badServerResponse)
            }
            
            // 保存到缓存
            cache.setObject(image, forKey: url.absoluteString as NSString)
            let cachedResponse = CachedURLResponse(
                response: response,
                data: data,
                storagePolicy: .allowed
            )
            URLCache.shared.storeCachedResponse(cachedResponse, for: request)
            
            return image
        }
        
        // 保存任务
        withLock {
            loadingTasks[url] = task
        }
        
        // 4. 等待任务完成并清理
        defer {
            Task {
                withLock {
                    loadingTasks[url] = nil
                }
            }
        }
        
        return try await task.value ?? UIImage()
    }
    
    func clearCache() {
        cache.removeAllObjects()
        URLCache.shared.removeAllCachedResponses()
    }
    
    /// 获取图片缓存大小（字节）
    func getCacheSize() -> Int64 {
        // 磁盘缓存大小
        let diskSize = Int64(URLCache.shared.currentDiskUsage)
        
        return diskSize
    }
} 