# PocketMusic 🎵

一个现代化的 iOS 离线音乐播放器，灵感来自 foobar2000，使用 Swift 和 SwiftUI 构建。

## ✨ 特性

### 核心功能
- 🎵 **广泛的音频格式支持** - 支持 20+ 种音频格式
  - 无损格式：FLAC, ALAC, WAV, AIFF, APE, WV
  - 有损格式：MP3, AAC, M4A, OGG, OPUS, WMA
  - 其他格式：CAF, M4B, M4P, MP2, MPA
- 📁 **文件系统浏览** - 保留原始文件夹结构，类似文件管理器的浏览体验
- 📥 **灵活的导入** - 支持从本地文件和 iCloud Drive 导入音乐及歌词文件
- 🎨 **动态背景** - 基于专辑封面的智能取色和动态渐变背景（类似 Apple Music）
- 🔍 **强大的搜索** - 搜索歌曲名、艺术家、专辑等元数据
- 📝 **歌词支持** - 完整的歌词功能
  - 支持外部 .lrc 文件（时间轴同步）
  - 支持内嵌歌词提取
  - 自动滚动和高亮当前歌词
  - Apple Music 风格的歌词显示

### 播放功能
- ⏯️ 播放、暂停、上一曲、下一曲
- 🔀 随机播放
- 🔁 重复播放（单曲/列表/关闭）
- 🔊 音量控制
- ⏱️ 进度条拖动
- 🎵 后台播放支持

### 歌词功能
- 📝 **LRC 格式解析** - 完整支持 LRC 歌词文件格式
  - 时间戳解析（支持 mm:ss.xx 和 mm:ss.xxx 格式）
  - 元数据标签（标题、艺术家、专辑等）
  - 多时间戳支持（一行歌词多个时间点）
- 🎯 **智能歌词加载**
  - 自动检测同目录下的同名 .lrc 文件
  - 导入时自动复制关联的歌词文件
  - 支持从音频文件元数据提取内嵌歌词
- 📱 **优雅的显示效果**
  - 实时同步滚动
  - 当前行高亮放大
  - 平滑过渡动画
  - 支持点击专辑封面切换歌词/封面视图

### 用户界面
- 🎨 原生 SwiftUI 界面
- 🌈 动态主题颜色（根据专辑封面智能提取）
- 📱 支持 iPhone 和 iPad
- 🔄 横屏和竖屏支持
- 💫 流畅的动画和转场效果
- 🎯 Apple Music 风格的播放器界面

## 🏗️ 项目架构

```
PocketMusic/
├── PocketMusic/
│   ├── PocketMusicApp.swift          # 应用入口
│   ├── Models/                       # 数据模型
│   │   ├── MusicFile.swift          # 音乐文件模型（扩展格式支持）
│   │   ├── Folder.swift             # 文件夹模型
│   │   ├── PlaybackState.swift      # 播放状态模型
│   │   └── Lyrics.swift             # 歌词模型（NEW）
│   ├── ViewModels/                   # 视图模型
│   │   ├── MusicLibraryViewModel.swift
│   │   └── PlayerViewModel.swift
│   ├── Views/                        # 视图
│   │   ├── ContentView.swift        # 主视图
│   │   ├── FileExplorerView.swift   # 文件浏览器
│   │   ├── PlayerView.swift         # 播放器界面（升级版）
│   │   ├── ImportView.swift         # 导入界面
│   │   └── Components/              # 可复用组件
│   │       ├── MusicFileRowView.swift
│   │       ├── DynamicBackgroundView.swift
│   │       └── LyricsView.swift     # 歌词显示组件（NEW）
│   └── Services/                     # 服务层
│       ├── FileManagerService.swift  # 文件管理服务（增强）
│       ├── AudioPlayerService.swift  # 音频播放服务（详细注释）
│       ├── ColorExtractorService.swift # 颜色提取服务（优化）
│       └── LyricsService.swift      # 歌词服务（NEW）
└── README.md
```

## 🛠️ 技术栈

- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI
- **音频播放**: AVFoundation
- **架构模式**: MVVM
- **响应式编程**: Combine
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
7. 如果有 .lrc 歌词文件，它们会自动一起导入

