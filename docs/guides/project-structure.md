# 项目结构

本文档提供了 SMTX iOS 项目的结构和组织概述。

## 目录结构

```
smtx/
├── docs/                           # 项目文档
│   ├── api/                       	# API相关文档
│   ├── architecture/            	# 架构设计文档
│   ├── guides/                   	# 开发指南
│   ├── overview.md              	# 项目概述
│   └── README.md                	# 文档说明
│
├── smtx/                          	# 主应用程序源代码
│   ├── Assets.xcassets/         	# 资源文件
│   ├── Model.xcdatamodeld  		# Core Data 模型
│   ├── Models/                  	# 数据模型
│   ├── Navigation/             	# 导航相关
│   ├── Services/              		# 服务层
│   ├── Store/                		# 数据存储
│   ├── Utilities/           		# 工具类
│   ├── ViewModels/         		# 视图模型
│   ├── Views/             			# 视图组件
│   ├── ContentView.swift  			# 主内容视图
│   └── smtxApp.swift     			# 应用程序入口
│
├── smtxTests/                    	# 单元测试
├── smtxUITests/                 	# UI测试
└── smtx.xcodeproj/             	# Xcode项目配置
```

## 主要组件

### 1. 源代码 (`smtx/`)
主应用程序源代码目录包含：
- 应用程序源文件
- 资源文件（图片、素材等）
- 界面文件（Storyboards、XIBs）
- 支持文件

### 2. 测试

#### 单元测试 (`smtxTests/`)
包含用于测试单个组件和业务逻辑的单元测试。

#### UI测试 (`smtxUITests/`)
包含用于测试用户界面和集成场景的UI测试。

### 3. 文档 (`docs/`)
项目文档包括：
- 技术指南
- API文档
- 开发指南
- 项目概述

### 4. 项目配置 (`smtx.xcodeproj/`)
包含Xcode项目设置，包括：
- 构建配置
- Scheme定义
- 项目依赖
- 目标设置

## 最佳实践

在为本项目贡献代码时，请遵循以下结构指南：

1. 将相关文件放在适当的目录中
2. 遵循既定的命名规范
3. 将新文档放在适当的docs子目录中
4. 在smtxTests目录中为新功能添加单元测试
5. 在smtxUITests目录中为新界面元素添加UI测试

## 添加新功能

添加新功能时：
1. 为你的功能创建适当的目录结构
2. 如果添加了新的主要组件，请更新此文档
3. 遵循现有的项目组织模式
4. 在适当的测试目录中包含必要的测试文件
