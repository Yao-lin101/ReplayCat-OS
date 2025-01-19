# 模板 API

## 概述

模板 API 提供了创建、管理和操作学习模板的相关接口。

## API 列表

### 获取模板列表

```http
GET /api/v1/templates
```

#### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| language_section | string | 否 | 语言分区 ID |
| search | string | 否 | 搜索关键词 |
| page | integer | 否 | 页码，默认 1 |

#### 响应示例

```json
{
    "count": 100,
    "next": "https://api.smtx.com/v1/templates?page=2",
    "previous": null,
    "results": [
        {
            "id": "template_id",
            "title": "模板标题",
            "description": "模板描述",
            "cover_image": "https://example.com/cover.jpg",
            "language_section": "section_id",
            "author": {
                "id": "user_id",
                "username": "作者名"
            },
            "likes_count": 10,
            "is_liked": false,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
    ]
}
```

### 获取模板详情

```http
GET /api/v1/templates/{template_id}
```

#### 响应示例

```json
{
    "id": "template_id",
    "title": "模板标题",
    "description": "模板描述",
    "cover_image": "https://example.com/cover.jpg",
    "language_section": "section_id",
    "author": {
        "id": "user_id",
        "username": "作者名"
    },
    "timeline_items": [
        {
            "id": "item_id",
            "timestamp": 1.5,
            "content": "内容文本",
            "image_url": "https://example.com/image.jpg",
            "type": "text"
        }
    ],
    "likes_count": 10,
    "is_liked": false,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
}
```

### 创建模板

```http
POST /api/v1/templates
```

#### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 是 | 模板标题 |
| description | string | 否 | 模板描述 |
| language_section | string | 是 | 语言分区 ID |
| cover_image | file | 否 | 封面图片 |
| timeline_items | array | 是 | 时间轴项目列表 |

#### 时间轴项目格式

```json
{
    "timestamp": 1.5,
    "content": "内容文本",
    "image_url": "https://example.com/image.jpg",
    "type": "text"
}
```

### 更新模板

```http
PUT /api/v1/templates/{template_id}
```

#### 请求参数

与创建模板相同，但所有字段都是可选的。

### 删除模板

```http
DELETE /api/v1/templates/{template_id}
```

### 点赞/取消点赞

```http
POST /api/v1/templates/{template_id}/like
```

#### 响应示例

```json
{
    "status": "liked" // 或 "unliked"
}
```

## 代码示例

### Swift 示例

```swift
// 获取模板列表
func fetchTemplates(
    languageSection: String? = nil,
    search: String? = nil,
    page: Int = 1
) async throws -> [CloudTemplate] {
    return try await cloudTemplateService.fetchTemplates(
        languageSection: languageSection,
        search: search,
        page: page
    )
}

// 获取模板详情
func fetchTemplate(uid: String) async throws -> CloudTemplate {
    return try await cloudTemplateService.fetchTemplate(uid: uid)
}

// 点赞模板
func likeTemplate(uid: String) async throws -> Bool {
    return try await cloudTemplateService.likeTemplate(uid: uid)
}

// 创建模板
func createTemplate(_ template: Template) async throws -> CloudTemplate {
    return try await cloudTemplateService.createTemplate(template)
}

// 更新模板
func updateTemplate(_ template: Template) async throws -> CloudTemplate {
    return try await cloudTemplateService.updateTemplate(template)
}

// 删除模板
func deleteTemplate(uid: String) async throws {
    try await cloudTemplateService.deleteTemplate(uid: uid)
}
```

## 最佳实践

### 1. 模板创建

```swift
func createNewTemplate(
    title: String,
    description: String,
    languageSection: String,
    coverImage: UIImage?
) async throws -> CloudTemplate {
    // 1. 上传封面图片（如果有）
    var coverImageUrl: String?
    if let image = coverImage {
        coverImageUrl = try await uploadCoverImage(image)
    }
    
    // 2. 创建模板
    let template = Template(
        title: title,
        description: description,
        languageSection: languageSection,
        coverImage: coverImageUrl,
        timelineItems: []
    )
    
    // 3. 保存模板
    return try await cloudTemplateService.createTemplate(template)
}
```

### 2. 时间轴管理

```swift
class TimelineManager {
    // 添加时间轴项目
    func addItem(_ item: TimelineItem, to template: Template) {
        var updatedTemplate = template
        updatedTemplate.timelineItems.append(item)
        updatedTemplate.timelineItems.sort { $0.timestamp < $1.timestamp }
    }
    
    // 更新时间轴项目
    func updateItem(_ item: TimelineItem, in template: Template) {
        guard let index = template.timelineItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        var updatedTemplate = template
        updatedTemplate.timelineItems[index] = item
    }
}
```

### 3. 缓存管理

```swift
class TemplateCache {
    static let shared = TemplateCache()
    private let cache = NSCache<NSString, CloudTemplate>()
    
    func cacheTemplate(_ template: CloudTemplate) {
        cache.setObject(template, forKey: template.id as NSString)
    }
    
    func getTemplate(id: String) -> CloudTemplate? {
        return cache.object(forKey: id as NSString)
    }
}
```

## 性能优化

1. **图片处理**
   - 压缩上传的图片
   - 使用合适的图片缓存策略
   - 支持渐进式加载

2. **列表优化**
   - 实现分页加载
   - 缓存已加载的数据
   - 优化滚动性能

3. **并发处理**
   - 合理控制并发请求数
   - 实现请求取消机制
   - 处理竞态条件

## 错误处理

```swift
enum TemplateError: Error {
    case templateNotFound
    case invalidData
    case uploadFailed
    case operationFailed(String)
    case networkError(String)
    case serverError(String)
    
    var localizedDescription: String {
        switch self {
        case .templateNotFound:
            return "模板不存在"
        case .invalidData:
            return "数据格式错误"
        case .uploadFailed:
            return "上传失败"
        case .operationFailed(let message):
            return message
        case .networkError(let message):
            return "网络错误: \(message)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
}
```
