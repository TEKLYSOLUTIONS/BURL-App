import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/connectivity_provider.dart';

class GlobalOfflineBanner extends ConsumerWidget {
  const GlobalOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    if (!networkStatus.isOffline) {
      return const SizedBox.shrink(); // Return nothing when online
    }

    // Return the offline banner
    return Material(
      color: Colors.red.shade600,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'No Internet Connection',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
