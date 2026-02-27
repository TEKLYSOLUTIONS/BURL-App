import 'package:flutter/material.dart';

class SessionUtils {
  /// Get a dynamic image for the session based on its focus area or type
  static String getSessionImage(dynamic session) {
    // Verified Unsplash Images (Using ?w=400 for optimizations)
    const String defaultCricket =
        'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&q=80&w=400';
    const String batting =
        'https://images.unsplash.com/photo-1624526267942-ab449aaa65f2?auto=format&fit=crop&q=80&w=400';
    const String bowling =
        'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&q=80&w=400'; // Fallback to generic for now
    const String training =
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80&w=400';

    if (session == null) return defaultCricket;

    // Check focus areas
    final focusAreas = session['focusAreas'] as List<dynamic>?;
    if (focusAreas != null && focusAreas.isNotEmpty) {
      final mainFocus = focusAreas.first.toString().toLowerCase();

      if (mainFocus.contains('batting')) {
        return batting;
      } else if (mainFocus.contains('bowling')) {
        return bowling;
      } else if (mainFocus.contains('fielding')) {
        return defaultCricket;
      } else if (mainFocus.contains('fitness') ||
          mainFocus.contains('conditioning')) {
        return training;
      }
    }

    // Check session type
    final sessionType = session['sessionType']?.toString().toLowerCase();
    if (sessionType == 'match' || sessionType == 'tournament') {
      return defaultCricket;
    } else if (sessionType == 'camp') {
      return defaultCricket;
    }

    // Fallback based on titles
    final title = session['title']?.toString().toLowerCase() ?? '';
    if (title.contains('batting')) return batting;
    if (title.contains('fitness') || title.contains('gym')) return training;

    return defaultCricket;
  }

  /// Get a thematic background color shade for the session card based on type
  static Color getSessionColor(BuildContext context, dynamic session) {
    if (session == null) return Theme.of(context).cardColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if it's a booking or a 1-on-1 session
    final isBooking = session['isBooking'] == true ||
        session['type'] == 'booking' ||
        (session['title']?.toString().toLowerCase().contains('1-on-1') ??
            false);

    if (isBooking) {
      // 1-on-1 Session (Teal / Cyan tinted)
      return isDark ? const Color(0xFF003344) : const Color(0xFFE0F7FA);
    }

    final sessionType = session['sessionType']?.toString().toLowerCase();

    switch (sessionType) {
      case 'recurring':
        // Recurring Session (Greenish tinted)
        return isDark ? const Color(0xFF1B3B2B) : const Color(0xFFE8F5E9);
      case 'camp':
        // Camp Session (Warm Orange/Brown tinted)
        return isDark ? const Color(0xFF4A2B1D) : const Color(0xFFFFF3E0);
      case 'tournament':
      case 'match':
        // Tournament/Match (Purple tinted)
        return isDark ? const Color(0xFF2E1C40) : const Color(0xFFF3E5F5);
      case 'one-time':
      default:
        // Default card color
        return Theme.of(context).cardColor;
    }
  }

  /// Get a thematic primary/accent color for the session card based on type
  static Color getSessionPrimaryColor(BuildContext context, dynamic session) {
    if (session == null) return Theme.of(context).primaryColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if it's a booking or a 1-on-1 session
    final isBooking = session['isBooking'] == true ||
        session['type'] == 'booking' ||
        (session['title']?.toString().toLowerCase().contains('1-on-1') ??
            false);

    if (isBooking) {
      // 1-on-1 Session (Teal / Cyan)
      return isDark ? const Color(0xFF80DEEA) : const Color(0xFF00838F);
    }

    final sessionType = session['sessionType']?.toString().toLowerCase();

    switch (sessionType) {
      case 'recurring':
        // Recurring Session (Green)
        return isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32);
      case 'camp':
        // Camp Session (Warm Orange)
        return isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100);
      case 'tournament':
      case 'match':
        // Tournament/Match (Purple)
        return isDark ? const Color(0xFFCE93D8) : const Color(0xFF6A1B9A);
      case 'one-time':
      default:
        // Default primary color
        return Theme.of(context).primaryColor;
    }
  }
}
