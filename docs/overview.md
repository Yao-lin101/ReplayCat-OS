# 项目概述

SMTX 是一个专为语言学习者设计的 iOS 应用，帮助用户创建、管理和练习语言学习模板。本文档将帮助你快速了解项目结构并开始开发。


## 技术栈

- **UI 框架**: SwiftUI
- **状态管理**: Combine
- **数据持久化**: CoreData
- **音频处理**: AVFoundation
- **图片缓存**: NSCache + FileManager

## 系统要求

- iOS 16.0 或更高版本
- Xcode 15.0 或更高版本（用于开发）
- Swift 5.9 或更高版本

## 核心功能模块

### 1. 语言分区管理
- 创建和管理语言分区
- 分区权限控制
- 详见: [语言分区设计](./architecture/language-section.md)

### 2. 模板系统
- 创建和编辑模板
- 时间轴管理
- 详见: [模板系统设计](./architecture/template.md)

### 3. 录音功能
- 录音和播放
- 波形显示
- 详见: [录音系统设计](./architecture/recording.md)

## 开发指南

- [代码风格指南](./guides/code-style.md)
- [测试指南](./guides/testing.md)
- [发布流程](./guides/release.md)

## 相关资源

- [SwiftUI 官方文档](https://developer.apple.com/documentation/swiftui)
- [CoreData 官方文档](https://developer.apple.com/documentation/coredata)
- [Combine 官方文档](https://developer.apple.com/documentation/combine)
