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

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            Colors.white.withValues(alpha: 0.1),
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
              Icon(
                hasNotification
                    ? Icons.notifications
                    : Icons.notifications_none,
                color: widget.iconColor ?? Colors.white,
                size: 20,
              ),
              if (hasNotification && widget.showCount)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              else if (hasNotification)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
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
