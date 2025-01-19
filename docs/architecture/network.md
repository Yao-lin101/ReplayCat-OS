# 网络架构

## 概述

SMTX 的网络架构采用现代化的设计模式，基于 URLSession 和 Combine 框架实现。本文档详细说明了网络层的设计和实现细节。

## 核心组件

### 1. NetworkService

基础网络请求服务：

```swift
class NetworkService {
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error>
    func upload(_ data: Data, to endpoint: Endpoint) -> AnyPublisher<UploadResponse, Error>
    func download(from url: URL) -> AnyPublisher<URL, Error>
}
```

### 2. Endpoint

请求端点定义：

```swift
struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?
    let headers: [String: String]?
    let body: Data?
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
}
```

### 3. APIClient

API 客户端实现：

```swift
class APIClient {
    private let networkService: NetworkService
    private let baseURL: URL
    
    // Auth
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, Error>
    func refreshToken() -> AnyPublisher<TokenResponse, Error>
    
    // Templates
    func fetchTemplates() -> AnyPublisher<[Template], Error>
    func createTemplate(_ template: Template) -> AnyPublisher<Template, Error>
    
    // Language Sections
    func fetchLanguageSections() -> AnyPublisher<[LanguageSection], Error>
    func createLanguageSection(_ section: LanguageSection) -> AnyPublisher<LanguageSection, Error>
}
```

## 网络层架构

### 1. 请求拦截器

```swift
protocol RequestInterceptor {
    func adapt(_ urlRequest: URLRequest) -> URLRequest
    func retry(_ request: Request, dueTo error: Error) -> Bool
}

class AuthInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest) -> URLRequest {
        // 添加认证头
        var request = urlRequest
        if let token = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", 
                           forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    func retry(_ request: Request, dueTo error: Error) -> Bool {
        // 处理认证错误
        if case .responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) = error {
            return TokenManager.shared.refreshToken()
        }
        return false
    }
}
```

### 2. 响应处理

```swift
class ResponseHandler {
    static func decode<T: Decodable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
    
    static func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}
```

## 错误处理

```swift
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noData
    case unauthorized
    case networkError(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let statusCode):
            return "HTTP 错误: \(statusCode)"
        case .decodingError(let error):
            return "解码错误: \(error.localizedDescription)"
        case .noData:
            return "没有数据"
        case .unauthorized:
            return "未授权"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}
```

## 缓存策略

### 1. 图片缓存

```swift
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    func cache(_ image: UIImage, for url: URL)
    func getImage(for url: URL) -> UIImage?
    func clearCache()
}
```

### 2. 响应缓存

```swift
class ResponseCache {
    static let shared = ResponseCache()
    private let cache = NSCache<NSString, CachedResponse>()
    
    func cacheResponse(_ data: Data, for request: URLRequest)
    func getCachedResponse(for request: URLRequest) -> Data?
    func clearCache()
}
```

## 性能优化

1. **请求优化**:
   - 请求合并
   - 请求队列
   - 请求优先级

2. **缓存优化**:
   - 多级缓存
   - 缓存策略
   - 缓存清理

3. **并发控制**:
   - 最大并发数
   - 请求超时
   - 重试机制

## 安全性

1. **数据安全**:
   - HTTPS
   - 证书验证
   - 数据加密

2. **认证安全**:
   - Token 管理
   - 刷新机制
   - 会话控制

## 测试策略

1. **单元测试**:
   - 请求构建测试
   - 响应处理测试
   - 错误处理测试

2. **集成测试**:
   - API 集成测试
   - 认证流程测试
   - 缓存机制测试

3. **性能测试**:
   - 并发测试
   - 网络条件测试
   - 内存泄漏测试

## 最佳实践

1. **代码组织**:
   - 清晰的层次结构
   - 职责分离
   - 可测试性

2. **错误处理**:
   - 统一的错误类型
   - 友好的错误提示
   - 完整的错误日志

3. **性能优化**:
   - 适当的缓存策略
   - 请求优化
   - 资源管理