import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// A simple class representing network status.
class NetworkStatus {
  final bool isOffline;

  const NetworkStatus({required this.isOffline});
}

/// Provider that exposes the current network status.
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  late StreamSubscription<InternetStatus> _subscription;

  NetworkStatusNotifier() : super(const NetworkStatus(isOffline: false)) {
    _initConnectionChecking();
  }

  void _initConnectionChecking() {
    // Listen for internet connection status changes
    _subscription =
        InternetConnection().onStatusChange.listen((InternetStatus status) {
      if (status == InternetStatus.connected) {
        state = const NetworkStatus(isOffline: false);
      } else {
        state = const NetworkStatus(isOffline: true);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
