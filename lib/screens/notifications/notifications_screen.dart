import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../services/notification_service.dart';

class NotificationItem {
  final String id;
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
  final String
  category; // 'Mentions', 'Schedule', 'Performance', 'Payments', 'Other'

  NotificationItem({
    required this.id,
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

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // Parse icon data from backend
    final icon = json['icon'] as Map<String, dynamic>?;
    IconData? iconData;
    Color? iconColor;
    Color? iconBg;

    if (icon != null) {
      iconData = _mapIconName(icon['icon'] as String?);
      iconColor = _parseColor(icon['color'] as String?);
      iconBg = _parseColor(icon['bg'] as String?);
    }

    return NotificationItem(
      id: json['_id'] as String,
      title: json['title'] as String,
      time: json['timeAgo'] as String? ?? '',
      description: json['description'] as String?,
      avatar: json['sender']?['profilePicture'] as String?,
      iconData: iconData,
      iconColor: iconColor,
      iconBg: iconBg,
      isUnread: !(json['isRead'] as bool? ?? false),
      isLike: json['type'] == 'like',
      actionButton: json['actionButton']?['text'] as String?,
      category: json['category'] as String? ?? 'Other',
    );
  }

  static IconData _mapIconName(String? iconName) {
    const iconMap = {
      'calendar_today': Icons.calendar_today,
      'check_circle': Icons.check_circle,
      'cancel': Icons.cancel,
      'alarm': Icons.alarm,
      'update': Icons.update,
      'event_busy': Icons.event_busy,
      'payment': Icons.payment,
      'hourglass_empty': Icons.hourglass_empty,
      'star': Icons.star,
      'comment': Icons.comment,
      'mail': Icons.mail,
      'emoji_events': Icons.emoji_events,
      'info': Icons.info,
    };
    return iconMap[iconName] ?? Icons.notifications;
  }

  static Color _parseColor(String? colorName) {
    const colorMap = {
      'orange': Colors.orange,
      'blue': Colors.blue,
      'green': Colors.green,
      'red': Colors.red,
      'purple': Colors.purple,
      'grey': Colors.grey,
    };
    return colorMap[colorName] ?? Colors.grey;
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';
  List<NotificationItem> _allNotifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await NotificationService.getNotifications(
        category: _selectedFilter == 'All' ? 'all' : _selectedFilter,
        limit: 50,
      );

      final notificationsList = data['notifications'] as List;
      setState(() {
        _allNotifications = notificationsList
            .map(
              (json) => NotificationItem.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
      setState(() {
        final index = _allNotifications.indexWhere(
          (n) => n.id == notificationId,
        );
        if (index != -1) {
          _allNotifications[index] = NotificationItem(
            id: _allNotifications[index].id,
            title: _allNotifications[index].title,
            time: _allNotifications[index].time,
            description: _allNotifications[index].description,
            avatar: _allNotifications[index].avatar,
            iconData: _allNotifications[index].iconData,
            iconColor: _allNotifications[index].iconColor,
            iconBg: _allNotifications[index].iconBg,
            isUnread: false,
            isLike: _allNotifications[index].isLike,
            typeIcon: _allNotifications[index].typeIcon,
            actionButton: _allNotifications[index].actionButton,
            category: _allNotifications[index].category,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to mark as read: $e')));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      setState(() {
        _allNotifications = _allNotifications.map((n) {
          return NotificationItem(
            id: n.id,
            title: n.title,
            time: n.time,
            description: n.description,
            avatar: n.avatar,
            iconData: n.iconData,
            iconColor: n.iconColor,
            iconBg: n.iconBg,
            isUnread: false,
            isLike: n.isLike,
            typeIcon: n.typeIcon,
            actionButton: n.actionButton,
            category: n.category,
          );
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
      setState(() {
        _allNotifications.removeWhere((n) => n.id == notificationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification: $e')),
        );
      }
    }
  }

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
    final filtered = _filteredNotifications;
    final newNotifications = filtered.where((i) => i.isUnread).toList();
    final earlierNotifications = filtered.where((i) => !i.isUnread).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppPalette.surfaceGlassDark
                  : AppPalette.navyPrimary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
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
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load notifications',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadNotifications,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                _buildFilterChip(
                                  'Performance',
                                  icon: Icons.bar_chart,
                                ),
                                _buildFilterChip(
                                  'Payments',
                                  icon: Icons.payment,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          if (_allNotifications.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 64),
                                  Icon(
                                    Icons.notifications_none,
                                    size: 80,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications yet',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

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
                            ...newNotifications.map(
                              (n) => _buildNotificationCard(n),
                            ),
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
                            ...earlierNotifications.map(
                              (n) => _buildNotificationCard(n),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {IconData? icon}) {
    final isSelected = _selectedFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : AppPalette.navyPrimary;
    final unselectedColor = isDark ? Colors.white70 : AppPalette.navyPrimary;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: icon != null
            ? Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : unselectedColor,
              )
            : null,
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : unselectedColor,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        selectedColor: selectedColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected
              ? BorderSide.none
              : BorderSide(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onSelected: (val) {
          setState(() {
            _selectedFilter = label;
            _loadNotifications();
          });
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(item.id);
      },
      child: GestureDetector(
        onTap: () {
          if (item.isUnread) {
            _markAsRead(item.id);
          }
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                            border: Border.all(
                              color: Theme.of(context).cardColor,
                              width: 2,
                            ),
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
                    color:
                        item.iconBg ??
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.iconData,
                    color:
                        item.iconColor ??
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
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
                              color: Theme.of(context).colorScheme.onSurface,
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
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
                          color: Theme.of(context).textTheme.bodyMedium?.color,
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
                          color: isDark
                              ? AppPalette.orangeAccent.withValues(alpha: 0.1)
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.actionButton!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppPalette.orangeAccent
                                : Colors.orange[800],
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
      ),
    );
  }
}
