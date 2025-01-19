# 测试指南

## 概述

本文档提供了 SMTX iOS 项目的测试策略和最佳实践。我们采用多层次的测试方法，包括单元测试、集成测试和 UI 测试。

## 测试架构

### 1. 测试类型

#### 单元测试
- 业务逻辑测试
- 数据模型测试
- 工具类测试

#### 集成测试
- API 集成测试
- 数据持久化测试
- 模块间交互测试

#### UI 测试
- 用户界面测试
- 用户流程测试
- 性能测试

## 单元测试

### 1. 测试结构

```swift
class TemplateServiceTests: XCTestCase {
    // MARK: - Properties
    
    private var sut: TemplateService!
    private var mockNetworkService: MockNetworkService!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = TemplateService(networkService: mockNetworkService)
    }
    
    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_fetchTemplate_success() async throws {
        // Given
        let expectedTemplate = Template.mock()
        mockNetworkService.mockResponse(expectedTemplate)
        
        // When
        let template = try await sut.fetchTemplate(id: "test_id")
        
        // Then
        XCTAssertEqual(template.id, expectedTemplate.id)
    }
}
```

### 2. Mock 对象

```swift
class MockNetworkService: NetworkService {
    private var mockResponse: Any?
    private var mockError: Error?
    
    func mockResponse<T>(_ response: T) {
        mockResponse = response
    }
    
    func mockError(_ error: Error) {
        mockError = error
    }
    
    override func request<T>(_ endpoint: Endpoint) async throws -> T {
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse as? T else {
            throw NetworkError.invalidResponse
        }
        
        return response
    }
}
```

### 3. 测试数据

```swift
extension Template {
    static func mock(
        id: String = "test_id",
        title: String = "Test Template",
        description: String = "Test Description"
    ) -> Template {
        return Template(
            id: id,
            title: title,
            description: description,
            timelineItems: []
        )
    }
}
```

## 集成测试

### 1. API 测试

```swift
class APIIntegrationTests: XCTestCase {
    private var authService: AuthService!
    private var templateService: TemplateService!
    
    override func setUp() {
        super.setUp()
        authService = AuthService.shared
        templateService = TemplateService.shared
    }
    
    func test_completeUserFlow() async throws {
        // 1. 登录
        let user = try await authService.login(
            email: "test@example.com",
            password: "password"
        )
        XCTAssertNotNil(user)
        
        // 2. 创建模板
        let template = try await templateService.createTemplate(
            Template.mock()
        )
        XCTAssertNotNil(template)
        
        // 3. 获取模板
        let fetchedTemplate = try await templateService.fetchTemplate(
            id: template.id
        )
        XCTAssertEqual(template.id, fetchedTemplate.id)
    }
}
```

### 2. 数据持久化测试

```swift
class CoreDataTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        container = NSPersistentContainer(name: "TestModel")
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        context = container.viewContext
    }
    
    func test_saveAndFetchTemplate() throws {
        // 1. 创建模板
        let template = TemplateEntity(context: context)
        template.id = "test_id"
        template.title = "Test Template"
        
        // 2. 保存
        try context.save()
        
        // 3. 获取
        let request = TemplateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", "test_id")
        let results = try context.fetch(request)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Test Template")
    }
}
```

## UI 测试

### 1. 基本 UI 测试

```swift
class TemplateListUITests: XCTestCase {
    private var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func test_createTemplate() {
        // 1. 导航到创建模板页面
        app.buttons["创建模板"].tap()
        
        // 2. 填写表单
        let titleField = app.textFields["标题"]
        titleField.tap()
        titleField.typeText("测试模板")
        
        // 3. 提交
        app.buttons["保存"].tap()
        
        // 4. 验证结果
        XCTAssertTrue(app.staticTexts["测试模板"].exists)
    }
}
```

### 2. 用户流程测试

```swift
class UserFlowUITests: XCTestCase {
    private var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        app.launch()
    }
    
    func test_loginAndCreateTemplate() {
        // 1. 登录
        login()
        
        // 2. 创建模板
        createTemplate()
        
        // 3. 验证模板列表
        XCTAssertTrue(app.tables.cells.count > 0)
    }
    
    private func login() {
        app.textFields["邮箱"].tap()
        app.textFields["邮箱"].typeText("test@example.com")
        
        app.secureTextFields["密码"].tap()
        app.secureTextFields["密码"].typeText("password")
        
        app.buttons["登录"].tap()
    }
    
    private func createTemplate() {
        app.buttons["创建模板"].tap()
        // 填写模板信息
        app.buttons["保存"].tap()
    }
}
```

## 性能测试

### 1. 时间测试

```swift
func test_templateListPerformance() {
    measure {
        // 执行需要测试性能的代码
        let viewModel = TemplateListViewModel()
        viewModel.loadTemplates()
    }
}
```

### 2. 内存测试

```swift
func test_memoryUsage() {
    addTeardownBlock {
        // 检查内存泄漏
    }
    
    autoreleasepool {
        // 执行可能导致内存问题的代码
    }
}
```

## 测试覆盖率

### 1. 设置目标

- 业务逻辑：90% 以上
- 数据模型：95% 以上
- UI 代码：70% 以上

### 2. 覆盖率报告

```bash
xcodebuild test \
  -scheme SMTX \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -enableCodeCoverage YES
```

## 持续集成

### 1. GitHub Actions 配置

```yaml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode.app
      
    - name: Build and Test
      run: |
        xcodebuild test \
          -scheme SMTX \
          -destination 'platform=iOS Simulator,name=iPhone 14' \
          -enableCodeCoverage YES
```

## 最佳实践

### 1. 测试命名

```swift
// 格式：test_[方法名]_[情况]_[预期结果]
func test_login_withValidCredentials_shouldSucceed()
func test_login_withInvalidPassword_shouldFail()
```

### 2. 测试隔离

```swift
class IsolatedTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // 清理测试环境
        clearDatabase()
        resetUserDefaults()
    }
    
    override func tearDown() {
        // 清理测试数据
        clearTestData()
        super.tearDown()
    }
}
```

### 3. 异步测试

```swift
func test_asyncOperation() async throws {
    // Given
    let expectation = XCTestExpectation(description: "Async operation")
    
    // When
    Task {
        do {
            let result = try await sut.performOperation()
            // Then
            XCTAssertNotNil(result)
            expectation.fulfill()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
}
```

## 常见问题

### 1. 测试失败处理

```swift
func test_handleFailure() {
    // 1. 记录失败原因
    // 2. 截图或记录日志
    // 3. 清理环境
}
```

### 2. 测试数据管理

```swift
class TestDataManager {
    static func setupTestData()
    static func clearTestData()
    static func mockNetworkResponses()
}
```

### 3. UI 测试稳定性

```swift
extension XCUIElement {
    func waitForExistence(timeout: TimeInterval = 5.0) -> Bool {
        return waitForExistence(timeout: timeout)
    }
    
    func safelyTap() {
        if waitForExistence() {
            tap()
        }
    }
}
```
