# API 概览

SMTX iOS 客户端的 API 接口采用 RESTful 风格设计，主要包含以下几个模块：

## API 基础信息

- 基础 URL: `https://api.smtx.com/v1`
- 认证方式: Bearer Token
- 响应格式: JSON
- 编码方式: UTF-8

## API 模块

### 1. 认证接口
- [用户注册](./auth.md#注册)
- [用户登录](./auth.md#登录)
- [验证码发送](./auth.md#验证码)
- [个人资料更新](./auth.md#个人资料)
- [头像上传](./auth.md#头像上传)

### 2. 语言分区接口
- [获取分区列表](./language-section.md#获取列表)
- [创建分区](./language-section.md#创建分区)
- [更新分区](./language-section.md#更新分区)
- [删除分区](./language-section.md#删除分区)
- [订阅分区](./language-section.md#订阅分区)

### 3. 模板接口
- [获取模板列表](./template.md#获取列表)
- [获取模板详情](./template.md#获取详情)
- [创建模板](./template.md#创建模板)
- [更新模板](./template.md#更新模板)
- [删除模板](./template.md#删除模板)
- [点赞/取消点赞](./template.md#点赞操作)
- [收藏/取消收藏](./template.md#收藏操作)

## 通用格式

### 请求头

```
Authorization: Bearer <access_token>
Content-Type: application/json
Accept: application/json
```

### 分页响应

```json
{
    "count": 100,
    "next": "https://api.smtx.com/v1/templates?page=2",
    "previous": null,
    "results": [
        // 数据项列表
    ]
}
```

### 错误响应

```json
{
    "error": {
        "code": "ERROR_CODE",
        "message": "错误描述信息"
    }
}
```

## 错误码说明

| 错误码 | 说明 |
|--------|------|
| 400 | 请求参数错误 |
| 401 | 未授权或 Token 失效 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

## 最佳实践

### 1. 错误处理
- 始终检查响应状态码
- 合理处理网络错误
- 实现请求重试机制

### 2. 性能优化
- 使用合适的缓存策略
- 实现请求取消机制
- 处理并发请求

### 3. 安全性
- 不在客户端存储敏感信息
- 使用 HTTPS 进行通信
- 实现 Token 自动刷新

## 开发工具

### 1. API 调试
- Postman
- Charles Proxy
- Xcode Network Inspector

### 2. 性能分析
- Instruments
- Network Link Conditioner

## 常见问题

### 1. Token 过期处理
当收到 401 错误时，需要：
1. 尝试刷新 Token
2. 如果刷新成功，重试原请求
3. 如果刷新失败，退出登录状态

### 2. 网络异常处理
- 实现优雅的降级策略
- 提供友好的错误提示
- 支持离线模式

### 3. 并发请求
- 合理控制并发数量
- 处理请求优先级
- 避免重复请求
