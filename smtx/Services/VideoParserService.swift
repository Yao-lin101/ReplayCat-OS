import Foundation

// 错误类型
enum VideoParseError: LocalizedError {
    case invalidUrl
    case unsupportedPlatform
    case parseError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "无效的视频链接"
        case .unsupportedPlatform:
            return "暂不支持该平台"
        case .parseError(let message):
            return "解析失败：\(message)"
        case .networkError(let error):
            return "网络错误：\(error.localizedDescription)"
        }
    }
}

// 视频解析器协议
protocol VideoParser {
    func parseVideo(_ urlString: String) async throws -> VideoInfo
    func detectPlatform(_ urlString: String) -> Bool
}

// B站API响应模型
struct BiliVideoResponse: Codable {
    let code: Int
    let message: String
    let data: BiliVideoData
    
    struct BiliVideoData: Codable {
        let bvid: String
        let aid: Int
        let cid: Int
        let title: String
        let desc: String
        let pic: String
        let duration: Int
        let owner: Owner
        
        struct Owner: Codable {
            let mid: Int
            let name: String
        }
    }
}

struct BiliPlayUrlResponse: Codable {
    let code: Int
    let data: PlayUrlData
    
    struct PlayUrlData: Codable {
        let durl: [DUrl]
    }
    
    struct DUrl: Codable {
        let url: String
    }
}

// B站解析器
class BilibiliParser: VideoParser {
    func detectPlatform(_ urlString: String) -> Bool {
        return urlString.contains("bilibili.com") || 
               urlString.contains("b23.tv") || 
               urlString.contains("BV")
    }
    
    func parseVideo(_ urlString: String) async throws -> VideoInfo {
        let bvid = try await extractBvid(from: urlString)
        let videoInfo = try await fetchVideoInfo(bvid: bvid)
        let videoUrl = try await fetchVideoUrl(aid: videoInfo.data.aid, cid: videoInfo.data.cid)
        
        // 将 HTTP URL 转换为 HTTPS
        let coverUrl = videoInfo.data.pic.replacingOccurrences(of: "http://", with: "https://")
        
        return VideoInfo(
            title: videoInfo.data.title,
            description: videoInfo.data.desc,
            videoUrl: videoUrl,
            coverUrl: coverUrl,  // 使用转换后的 HTTPS URL
            duration: videoInfo.data.duration,
            platform: .bilibili,
            originalId: bvid,
            authorName: videoInfo.data.owner.name,
            authorId: String(videoInfo.data.owner.mid),
            platformExtra: nil
        )
    }
    
    private func extractBvid(from urlString: String) async throws -> String {
        // 1. 首先清理链接文本，提取实际URL
        let cleanUrl = urlString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "http")
            .last.map { "http" + $0 } ?? urlString
        
        // 2. 处理不同格式
        if cleanUrl.contains("BV") {
            // 直接BV号格式
            if let match = cleanUrl.range(of: "BV[A-Za-z0-9]+", options: .regularExpression) {
                return String(cleanUrl[match])
            }
        } else if cleanUrl.contains("b23.tv") {
            // 短链接格式
            guard let url = URL(string: cleanUrl) else {
                throw VideoParseError.invalidUrl
            }
            
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                if let redirectUrl = (response as? HTTPURLResponse)?.url?.absoluteString,
                   let match = redirectUrl.range(of: "BV[A-Za-z0-9]+", options: .regularExpression) {
                    return String(redirectUrl[match])
                }
            } catch {
                throw VideoParseError.parseError("短链接解析失败")
            }
        }
        
        throw VideoParseError.parseError("无效的B站视频链接")
    }
    
    private func fetchVideoInfo(bvid: String) async throws -> BiliVideoResponse {
        let url = URL(string: "https://api.bilibili.com/x/web-interface/view?bvid=\(bvid)")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(BiliVideoResponse.self, from: data)
            
            guard response.code == 0 else {
                throw VideoParseError.parseError(response.message)
            }
            
            return response
        } catch let error as VideoParseError {
            throw error
        } catch {
            throw VideoParseError.networkError(error)
        }
    }
    
    private func fetchVideoUrl(aid: Int, cid: Int) async throws -> String {
        let url = URL(string: "https://api.bilibili.com/x/player/playurl?avid=\(aid)&cid=\(cid)&qn=16&type=mp4&platform=html5")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(BiliPlayUrlResponse.self, from: data)
            
            guard let videoUrl = response.data.durl.first?.url else {
                throw VideoParseError.parseError("视频地址获取失败")
            }
            
            return videoUrl
        } catch let error as VideoParseError {
            throw error
        } catch {
            throw VideoParseError.networkError(error)
        }
    }
}

// 主服务类
class VideoParserService {
    static let shared = VideoParserService()
    
    private var parsers: [VideoParser] = []
    
    private init() {
        // 注册解析器
        registerParser(BilibiliParser())
        // 后续可以继续注册其他平台的解析器
    }
    
    func registerParser(_ parser: VideoParser) {
        parsers.append(parser)
    }
    
    /// 解析视频链接
    /// - Parameter urlString: 视频链接
    /// - Returns: 视频信息
    func parseVideo(_ urlString: String) async throws -> VideoInfo {
        // 查找合适的解析器
        guard let parser = parsers.first(where: { $0.detectPlatform(urlString) }) else {
            throw VideoParseError.unsupportedPlatform
        }
        
        do {
            return try await parser.parseVideo(urlString)
        } catch let error as VideoParseError {
            throw error
        } catch {
            throw VideoParseError.networkError(error)
        }
    }
    
    /// 获取链接对应的平台
    /// - Parameter urlString: 视频链接
    /// - Returns: 视频平台
    func detectPlatform(_ urlString: String) -> VideoPlatform? {
        guard let parser = parsers.first(where: { $0.detectPlatform(urlString) }) else {
            return nil
        }
        
        switch parser {
        case is BilibiliParser:
            return .bilibili
        // 暂时注释掉未实现的解析器
        // case is DouyinParser:
        //     return .douyin
        // case is KuaishouParser:
        //     return .kuaishou
        default:
            return nil
        }
    }
    
    /// 检查链接是否支持解析
    /// - Parameter urlString: 视频链接
    /// - Returns: 是否支持
    func isSupported(_ urlString: String) -> Bool {
        return parsers.contains(where: { $0.detectPlatform(urlString) })
    }
} 