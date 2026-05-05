import 'dart:io';

class ApiConfig {
  // Environment Configuration
  // Set to true when building for production (deployed backend)
  static const bool isProduction = true; // LOCAL DEV MODE

  // 🔧 PHYSICAL DEVICE TESTING
  // Set to true when testing on a physical Android device via USBS
  // Set to false when testing on Android Emulator
  static const bool isPhysicalDevice = true;

  // Development URLs (for emulator/simulator testing)
  static const String _baseUrlEmulator = 'http://10.0.2.2:4000/api';
  // Physical device using adb reverse tunnel
  static const String _baseUrlPhysicalDevice = 'http://127.0.0.1:4000/api';
  static const String _baseUrlIOS = 'http://localhost:4000/api';
  static const String _baseUrlWindows = 'http://localhost:4000/api';

  // Production URL (for deployed backend)
  // ✅ Updated with Render.com deployment URL
  static const String _baseUrlProduction =
      'https://api-g3j6nukjya-uc.a.run.app/api';

  static const String googleMapsApiKey =
      'AIzaSyA49gBcEHS6benjXtwA2rakOLejlmDFd-0';

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
