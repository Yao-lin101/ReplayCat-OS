# SMTX - 语言学习模板应用

SMTX 是一个专为语言学习者设计的 iOS 应用，帮助用户创建、管理和练习语言学习模板。

## 系统要求

- iOS 16.0 或更高版本
- Xcode 15.0 或更高版本（用于开发）
- Swift 5.9 或更高版本

## 快速开始

1. 克隆项目
```bash
git clone https://github.com/your-org/smtx.git
cd smtx/ios/smtx
```

2. 安装依赖
```bash
pod install
```

3. 打开项目
```bash
open smtx.xcworkspace
```

## 核心功能

- 用户认证与个人资料管理
- 语言分区管理
- 模板创建与编辑
- 录音练习
- 云端同步

## 文档

详细的开发文档请查看 [docs](./docs) 目录：

- [项目概述](./docs/overview.md)
- [架构设计](./docs/architecture/)
  - [用户系统](./docs/architecture/auth.md)
  - [语言分区](./docs/architecture/language-section.md)
  - [模板系统](./docs/architecture/template.md)
  - [录音系统](./docs/architecture/recording.md)
  - [网络架构](./docs/architecture/network.md)
- [API 文档](./docs/api/)
  - [API 概览](./docs/api/overview.md)
  - [认证 API](./docs/api/auth.md)
  - [模板 API](./docs/api/template.md)
- [开发指南](./docs/guides/)
  - [项目结构](./docs/guides/project-structure.md)
  - [代码风格](./docs/guides/code-style.md)
  - [测试指南](./docs/guides/testing.md)
  - [发布流程](./docs/guides/release.md)

## 贡献

如果你想为项目做出贡献，请查看我们的[贡献指南](./docs/contributing.md)。

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](./LICENSE) 文件了解详情。