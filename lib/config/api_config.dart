import 'dart:io';

class ApiConfig {
  static const String _baseUrlAndroid = 'http://10.0.2.2:4000/api';
  static const String _baseUrlIOS = 'http://localhost:4000/api';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return _baseUrlAndroid;
    } else {
      return _baseUrlIOS;
    }
  }
}
