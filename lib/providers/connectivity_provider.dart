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
    NotifierProvider<NetworkStatusNotifier, NetworkStatus>(() {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends Notifier<NetworkStatus> {
  late StreamSubscription<InternetStatus> _subscription;

  @override
  NetworkStatus build() {
    _initConnectionChecking();
    ref.onDispose(() {
      _subscription.cancel();
    });
    return const NetworkStatus(isOffline: false);
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

}
