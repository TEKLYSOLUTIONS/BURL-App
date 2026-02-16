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
}
