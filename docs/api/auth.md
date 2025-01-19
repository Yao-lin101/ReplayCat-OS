# 认证 API

## 概述

认证 API 模块提供了用户认证、注册和个人资料管理的相关接口。

## API 列表

### 发送验证码

```http
POST /api/v1/auth/verify-code
```

#### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |

#### 响应示例

```json
{
    "message": "验证码已发送"
}
```

#### 错误码

| 错误码 | 说明 |
|--------|------|
| EMAIL_EXISTS | 邮箱已被注册 |
| INVALID_EMAIL | 邮箱格式错误 |

### 注册

```http
POST /api/v1/auth/register
```

#### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| password | string | 是 | 密码 |
| verify_code | string | 是 | 验证码 |

#### 响应示例

```json
{
    "user": {
        "id": "user_id",
        "email": "user@example.com",
        "username": "username",
        "avatar_url": "https://example.com/avatar.jpg"
    },
    "access_token": "access_token",
    "refresh_token": "refresh_token"
}
```

#### 错误码

| 错误码 | 说明 |
|--------|------|
| INVALID_CODE | 验证码错误 |
| INVALID_EMAIL | 邮箱格式错误 |
| INVALID_PASSWORD | 密码格式错误 |

### 登录

```http
POST /api/v1/auth/login
```

#### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| password | string | 是 | 密码 |

#### 响应示例

```json
{
    "user": {
        "id": "user_id",
        "email": "user@example.com",
        "username": "username",
        "avatar_url": "https://example.com/avatar.jpg"
    },
    "access_token": "access_token",
    "refresh_token": "refresh_token"
}
```

#### 错误码

| 错误码 | 说明 |
|--------|------|
| LOGIN_FAILED | 账号或密码错误 |
| INVALID_EMAIL | 邮箱格式错误 |
| INVALID_PASSWORD | 密码格式错误 |

### 上传头像

```http
POST /api/v1/users/me/avatar
```

#### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| avatar | file | 是 | 头像图片文件 |

#### 响应示例

```json
{
    "id": "user_id",
    "email": "user@example.com",
    "username": "username",
    "avatar_url": "https://example.com/new-avatar.jpg"
}
```

#### 错误码

| 错误码 | 说明 |
|--------|------|
| INVALID_IMAGE | 图片格式错误 |
| FILE_TOO_LARGE | 文件大小超限 |

### 更新个人资料

```http
PUT /api/v1/users/me
```

#### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | 否 | 用户名 |
| bio | string | 否 | 个人简介 |

#### 响应示例

```json
{
    "id": "user_id",
    "email": "user@example.com",
    "username": "new_username",
    "bio": "new bio",
    "avatar_url": "https://example.com/avatar.jpg"
}
```

#### 错误码

| 错误码 | 说明 |
|--------|------|
| USERNAME_EXISTS | 用户名已被使用 |
| INVALID_USERNAME | 用户名格式错误 |

## 代码示例

### Swift 示例

```swift
// 发送验证码
func sendVerificationCode(email: String) async throws {
    try await authService.sendVerificationCode(email: email)
}

// 注册
func register(email: String, password: String, code: String) async throws -> User {
    let response = try await authService.register(
        email: email,
        password: password,
        code: code
    )
    return response.user
}

// 登录
func login(email: String, password: String) async throws -> User {
    let response = try await authService.login(
        email: email,
        password: password
    )
    return response.user
}

// 上传头像
func uploadAvatar(_ image: UIImage) async throws -> User {
    return try await authService.uploadAvatar(image)
}

// 更新个人资料
func updateProfile(username: String, bio: String) async throws -> User {
    return try await authService.updateProfile([
        "username": username,
        "bio": bio
    ])
}
```

## 最佳实践

### 1. 错误处理

```swift
do {
    let user = try await authService.login(email: email, password: password)
    // 处理成功登录
} catch AuthError.loginFailed {
    // 显示账号或密码错误提示
} catch AuthError.invalidEmail {
    // 显示邮箱格式错误提示
} catch AuthError.invalidPassword {
    // 显示密码格式错误提示
} catch {
    // 处理其他错误
}
```

### 2. Token 管理

```swift
class TokenManager {
    static let shared = TokenManager()
    
    func saveTokens(access: String, refresh: String) {
        // 安全存储 tokens
    }
    
    func clearTokens() {
        // 清除存储的 tokens
    }
    
    func getAccessToken() -> String? {
        // 获取 access token
    }
}
```

### 3. 请求重试

```swift
func retryRequest<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch AuthError.unauthorized {
        // 尝试刷新 token
        if try await refreshToken() {
            return try await operation()
        }
        throw AuthError.unauthorized
    }
}
```

## 安全建议

1. **密码处理**
   - 不在客户端存储密码
   - 使用 HTTPS 传输
   - 实现密码强度验证

2. **Token 安全**
   - 使用 Keychain 存储 tokens
   - 定期刷新 access token
   - 合理设置 token 有效期

3. **敏感信息**
   - 避免日志记录敏感信息
   - 实现自动登出机制
   - 清理缓存数据
