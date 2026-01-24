import 'dart:io';

class ApiConfig {
  // Environment Configuration
  // Set to true when building for production (physical devices)
  // Set to false when testing on emulator/simulator
  static const bool isProduction = false;

  // Development URLs (for emulator/simulator testing)
  static const String _baseUrlAndroid = 'http://10.0.2.2:4000/api';
  static const String _baseUrlIOS = 'http://localhost:4000/api';

  // Production URL (for physical devices)
  // TODO: Update this URL after deploying to Render.com
  static const String _baseUrlProduction =
      'https://your-app-name.onrender.com/api';

  static String get baseUrl {
    // Use production URL when isProduction is true
    if (isProduction) {
      return _baseUrlProduction;
    }

    // Use development URLs based on platform
    if (Platform.isAndroid) {
      return _baseUrlAndroid;
    } else {
      return _baseUrlIOS;
    }
  }
}
