import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_notification_service.dart';

class StartupService {
  StartupService._();

  /// Call once from main() after Firebase init.
  /// Handles prompting for Push Notifications and Location on first run.
  static Future<void> initializeAppStartup() async {
    // 1. Initialize Push Notifications (triggers iOS/Android 13+ permission prompt)
    // The underlying method has its own check so it won't prompt twice.
    await PushNotificationService.initialize();

    // 2. Ask for Location Permission if not already asked
    await _requestLocationPermission();
  }

  static Future<void> _requestLocationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAskedLoc = prefs.getBool('has_asked_location') ?? false;

    // Only prompt aggressively on the very first fresh run of the app
    if (!hasAskedLoc) {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, don't ask for permission yet
        // Let the map/search screen handle this later
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // This triggers the OS system prompt
        debugPrint('📍 Requesting Location Permission...');
        permission = await Geolocator.requestPermission();
        
        // Mark that we've asked so we don't bombard them on every hot reload/restart
        await prefs.setBool('has_asked_location', true);
      }
    }
  }
}
