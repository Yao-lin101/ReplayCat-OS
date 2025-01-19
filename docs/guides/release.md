# 发布流程指南

## 概述

本文档详细说明了 SMTX iOS 应用的发布流程，包括版本管理、测试流程和 App Store 发布步骤。

## 版本管理

### 1. 版本号规范

我们使用语义化版本号（Semantic Versioning）：

- 主版本号（Major）：不兼容的 API 修改
- 次版本号（Minor）：向下兼容的功能性新增
- 修订号（Patch）：向下兼容的问题修正

示例：1.2.3
- 1：主版本号
- 2：次版本号
- 3：修订号

### 2. 分支管理

```
main
  ├── develop
  │   ├── feature/user-profile
  │   └── feature/template-editor
  ├── release/1.2.0
  └── hotfix/1.1.1
```

- `main`: 生产环境代码
- `develop`: 开发分支
- `feature/*`: 功能分支
- `release/*`: 发布分支
- `hotfix/*`: 紧急修复分支

## 发布准备

### 1. 代码冻结

1. 创建发布分支
```bash
git checkout develop
git checkout -b release/1.2.0
```

2. 更新版本号
```swift
// Info.plist
<key>CFBundleShortVersionString</key>
<string>1.2.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 2. 测试清单

- [ ] 单元测试全部通过
- [ ] UI 测试全部通过
- [ ] 性能测试达标
- [ ] Beta 测试反馈处理完成
- [ ] 所有已知 bug 修复完成

## 构建和签名

### 1. 证书管理

1. 检查证书有效性
```bash
security find-identity -v -p codesigning
```

2. 更新描述文件
- 打开 Xcode -> Preferences -> Accounts
- 刷新描述文件
- 确保正确的描述文件被选中

### 2. 构建配置

```xcconfig
// Release.xcconfig
PRODUCT_BUNDLE_IDENTIFIER = com.smtx.ios
DEVELOPMENT_TEAM = XXXXXXXXXX
CODE_SIGN_IDENTITY = iPhone Distribution
PROVISIONING_PROFILE_SPECIFIER = SMTX_App_Store
```

### 3. 构建命令

```bash
# 清理构建目录
xcodebuild clean -workspace SMTX.xcworkspace -scheme SMTX

# 构建归档文件
xcodebuild archive \
    -workspace SMTX.xcworkspace \
    -scheme SMTX \
    -configuration Release \
    -archivePath build/SMTX.xcarchive

# 导出 IPA
xcodebuild -exportArchive \
    -archivePath build/SMTX.xcarchive \
    -exportOptionsPlist ExportOptions.plist \
    -exportPath build/SMTX
```

## App Store 发布

### 1. 准备材料

#### 截图要求
- iPhone 6.5" Display (iPhone 11 Pro Max)
- iPhone 5.5" Display (iPhone 8 Plus)
- iPad Pro (12.9-inch)
- iPad Pro (11-inch)

#### App Store 信息
- App 名称
- 关键词
- 描述
- 支持网站
- 隐私政策 URL

### 2. TestFlight

1. 内部测试
- 添加内部测试人员
- 收集反馈
- 修复问题

2. 外部测试
- 创建外部测试组
- 邀请测试人员
- 处理反馈

### 3. App Store 提交

1. 在 App Store Connect 创建新版本
2. 上传构建版本
3. 填写版本信息
4. 提交审核

## 发布后监控

### 1. 崩溃监控

```swift
class CrashReporter {
    static func setup() {
        // 初始化崩溃报告工具
    }
    
    static func recordError(_ error: Error) {
        // 记录错误信息
    }
}
```

### 2. 性能监控

```swift
class PerformanceMonitor {
    static func trackMemory() {
        // 监控内存使用
    }
    
    static func trackNetworkLatency() {
        // 监控网络延迟
    }
}
```

### 3. 用户反馈

```swift
class FeedbackManager {
    static func collectFeedback() {
        // 收集用户反馈
    }
    
    static func reportIssue(_ issue: Issue) {
        // 报告问题
    }
}
```

## 紧急修复流程

### 1. 创建热修复

```bash
# 从主分支创建热修复分支
git checkout main
git checkout -b hotfix/1.1.1

# 修复问题
git commit -m "fix: 修复登录崩溃问题"

# 合并回主分支和开发分支
git checkout main
git merge --no-ff hotfix/1.1.1
git tag -a v1.1.1 -m "版本 1.1.1"

git checkout develop
git merge --no-ff hotfix/1.1.1

# 删除热修复分支
git branch -d hotfix/1.1.1
```

### 2. 加急审核

1. 联系 App Store 审核团队
2. 说明紧急修复原因
3. 请求加急审核

## 版本回滚

### 1. 代码回滚

```bash
# 查看版本历史
git log --oneline

# 回滚到指定版本
git revert <commit-hash>

# 创建回滚分支
git checkout -b rollback/1.1.0
```

### 2. App Store 回滚

1. 在 App Store Connect 中移除有问题的版本
2. 恢复之前的稳定版本
3. 提交加急审核

## 发布检查清单

### 1. 代码准备
- [ ] 所有功能开发完成
- [ ] 代码审查通过
- [ ] 文档更新完成
- [ ] 第三方库更新检查
- [ ] 代码静态分析通过
- [ ] Git Tag 创建完成

### 2. 测试验证
- [ ] 单元测试通过
- [ ] UI 测试通过
- [ ] 集成测试通过
- [ ] Beta 测试完成
- [ ] 性能测试达标
- [ ] 安全测试通过

### 3. 构建打包
- [ ] 证书和描述文件有效
- [ ] 版本号正确
- [ ] 构建设置正确
- [ ] 签名验证通过
- [ ] 包大小优化完成

### 4. 提交材料
- [ ] App Store 截图准备
- [ ] 更新日志编写
- [ ] 应用描述更新
- [ ] 隐私政策更新
- [ ] 营销材料准备

### 5. 发布后计划
- [ ] 监控系统就绪
- [ ] 客服团队准备
- [ ] 回滚方案准备
- [ ] 用户通知准备
- [ ] 社交媒体更新准备

## 常见问题

### 1. 证书问题
- 证书过期
- 描述文件不匹配
- 签名失败

解决方案：
1. 检查证书有效期
2. 更新描述文件
3. 清理 Xcode 缓存

### 2. 构建问题
- 编译错误
- 链接错误
- 资源缺失

解决方案：
1. 清理构建目录
2. 更新依赖库
3. 检查资源文件

### 3. 审核问题
- 元数据不完整
- 功能不符合规范
- 性能问题

解决方案：
1. 仔细阅读拒绝原因
2. 更新相关内容
3. 改进问题功能
