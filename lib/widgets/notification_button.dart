import 'package:flutter/material.dart';

class NotificationButton extends StatelessWidget {
  final bool hasNotification;
  final VoidCallback? onTap;

  const NotificationButton({
    super.key,
    this.hasNotification = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // Glassy effect
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                hasNotification
                    ? Icons.notifications
                    : Icons.notifications_none,
                color: Colors.white,
                size: 20,
              ),
              if (hasNotification)
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
