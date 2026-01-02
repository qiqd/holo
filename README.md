# Holo

An open-source anime streaming application built with Flutter, supporting Android and iOS platforms.

## Features

- 📺 **Anime Streaming**: Watch your favorite anime with ease
- 📅 **Calendar**: Stay updated with the latest anime releases
- 🔍 **Search**: Find anime quickly and efficiently
- 💾 **History**: Keep track of your watching progress
- 🔔 **Subscribe**: Get notified when new episodes are available
- **Multi-platform**: Supports Android and iOS

## Tech Stack

- **Framework**: Flutter
- **Routing**: GoRouter
- **Networking**: Dio
- **JSON Serialization**: json_annotation
- **Video Player**: video_player
- **Storage**: shared_preferences
- **Danmaku Support**: canvas_danmaku

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
