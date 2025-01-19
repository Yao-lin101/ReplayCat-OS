# 模板系统设计

## 概述

模板系统是 SMTX 应用的核心功能，用于创建和管理语言学习内容。每个模板包含一系列时间轴项目，支持文本和图片内容。本文档详细说明了模板系统的设计和实现。

## 数据模型

### Template

```swift
struct Template: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var coverImage: String?
    var tags: [String]
    var timelineItems: [TimelineItem]
    var languageSectionId: String
    var createdAt: Date
    var updatedAt: Date
}
```

### TimelineItem

```swift
struct TimelineItem: Identifiable, Codable {
    let id: String
    var timestamp: TimeInterval
    var content: String
    var imageUrl: String?
    var type: ItemType
    
    enum ItemType: String, Codable {
        case text
        case image
        case both
    }
}
```

## 核心组件

### 1. TemplateStore

管理模板的状态和操作：

```swift
class TemplateStore: ObservableObject {
    @Published var templates: [Template] = []
    @Published var currentTemplate: Template?
    
    func fetchTemplates(sectionId: String) -> AnyPublisher<[Template], Error>
    func createTemplate(_ template: Template) -> AnyPublisher<Template, Error>
    func updateTemplate(_ template: Template) -> AnyPublisher<Template, Error>
    func deleteTemplate(_ id: String) -> AnyPublisher<Void, Error>
}
```

### 2. TimelineManager

管理时间轴项目：

```swift
class TimelineManager {
    func addItem(_ item: TimelineItem, to template: Template)
    func removeItem(_ id: String, from template: Template)
    func updateItem(_ item: TimelineItem, in template: Template)
    func reorderItems(in template: Template, from: Int, to: Int)
}
```

### 3. TemplateStorage

处理模板的本地存储：

```swift
class TemplateStorage {
    func saveTemplate(_ template: Template)
    func loadTemplate(id: String) -> Template?
    func deleteTemplate(id: String)
    func loadAllTemplates() -> [Template]
}
```

## 功能实现

### 1. 模板管理

- 创建新模板
- 编辑模板信息
- 删除模板
- 模板复制

### 2. 时间轴编辑

- 添加时间点
- 编辑内容
- 调整时间
- 重新排序

### 3. 内容管理

- 文本编辑
- 图片上传
- 内容预览
- 版本控制

## 用户界面

### 1. 模板列表

```swift
struct TemplateListView: View {
    @StateObject private var store = TemplateStore()
    let sectionId: String
    
    var body: some View {
        List {
            ForEach(store.templates) { template in
                TemplateRow(template: template)
            }
        }
        .toolbar {
            Button("New Template") {
                // 显示创建模板表单
            }
        }
    }
}
```

### 2. 模板编辑器

```swift
struct TemplateEditorView: View {
    @StateObject private var viewModel: TemplateEditorViewModel
    @State private var showingTimelineEditor = false
    
    var body: some View {
        VStack {
            // 模板基本信息编辑
            TemplateInfoSection(template: $viewModel.template)
            
            // 时间轴编辑
            TimelineEditorView(items: $viewModel.template.timelineItems)
            
            // 工具栏
            TemplateEditorToolbar(viewModel: viewModel)
        }
    }
}
```

## 数据流

1. **创建模板流程**:
   - 用户输入基本信息
   - 创建时间轴项目
   - 保存本地数据
   - 同步到云端
   - 更新 UI

2. **编辑模板流程**:
   - 加载模板数据
   - 用户修改内容
   - 实时保存
   - 同步更新
   - 刷新界面

3. **预览模板流程**:
   - 加载模板数据
   - 渲染时间轴
   - 支持交互操作
   - 显示预览效果

## 性能优化

1. **数据处理**:
   - 增量更新
   - 懒加载
   - 缓存管理

2. **图片处理**:
   - 图片压缩
   - 缓存策略
   - 渐进式加载

3. **编辑优化**:
   - 自动保存
   - 撤销/重做
   - 并发控制

## 测试策略

1. **单元测试**:
   - 模板操作测试
   - 时间轴管理测试
   - 数据验证测试

2. **集成测试**:
   - 存储系统测试
   - 同步机制测试
   - 并发操作测试

3. **UI 测试**:
   - 编辑功能测试
   - 交互流程测试
   - 性能测试

## 常见问题

1. **大量数据处理**:
   - 分页加载
   - 内存优化
   - 性能监控

2. **并发编辑**:
   - 锁机制
   - 冲突解决
   - 版本控制

3. **离线支持**:
   - 本地存储
   - 同步策略
   - 状态管理

## 最佳实践

1. **模板设计**:
   - 保持简洁
   - 结构清晰
   - 易于维护

2. **时间轴管理**:
   - 合理分段
   - 时间点设置
   - 内容组织

3. **用户体验**:
   - 响应及时
   - 操作直观
   - 反馈明确
