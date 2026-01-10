# Holo

一个使用 Flutter 构建的开源看番 APP，支持 Android、iOS 平台。

## 功能特性

- 📺 **动漫播放**：轻松观看您喜爱的动漫
- 📅 **更新日历**：随时了解最新动漫更新
- 🔍 **搜索功能**：快速高效地查找动漫
- 💾 **观看历史**：跟踪您的观看进度
- 💬 **弹幕功能**：支持实时弹幕互动体验
- 🌍 **多语言支持**：支持多种语言的国际化界面
- 🌐 **多平台支持**：覆盖 Android、iOS

## App Screenshots

<div align="center">
  <img src="screenshot/home.png" alt="Home Screen" width="30%"/>
  <img src="screenshot/detail.png" alt="Detail Screen" width="30%"/>
  <img src="screenshot/player1.png" alt="Player Screen" width="30%"/>
</div>

<div align="center">
  <img src="screenshot/player2.png" alt="Player Screen with Danmaku" width="30%"/>
  <img src="screenshot/weekly.png" alt="Weekly Schedule" width="30%"/>
  <img src="screenshot/setting.png" alt="Settings" width="30%"/>
</div>

<div align="center">
  <img src="screenshot/Subscribe.png" alt="Subscribe Page" width="30%"/>
</div>

## 特别感谢

- **弹幕提供**：[canvas_danmaku](https://github.com/huangxd-/danmu_api)
- **番剧源信息**： [bangumi/api](https://github.com/bangumi/api)


## 项目结构

```
lib/
├── entity/          # 数据模型
├── service/         # API 服务和业务逻辑
│   ├── impl/        # 服务实现
│   └── util/        # 工具函数
├── ui/              # UI 组件和页面
│   ├── component/   # 可复用组件
│   └── screen/      # 应用页面
└── main.dart        # 应用入口
```

## 快速开始

### 前提条件

- Flutter SDK (>= 3.10.3)
- Dart SDK (>= 3.10.3)
- 安装了 Flutter 插件的 IDE（Android Studio、VS Code 等）

### 安装步骤

1. 克隆仓库

   ```bash
   git clone https://github.com/qiqd/holo.git
   cd holo
   ```

2. 安装依赖

   ```bash
   flutter pub get
   ```

3. 生成 JSON 序列化文件

   ```bash
   flutter pub run build_runner build
   ```

4. 运行应用
   ```bash
   flutter run
   ```

### 构建生产版本

- Android

  ```bash
  flutter build apk
  ```

- iOS
  ```bash
  flutter build ios
  ```

## 贡献指南

欢迎贡献！请随时提交 Pull Request。

## 许可证

本项目采用 AGPL-3.0 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。
