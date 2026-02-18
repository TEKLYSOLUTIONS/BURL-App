import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

class NotificationButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showCount;

  const NotificationButton({
    super.key,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.showCount = true,
  });

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Public method to refresh count (can be called from parent)
  void refresh() {
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final hasNotification = _unreadCount > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color:
            widget.backgroundColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05)),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            widget.onTap?.call();
            // Refresh count when opened
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _loadUnreadCount();
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Icon(
                  hasNotification
                      ? Icons
                            .notifications_active // Changed icon for active state
                      : Icons.notifications_none,
                  color:
                      widget.iconColor ??
                      (isDark
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).primaryColor), // Use primary color for light theme
                  size: 24, // Increased size
                ),
              ),
              if (hasNotification && widget.showCount)
                Positioned(
                  top: -2, // Adjusted top position
                  right: -2, // Adjusted right position
                  child: Container(
                    padding: const EdgeInsets.all(4), // Increased padding
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ), // Add border for separation
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18, // Minimum width for the badge
                      minHeight: 18, // Minimum height for the badge
                    ),
                    child: Center(
                      child: Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
