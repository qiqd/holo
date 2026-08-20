<div align="right">
  [<a href="README.md">English</a>] | [<a href="README_zh.md">简体中文</a>]
</div>

<div align="center">
  <img src="screenshot/launcher_round.png" alt="Holo Logo" width="20%"/>
</div>

# Holo

An open-source anime streaming application built with Flutter, Supports Windows, macOS, Android and iOS platforms.

## Features

- 📺 **Anime Streaming**: Watch your favorite anime with ease
- 📅 **Calendar**: Stay updated with the latest anime releases
- 🔍 **Search**: Find anime quickly and efficiently
- 💾 **History**: Keep track of your watching progress
- 💬 **Danmaku Support**: Display danmaku to enhance viewing experience
- 🌍 **Multi-language Support**: Internationalized interface supporting multiple languages
- 🌐 **Multi-platform**: Supports Windows, macOS, Android and iOS
- 🖼️ **Image Search**: Search for anime by uploading images

## App Screenshots

<div align="center">
  <img src="screenshot/mobile-home.png" alt="Home Screen" width="25%"/>
  <img src="screenshot/desktop-home.png" alt="Detail Screen" width="57%"/>
  
</div>

## Acknowledgments

- **Danmaku API Library**: [canvas_danmaku](https://github.com/huangxd-/danmu_api)
- **Anime Metainfo Provider**: [bangumi/api](https://github.com/bangumi/api)
- **Image Search Provider**: [AnimeTrace](https://ai.animedb.cn)
- **Hitokoto API**: [sekaiai.github.io](https://github.com/sekaiai/sekaiai.github.io)

## Project Structure

```bash
lib/
├── entity/          # Data models
├── service/         # API services and business logic
│   ├── impl/        # Service implementations
│   └── util/        # Utility functions
├── ui/              # UI components and screens
│   ├── component/   # Reusable components
│   └── screen/      # Application screens
└── main.dart        # Application entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.10.3)
- Dart SDK (>= 3.10.3)
- IDE (Android Studio, VS Code, etc.) with Flutter plugin

### Installation

1. Clone the repository

   ```bash
   git clone https://github.com/qiqd/holo.git
   cd holo
   ```

2. Install dependencies

   ```bash
   flutter pub get
   ```

3. Configure environment variables

   Create a `.env` file in the root directory of the project.

4. Generate JSON serialization files

   ```bash
   flutter pub run build_runner build
   ```

5. Run the application

   ```bash
   flutter run
   ```

### Build for Production

- Android

  ```bash
  flutter build apk
  ```

- iOS

  ```bash
  flutter build ios
  ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.
