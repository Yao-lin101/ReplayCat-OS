# 用户系统架构

## 概述

SMTX 的用户系统采用 JWT (JSON Web Token) 认证机制，实现了安全可靠的用户认证和授权功能。本文档详细说明了用户系统的架构设计和实现细节。

## 核心组件

### 1. AuthService

主要负责处理所有与认证相关的网络请求：

```swift
class AuthService {
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, Error>
    func register(email: String, password: String) -> AnyPublisher<AuthResponse, Error>
    func refreshToken() -> AnyPublisher<AuthResponse, Error>
    func logout() -> AnyPublisher<Void, Error>
}
```

### 2. TokenManager

管理 JWT token 的存储、刷新和验证：

```swift
class TokenManager {
    func saveTokens(accessToken: String, refreshToken: String)
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func clearTokens()
    func isTokenValid() -> Bool
}
```

### 3. UserStore

管理用户状态和信息：

```swift
class UserStore: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool
    
    func updateProfile(_ profile: Profile) -> AnyPublisher<User, Error>
    func updateAvatar(_ image: UIImage) -> AnyPublisher<String, Error>
}
```

## 数据流

1. **登录流程**:
   - 用户输入邮箱和密码
   - AuthService 发送登录请求
   - 获取 JWT tokens
   - TokenManager 保存 tokens
   - UserStore 更新用户状态

2. **Token 刷新流程**:
   - 请求发送前检查 token 有效性
   - 如果 token 即将过期，使用 refresh token 获取新的 access token
   - TokenManager 更新存储的 tokens

3. **登出流程**:
   - 清除本地存储的 tokens
   - 重置 UserStore 状态
   - 清除相关缓存数据

## 安全考虑

1. **Token 存储**:
   - 使用 Keychain 安全存储 tokens
   - 避免在用户默认设置中存储敏感信息

2. **请求安全**:
   - 所有请求使用 HTTPS
   - 添加请求签名验证
   - 实现请求重试机制

3. **错误处理**:
   - 统一的错误处理机制
   - 友好的用户提示
   - 详细的日志记录

## 代码示例

### 网络请求拦截器

```swift
class AuthInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest) -> URLRequest {
        var request = urlRequest
        if let token = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    func retry(_ request: Request, dueTo error: Error) -> Bool {
        // 处理 401 错误，尝试刷新 token
        if case .responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) = error {
            return TokenManager.shared.refreshToken()
        }
        return false
    }
}
```

### 用户状态管理

```swift
extension UserStore {
    func handleAuthentication(_ response: AuthResponse) {
        TokenManager.shared.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        self.currentUser = response.user
        self.isAuthenticated = true
    }
    
    func handleLogout() {
        TokenManager.shared.clearTokens()
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
```

## 测试策略

1. **单元测试**:
   - AuthService 的网络请求测试
   - TokenManager 的 token 管理测试
   - UserStore 的状态管理测试

2. **集成测试**:
   - 完整的登录流程测试
   - Token 刷新机制测试
   - 错误处理测试

3. **UI 测试**:
   - 登录界面交互测试
   - 错误提示测试
   - 登录状态切换测试

## 常见问题

1. **Token 过期处理**:
   - 实现了自动刷新机制
   - 多个并发请求的处理
   - 刷新失败后的重试策略

2. **离线支持**:
   - 本地数据缓存
   - 离线状态检测
   - 数据同步策略

3. **性能优化**:
   - Token 验证缓存
   - 请求队列管理
   - 并发控制