### 浏览和播放

1. 在"音乐库"标签中浏览你的音乐文件
2. 点击文件夹进入子目录
3. 点击音乐文件开始播放
4. 切换到"正在播放"标签查看播放界面

### 查看歌词

1. 在播放界面，如果歌曲有歌词，会显示"点击封面查看歌词"提示
2. 点击专辑封面或"显示歌词"按钮切换到歌词视图
3. 歌词会随着播放自动滚动和高亮
4. 再次点击或点击"专辑封面"按钮切换回封面视图

### 搜索音乐

1. 在"音乐库"标签中使用顶部搜索框
2. 输入歌曲名、艺术家或专辑名
3. 点击搜索结果中的音乐开始播放

## 🎨 设计理念

### 类似 foobar2000 的体验
- 保留原始文件结构，不强制重新组织音乐库
- 提供简洁、高效的文件浏览界面
- 专注于音乐播放的核心功能
- 支持广泛的音频格式

### Apple Music 风格的播放界面
- 动态背景颜色根据专辑封面自动提取
- 流畅的渐变动画
- 原生 iOS 设计语言
- 优雅的歌词显示效果

## 🔧 开发路线图

### 已完成 ✅
- ✅ 基本的文件管理和浏览功能
- ✅ 音频播放核心功能
- ✅ 动态背景效果
- ✅ 文件导入功能
- ✅ 搜索功能
- ✅ 扩展的音频格式支持（20+ 格式）
- ✅ LRC 歌词文件解析
- ✅ 内嵌歌词提取
- ✅ 歌词同步显示
- ✅ Apple Music 风格的播放器界面
- ✅ 代码优化和详细注释

### 计划中 ⏳
- ⏳ 播放列表管理和编辑
- ⏳ 收藏夹功能
- ⏳ 均衡器
- ⏳ 睡眠定时器
- ⏳ 更多歌词格式支持（SRT, ASS）
- ⏳ 歌词编辑器
- ⏳ 音乐统计和播放历史
- ⏳ CarPlay 支持
- ⏳ Widget 支持
- ⏳ 深色模式优化
- ⏳ 更智能的颜色提取算法
- ⏳ 支持更多元数据格式

## 📝 LRC 歌词格式说明

PocketMusic 支持标准 LRC 格式歌词文件。LRC 文件应与音乐文件同名并放在同一目录下。

### LRC 格式示例

```lrc
[ti:歌曲标题]
[ar:艺术家]
[al:专辑名称]
[by:歌词制作者]
[offset:0]

[00:12.00]第一句歌词
[00:17.20]第二句歌词
[00:21.10]第三句歌词
[00:24.00][00:27.00]重复的歌词（支持多个时间戳）
[00:31.50]
```

### 支持的标签
- `[ti:...]` - 歌曲标题
- `[ar:...]` - 艺术家
- `[al:...]` - 专辑
- `[au:...]` - 歌词作者
- `[by:...]` - LRC 制作者
- `[offset:...]` - 时间偏移（毫秒）
- `[length:...]` - 歌曲长度

### 文件命名规则
- 音乐文件：`歌曲名.mp3`
- 歌词文件：`歌曲名.lrc`

例如：
```
我的歌曲/
├── 歌曲1.mp3
├── 歌曲1.lrc    ← 自动关联
├── 歌曲2.flac
└── 歌曲2.lrc    ← 自动关联
```

## 🏛️ 架构设计原则

### 解耦与单一职责
- **Models** - 纯数据模型，不包含业务逻辑
- **Services** - 独立的服务层，每个服务专注于一个领域
  - `AudioPlayerService` - 音频播放
  - `FileManagerService` - 文件管理
  - `LyricsService` - 歌词处理
  - `ColorExtractorService` - 颜色提取
- **ViewModels** - 连接 Services 和 Views，处理业务逻辑
- **Views** - 纯 UI 层，通过 EnvironmentObject 访问 ViewModels

### 详细注释
- 所有公共 API 都有完整的文档注释
- 复杂算法有详细的实现说明
- 使用 `// MARK:` 组织代码结构
- 关键决策点有注释解释

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
