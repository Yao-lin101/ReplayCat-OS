# 代码风格指南

## 概述

本文档定义了 SMTX iOS 项目的代码风格规范，旨在保持代码的一致性和可维护性。

## Swift 代码风格

### 1. 命名规范

#### 类型命名
- 使用 PascalCase
- 类名应该清晰表达其功能
- 避免缩写（除非是广泛使用的缩写）

```swift
// 好的例子
class TemplateDetailViewController
class CloudTemplateService
class ImageCache

// 不好的例子
class TemplateVC
class CloudTmpSvc
class ImgCache
```

#### 变量和函数命名
- 使用 camelCase
- 动词开头的函数名
- 布尔变量使用 is/has/should 等前缀

```swift
// 好的例子
var isLoading: Bool
var hasUnreadMessages: Bool
func fetchTemplate()
func updateProfile()

// 不好的例子
var Loading: Bool
var unreadMessages: Bool
func template()
func profile()
```

### 2. 代码组织

#### 文件结构
```swift
// 1. 导入语句
import SwiftUI
import Combine

// 2. 类型声明
class TemplateViewController: UIViewController {
    // 3. 属性声明
    private let viewModel: TemplateViewModel
    
    // 4. 初始化方法
    init(viewModel: TemplateViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    // 5. 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    // 6. 自定义方法
    private func setupUI() {
        // UI 设置代码
    }
    
    // 7. 代理方法
    extension TemplateViewController: UITableViewDelegate {
        // 代理方法实现
    }
}
```

#### MARK 注释
使用 MARK 注释组织代码：

```swift
class TemplateViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: - Lifecycle
    
    // MARK: - UI Setup
    
    // MARK: - Actions
    
    // MARK: - Helpers
}
```

### 3. 空白和格式

#### 缩进
- 使用 4 个空格进行缩进
- 不使用制表符

#### 行长度
- 每行最多 120 个字符
- 超过限制时进行换行

```swift
// 好的例子
let longString = """
    这是一个很长的字符串，
    需要换行显示
    """

// 不好的例子
let longString = "这是一个很长的字符串，应该换行显示，但是没有换行，导致代码很难阅读"
```

### 4. SwiftUI 代码风格

#### 视图结构
```swift
struct ContentView: View {
    // 1. 状态属性
    @State private var isLoading = false
    @StateObject private var viewModel = ViewModel()
    
    // 2. 计算属性
    var buttonTitle: String {
        isLoading ? "加载中..." : "确定"
    }
    
    // 3. 视图体
    var body: some View {
        VStack {
            // 主要内容
        }
    }
    
    // 4. 子视图
    private var headerView: some View {
        Text("Header")
    }
}
```

#### 修饰符顺序
```swift
Text("Hello")
    .font(.title)         // 1. 字体
    .foregroundColor(.primary)  // 2. 颜色
    .padding()           // 3. 间距
    .background(Color.blue)  // 4. 背景
    .cornerRadius(8)     // 5. 圆角
    .shadow(radius: 4)   // 6. 阴影
```

### 5. 注释规范

#### 文档注释
使用 Swift 文档注释格式：

```swift
/// 更新用户个人资料
/// - Parameters:
///   - username: 新的用户名
///   - bio: 个人简介
/// - Returns: 更新后的用户对象
/// - Throws: AuthError 如果更新失败
func updateProfile(
    username: String,
    bio: String
) async throws -> User
```

#### 实现注释
解释复杂的实现逻辑：

```swift
// 使用二分查找找到合适的插入位置
// 确保时间轴项目按时间戳排序
func findInsertPosition(for timestamp: TimeInterval) -> Int {
    // 实现代码
}
```

### 6. 错误处理

#### 错误定义
```swift
enum AuthError: Error {
    case invalidEmail
    case invalidPassword
    case networkError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidEmail:
            return "邮箱格式错误"
        case .invalidPassword:
            return "密码格式错误"
        case .networkError(let message):
            return "网络错误: \(message)"
        }
    }
}
```

#### 错误处理
```swift
do {
    try await authService.login(email: email, password: password)
} catch AuthError.invalidEmail {
    showError("邮箱格式错误")
} catch AuthError.invalidPassword {
    showError("密码格式错误")
} catch {
    showError("未知错误: \(error.localizedDescription)")
}
```

### 7. 并发编程

#### async/await
```swift
// 好的例子
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// 不好的例子
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        // 处理回调
    }.resume()
}
```

#### Actor 使用
```swift
actor TemplateStore {
    private var templates: [String: Template] = [:]
    
    func store(_ template: Template) {
        templates[template.id] = template
    }
    
    func template(for id: String) -> Template? {
        return templates[id]
    }
}
```

## 最佳实践

### 1. 依赖注入
```swift
// 好的例子
class TemplateViewController {
    private let service: TemplateService
    
    init(service: TemplateService) {
        self.service = service
    }
}

// 不好的例子
class TemplateViewController {
    private let service = TemplateService.shared
}
```

### 2. 单一职责
```swift
// 好的例子
class ImageLoader {
    func loadImage(from url: URL) async throws -> UIImage
}

class ImageCache {
    func cacheImage(_ image: UIImage, for url: URL)
}

// 不好的例子
class ImageManager {
    func loadAndCacheImage(from url: URL)
    func processImage(_ image: UIImage)
    func uploadImage(_ image: UIImage)
}
```

### 3. 协议导向编程
```swift
protocol TemplateService {
    func fetchTemplate(id: String) async throws -> Template
}

class CloudTemplateService: TemplateService {
    func fetchTemplate(id: String) async throws -> Template {
        // 实现代码
    }
}

class MockTemplateService: TemplateService {
    func fetchTemplate(id: String) async throws -> Template {
        // 测试实现
    }
}
```

## 代码审查清单

### 1. 基础检查
- [ ] 代码是否遵循命名规范
- [ ] 是否有适当的注释
- [ ] 是否处理了所有错误情况

### 2. 架构检查
- [ ] 是否遵循 SOLID 原则
- [ ] 是否有适当的抽象层
- [ ] 是否避免了循环依赖

### 3. 性能检查
- [ ] 是否有内存泄漏
- [ ] 是否有不必要的计算
- [ ] 是否正确使用缓存

### 4. 测试检查
- [ ] 是否有单元测试
- [ ] 是否测试了边界情况
- [ ] 是否有 UI 测试
