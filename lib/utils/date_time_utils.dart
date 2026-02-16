import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Get current date in "MMM DD, YYYY" format (e.g., "JAN 24, 2026")
  static String getCurrentDateFormatted() {
    final now = DateTime.now();
    final monthAbbr = _getMonthAbbreviation(now.month);
    return '$monthAbbr ${now.day}, ${now.year}'.toUpperCase();
  }

  /// Get greeting based on current time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Get month abbreviation
  static String _getMonthAbbreviation(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  /// Format time from ISO string to "HH:MM AM/PM"
  /// Converts from UTC to local time if the ISO string is in UTC
  static String formatTime(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString).toLocal();
      return DateFormat('h:mm a').format(dateTime).toUpperCase();
    } catch (e) {
      return 'TBD';
    }
  }

  /// Format relative time (e.g., "15 mins ago", "2 hrs ago")
  static String formatRelativeTime(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        final mins = difference.inMinutes;
        return '$mins min${mins == 1 ? '' : 's'} ago';
      } else if (difference.inHours < 24) {
        final hrs = difference.inHours;
        return '$hrs hr${hrs == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return '$days day${days == 1 ? '' : 's'} ago';
      } else {
        return DateFormat('MMM dd').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  /// Format date to "MMM DD" (e.g., "JAN 24")
  static String formatDateShort(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString).toLocal();
      return DateFormat('MMM dd').format(dateTime).toUpperCase();
    } catch (e) {
      return '';
    }
  }

  /// Format date to full format "MMMM DD, YYYY" (e.g., "January 24, 2026")
  static String formatDateFull(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString).toLocal();
      return DateFormat('MMMM dd, yyyy').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  /// Format session date (e.g., "Tomorrow, 10:00 AM" or "Mon, Jan 25 • 2:00 PM")
  static String formatSessionDate(DateTime dateTime) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final time = DateFormat('h:mm a').format(dateTime);

    if (targetDay == today) {
      return 'Today, $time';
    } else if (targetDay == tomorrow) {
      return 'Tomorrow, $time';
    } else {
      final dayOfWeek = DateFormat('EEE').format(dateTime);
      final date = DateFormat('MMM d').format(dateTime);
      return '$dayOfWeek, $date • $time';
    }
  }

  /// Format duration in minutes to readable format (e.g., "1h 30m", "45m")
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      if (remainingMins == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMins}m';
      }
    }
  }

  /// Format duration in minutes to readable format (e.g., "1d 2h 30m", "2h 45m")
  static String formatDurationDetailed(int totalMinutes) {
    if (totalMinutes < 0) return '0m';

    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes % (24 * 60)) ~/ 60;
    final minutes = totalMinutes % 60;

    List<String> parts = [];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');

    if (parts.isEmpty) return '0m';
    return parts.join(' ');
  }

  /// Get time until session starts (e.g., "Starts in 2h 30m", "Started 15m ago")
  static String getTimeUntilSession(DateTime startTime) {
    final now = DateTime.now();
    final difference = startTime.difference(now);

    if (difference.isNegative) {
      // Session already started
      final elapsed = now.difference(startTime);
      if (elapsed.inMinutes < 60) {
        return 'Started ${elapsed.inMinutes}m ago';
      } else {
        return 'In progress';
      }
    } else {
      // Session in future
      if (difference.inMinutes < 60) {
        return 'Starts in ${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        final mins = difference.inMinutes % 60;
        if (mins == 0) {
          return 'Starts in ${hours}h';
        } else {
          return 'Starts in ${hours}h ${mins}m';
        }
      } else {
        final days = difference.inDays;
        return 'In $days day${days == 1 ? '' : 's'}';
      }
    }
  }

  /// Format DateTime object to time string
  static String formatTimeFromDateTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime).toUpperCase();
  }

  /// Format DateTime object to short date
  static String formatDateShortFromDateTime(DateTime dateTime) {
    return DateFormat('MMM dd').format(dateTime).toUpperCase();
  }

  /// Format DateTime object to standard date (e.g., "MMM dd, yyyy")
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
