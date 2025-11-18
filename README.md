# PocketMusic 🎵

一个现代化的 iOS 离线音乐播放器，灵感来自 foobar2000，使用 Swift 和 SwiftUI 构建。

## ✨ 特性

### 核心功能
- 🎵 **离线音乐播放** - 支持 MP3, M4A, AAC, WAV, FLAC, AIFF, ALAC 等格式
- 📁 **文件系统浏览** - 保留原始文件夹结构，类似文件管理器的浏览体验
- 📥 **灵活的导入** - 支持从本地文件和 iCloud Drive 导入音乐
- 🎨 **动态背景** - 基于专辑封面的智能取色和动态渐变背景
- 🔍 **强大的搜索** - 搜索歌曲名、艺术家、专辑等元数据

### 播放功能
- ⏯️ 播放、暂停、上一曲、下一曲
- 🔀 随机播放
- 🔁 重复播放（单曲/列表/关闭）
- 🔊 音量控制
- ⏱️ 进度条拖动

### 用户界面
- 🎨 原生 SwiftUI 界面
- 🌈 动态主题颜色（根据专辑封面提取）
- 📱 支持 iPhone 和 iPad
- 🔄 横屏和竖屏支持
- 💫 流畅的动画和转场效果

## 🏗️ 项目架构

```
PocketMusic/
├── PocketMusic/
│   ├── PocketMusicApp.swift          # 应用入口
│   ├── Models/                       # 数据模型
│   │   ├── MusicFile.swift          # 音乐文件模型
│   │   ├── Folder.swift             # 文件夹模型
│   │   └── PlaybackState.swift      # 播放状态模型
│   ├── ViewModels/                   # 视图模型
│   │   ├── MusicLibraryViewModel.swift
│   │   └── PlayerViewModel.swift
│   ├── Views/                        # 视图
│   │   ├── ContentView.swift        # 主视图
│   │   ├── FileExplorerView.swift   # 文件浏览器
│   │   ├── PlayerView.swift         # 播放器界面
│   │   ├── ImportView.swift         # 导入界面
│   │   └── Components/              # 可复用组件
│   │       ├── MusicFileRowView.swift
│   │       └── DynamicBackgroundView.swift
│   └── Services/                     # 服务层
│       ├── FileManagerService.swift  # 文件管理服务
│       ├── AudioPlayerService.swift  # 音频播放服务
│       └── ColorExtractorService.swift # 颜色提取服务
└── README.md
```

## 🛠️ 技术栈

- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI
- **音频播放**: AVFoundation
- **架构模式**: MVVM
- **最低支持**: iOS 17.0+

## 📋 系统要求

- iOS 17.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本

## 🚀 开始使用

### 1. 克隆项目

```bash
git clone <repository-url>
cd PocketMusic
```

### 2. 打开项目

使用 Xcode 打开项目：

```bash
open PocketMusic.xcodeproj
```

或者直接在 Xcode 中打开 `PocketMusic.xcodeproj`

### 3. 运行项目

1. 选择目标设备（模拟器或真机）
2. 点击运行按钮（⌘R）

## 📱 使用说明

### 导入音乐

1. 点击"音乐库"标签
2. 点击右上角的菜单按钮
3. 选择"导入文件"
4. 选择导入来源（本地文件或 iCloud Drive）
5. 选择是否保留文件夹结构
6. 选择要导入的音乐文件或文件夹

### 浏览和播放

1. 在"音乐库"标签中浏览你的音乐文件
2. 点击文件夹进入子目录
3. 点击音乐文件开始播放
4. 切换到"正在播放"标签查看播放界面

### 搜索音乐

1. 在"音乐库"标签中使用顶部搜索框
2. 输入歌曲名、艺术家或专辑名
3. 点击搜索结果中的音乐开始播放

## 🎨 设计理念

### 类似 foobar2000 的体验
- 保留原始文件结构，不强制重新组织音乐库
- 提供简洁、高效的文件浏览界面
- 专注于音乐播放的核心功能

### Apple Music 风格的播放界面
- 动态背景颜色根据专辑封面自动提取
- 流畅的渐变动画
- 原生 iOS 设计语言

## 🔧 开发路线图

### 已完成
- ✅ 基本的文件管理和浏览功能
- ✅ 音频播放核心功能
- ✅ 动态背景效果
- ✅ 文件导入功能
- ✅ 搜索功能

### 计划中
- ⏳ 播放列表管理
- ⏳ 收藏夹功能
- ⏳ 均衡器
- ⏳ 睡眠定时器
- ⏳ 歌词显示
- ⏳ 音乐统计和播放历史
- ⏳ CarPlay 支持
- ⏳ Widget 支持
- ⏳ 深色模式优化

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证。

## 👨‍💻 作者

PocketMusic Team

## 🙏 致谢

- 灵感来自 foobar2000
- UI 设计参考 Apple Music
- 使用 SwiftUI 和 AVFoundation 框架
