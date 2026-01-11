import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';

class NotificationItem {
  final String title;
  final String time;
  final String? description;
  final String? avatar;
  final IconData? iconData;
  final Color? iconColor;
  final Color? iconBg;
  final bool isUnread;
  final bool isLike;
  final IconData? typeIcon;
  final String? actionButton;
  final String category; // 'Mentions', 'Schedule', 'Performance', 'Other'

  NotificationItem({
    required this.title,
    required this.time,
    this.description,
    this.avatar,
    this.iconData,
    this.iconColor,
    this.iconBg,
    this.isUnread = false,
    this.isLike = false,
    this.typeIcon,
    this.actionButton,
    required this.category,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  final List<NotificationItem> _allNotifications = [
    NotificationItem(
      avatar: 'https://i.pravatar.cc/150?u=coach',
      title: 'Coach Mike commented on your video',
      time: '2m ago',
      description:
          'Great form on that last rep! Keep those elbows tucked in on the drive. Your bat speed has improved significantly since last week. Let\'s focus on maintaining this consistency during the upcoming match properly. Keep up the hard work!',
      isUnread: true,
      typeIcon: Icons.videocam,
      category: 'Mentions',
    ),
    NotificationItem(
      iconBg: Colors.orange[50],
      iconColor: Colors.orange,
      iconData: Icons.calendar_today,
      title: 'Training session moved',
      time: '1h ago',
      description:
          "Today's 3:00 PM session is now at 4:00 PM due to field maintenance.",
      isUnread: true,
      category: 'Schedule',
    ),
    NotificationItem(
      iconBg: Colors.blue[50],
      iconColor: Colors.blue,
      iconData: Icons.emoji_events,
      title: 'New Personal Best! 🏆',
      time: '3h ago',
      description: 'You beat your 100m Dash record by 0.2s.',
      isUnread: true,
      actionButton: 'View Stats',
      category: 'Performance',
    ),
    NotificationItem(
      avatar: 'https://i.pravatar.cc/150?u=sarah',
      title: 'Sarah liked your sprint analysis',
      time: 'Yesterday',
      isLike: true,
      category: 'Mentions',
    ),
    NotificationItem(
      iconBg: Colors.grey[200],
      iconColor: Colors.grey[600],
      iconData: Icons.payment,
      title: 'Your subscription has been renewed',
      time: '2 days ago',
      category: 'Other',
    ),
    NotificationItem(
      iconBg: Colors.green[50],
      iconColor: Colors.green,
      iconData: Icons.directions_run,
      title: 'New drill assigned: HIIT Cardio',
      time: 'Last Week',
      category: 'Schedule',
    ),
  ];

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'All') {
      return _allNotifications;
    }
    return _allNotifications
        .where((item) => item.category == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Separate New and Earlier based on logic or just hardcoded for demo
    // For proper filtering, we might lose the "New/Earlier" split visualization if we just filter the list.
    // However, the original UI had "NEW" and "EARLIER" sections.
    // Let's simplified: If filter is All, show sections. If filter is specific, just show list?
    // Or simpler: Just re-group the filtered list.
    // For this implementation, I'll flatten the list when filtering if it's not 'All', or just maintain the headers if applicable.
    // To match user expectation: "click the categories that should be show the notification".

    final filtered = _filteredNotifications;
    // Simple heuristic: Unread = New, Read = Earlier
    final newNotifications = filtered.where((i) => i.isUnread).toList();
    final earlierNotifications = filtered.where((i) => !i.isUnread).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 20,
              24,
              30,
            ),
            decoration: const BoxDecoration(
              color: AppPalette.navyPrimary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (Navigator.of(context).canPop())
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                Text(
                  'Notifications',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.done_all, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        _buildFilterChip(
                          'Mentions',
                          icon: Icons.alternate_email,
                        ),
                        _buildFilterChip(
                          'Schedule',
                          icon: Icons.calendar_today,
                        ),
                        _buildFilterChip('Performance', icon: Icons.bar_chart),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (newNotifications.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NEW',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${newNotifications.length} unread',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...newNotifications.map(_buildNotificationCard),
                    const SizedBox(height: 32),
                  ],

                  if (earlierNotifications.isNotEmpty) ...[
                    Text(
                      'EARLIER',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...earlierNotifications.map(_buildNotificationCard),
                  ],

                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Text(
                          'No notifications found',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ].animate(interval: 50.ms).fadeIn().slideY(begin: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {IconData? icon}) {
    final isSelected = _selectedFilter == label;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: icon != null
            ? Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppPalette.navyPrimary,
              )
            : null,
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppPalette.navyPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        selectedColor: AppPalette.navyPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected
              ? BorderSide.none
              : BorderSide(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onSelected: (val) {
          setState(() {
            _selectedFilter = label;
          });
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/notification-detail',
          extra: {
            'title': item.title,
            'time': item.time,
            'description': item.description ?? 'No details available',
            'avatar': item.avatar,
            'iconData': item.iconData,
            'iconColor': item.iconColor,
            'iconBg': item.iconBg,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon or Avatar
            if (item.avatar != null)
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(item.avatar!),
                  ),
                  if (item.typeIcon != null || item.isLike)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: item.isLike
                              ? Colors.pink
                              : AppPalette.navyPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          item.isLike ? Icons.favorite : item.typeIcon,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.iconBg ?? Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.iconData, color: item.iconColor, size: 20),
              ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppPalette.navyPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (item.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppPalette.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.time,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (item.actionButton != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50], // Light orange
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.actionButton!,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
