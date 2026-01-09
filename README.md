# Holo

An open-source anime streaming application built with Flutter, supporting Android and iOS platforms.

## Features

- 📺 **Anime Streaming**: Watch your favorite anime with ease
- 📅 **Calendar**: Stay updated with the latest anime releases
- 🔍 **Search**: Find anime quickly and efficiently
- 💾 **History**: Keep track of your watching progress
- 🔔 **Subscribe**: Get notified when new episodes are available
- 💬 **Danmaku Support**: Real-time interactive bullet chat experience
- 🌍 **Multi-language Support**: Internationalized interface supporting multiple languages
- 🔄 **Loading Optimization**: Shimmer effects to optimize loading experience
- **Multi-platform**: Supports Android and iOS

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

## Acknowledgments for System Functions

- **Danmaku API Library**: [canvas_danmaku](https://github.com/huangxd-/danmu_api)
- **Anime Source Provider**: [bangumi/api](https://github.com/bangumi/api)

## Project Structure

```
lib/
├── entity/          # Data models
├── service/         # API services and business logic
│   ├── impl/        # Service implementations
│   └── util/        # Utility functions
├── ui/              # UI components and screens
│   ├── component/   # Reusable components
│   └── screen/      # Application screens
├── util/            # Utility classes
└── main.dart        # Application entry point
```

## Environment Configuration

This project uses `flutter_dotenv` to manage environment variables. Create a `.env` file in the project root directory and configure the following variables:

```
DAMMAKU_SERVER_URL=your_danmaku_server_url
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

3. Generate JSON serialization files

   ```bash
   flutter pub run build_runner build
   ```

4. Run the application
   ```bash
   flutter run
   ```

### Build for Production

- Android

  ```bash
  flutter build apk --dart-define=DAMMAKU_SERVER_URL=your_danmaku_server_url
  ```

- iOS
  ```bash
  flutter build ios --dart-define=DAMMAKU_SERVER_URL=your_danmaku_server_url
  ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

```

```
