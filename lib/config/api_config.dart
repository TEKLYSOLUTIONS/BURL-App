import 'dart:io';

class ApiConfig {
  // Environment Configuration
  // Set to true when building for production (deployed backend)
  static const bool isProduction = false; // 🔧 DEVELOPMENT MODE

  // 🔧 PHYSICAL DEVICE TESTING
  // Set to true when testing on a physical Android device via USB
  // Set to false when testing on Android Emulator
  static const bool isPhysicalDevice = false;

  // Development URLs (for emulator/simulator testing)
  static const String _baseUrlEmulator = 'http://10.0.2.2:4000/api';
  // Physical device uses localhost via ADB reverse tunnel (run: adb reverse tcp:4000 tcp:4000)
  static const String _baseUrlPhysicalDevice = 'http://localhost:4000/api';
  static const String _baseUrlIOS = 'http://localhost:4000/api';
  static const String _baseUrlWindows = 'http://localhost:4000/api';

  // Production URL (for deployed backend)
  // ✅ Updated with Render.com deployment URL
  static const String _baseUrlProduction =
      'https://cricket-coaching-backend.onrender.com/api';

  static String get baseUrl {
    // Use production URL when isProduction is true
    if (isProduction) {
      return _baseUrlProduction;
    }

    // Use development URLs based on platform
    if (Platform.isAndroid) {
      // Use physical device URL or emulator URL based on flag
      return isPhysicalDevice ? _baseUrlPhysicalDevice : _baseUrlEmulator;
    } else if (Platform.isWindows) {
      return _baseUrlWindows;
    } else {
      return _baseUrlIOS;
    }
  }
}
