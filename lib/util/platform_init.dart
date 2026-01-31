// Platform-specific initialization

// Conditionally import based on platform
import 'dart:io';

// For desktop platforms, import media_kit
// For mobile platforms, this import will still be present
// but we'll only use it in desktop-specific code
import 'package:media_kit/media_kit.dart' as media_kit;

/// Initialize platform-specific dependencies
Future<void> initializePlatformDependencies() async {
  if (Platform.isWindows || Platform.isLinux) {
    // For desktop platforms, initialize media_kit
    try {
      media_kit.MediaKit.ensureInitialized();
    } catch (e) {
      // Ignore errors if media_kit is not available
    }
  }
}
