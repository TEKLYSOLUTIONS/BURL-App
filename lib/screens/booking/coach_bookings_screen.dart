import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/palette.dart';
import '../../utils/responsive.dart';
import '../../services/booking_service.dart';

class CoachBookingsScreen extends ConsumerStatefulWidget {
  const CoachBookingsScreen({super.key});

  @override
  ConsumerState<CoachBookingsScreen> createState() =>
      _CoachBookingsScreenState();
}

class _CoachBookingsScreenState extends ConsumerState<CoachBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _upcomingBookings = [];
  List<dynamic> _pastBookings = [];
  List<dynamic> _cancelledBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[CoachBookingsScreen] Loading bookings...');
      // Load all types in parallel
      final upcoming = await BookingService.getCoachBookings(type: 'upcoming');
      final past = await BookingService.getCoachBookings(type: 'past');
      final cancelled = await BookingService.getCoachBookings(
        type: 'cancelled',
      );

      debugPrint(
        '[CoachBookingsScreen] Upcoming: ${upcoming['bookings'].length}',
      );
      debugPrint('[CoachBookingsScreen] Past: ${past['bookings'].length}');
      debugPrint(
        '[CoachBookingsScreen] Cancelled: ${cancelled['bookings'].length}',
      );

      if (mounted) {
        setState(() {
          _upcomingBookings = upcoming['bookings'];
          _pastBookings = past['bookings'];
          _cancelledBookings = cancelled['bookings'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CoachBookingsScreen] Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: $e'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      if (status == 'declined' || status == 'cancelled') {
        // Show reason dialog for decline/cancel
        final reason = await _showReasonDialog(
          status == 'declined' ? 'Decline Booking' : 'Cancel Booking',
          status == 'declined'
              ? 'Reason for declining:'
              : 'Reason for cancelling:',
        );

        if (reason == null) return; // User cancelled dialog

        await BookingService.updateBookingStatus(
          bookingId,
          status,
          reason: reason,
        );
      } else {
        // Directly update for confirmed
        await BookingService.updateBookingStatus(bookingId, status);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('Booking $status successfully'),
            backgroundColor: AppPalette.successGreen,
          ),
        );
        _loadBookings(); // Refresh lists
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  Future<String?> _showReasonDialog(String title, String label) async {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: context.text.h4,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to ${title.toLowerCase()}?',
              style: GoogleFonts.inter(
                fontSize: context.text.body,
              ),
            ),
            SizedBox(height: context.spacing.md),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.error,
            ),
            child: Text(title),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    await _updateBookingStatus(bookingId, 'cancelled');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Manage Bookings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          indicatorColor: AppPalette.orangeAccent,
          labelColor: AppPalette.white,
          unselectedLabelColor: AppPalette.white.withValues(alpha: 0.7),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppPalette.orangeAccent,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(_upcomingBookings, showActions: true),
                _buildBookingList(_pastBookings),
                _buildBookingList(_cancelledBookings),
              ],
            ),
    );
  }

  Widget _buildBookingList(List<dynamic> bookings, {bool showActions = false}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: context.responsive.circularSize(32),
              color: AppPalette.textDisabled,
            ),
            SizedBox(height: context.spacing.lg),
            Text(
              'No bookings found',
              style: GoogleFonts.inter(
                fontSize: context.text.body,
                color: AppPalette.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.spacing.md),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final player = booking['player'] ?? {};
        final session = booking['session'] ?? {};
        final date = DateTime.parse(booking['occurrenceDate']).toLocal();
        final status = booking['status'];

        return Card(
          margin: EdgeInsets.only(bottom: context.spacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: context.responsive.circularSize(12),
                      backgroundImage: NetworkImage(
                        player['profilePhoto'] ?? 'https://i.pravatar.cc/150',
                      ),
                    ),
                    SizedBox(width: context.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player['fullName'] ?? 'Unknown Player',
                            style: GoogleFonts.inter(
                              fontSize: context.text.h4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: context.spacing.xs),
                          Text(
                            session['title'] ?? 'Unknown Session',
                            style: GoogleFonts.inter(
                              fontSize: context.text.caption,
                              color: AppPalette.textSecondaryLight,
                            ),
                          ),
                          SizedBox(height: context.spacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppPalette.textSecondaryLight,
                              ),
                              SizedBox(width: context.spacing.xs),
                              Text(
                                '${DateFormat('MMM d, y').format(date)} • ${DateFormat('h:mm a').format(date)}',
                                style: GoogleFonts.inter(
                                  fontSize: context.text.caption,
                                  color: AppPalette.textSecondaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                if (showActions) ...[
                  Divider(height: context.spacing.lg * 1.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status == 'pending') ...[
                        OutlinedButton(
                          onPressed: () =>
                              _updateBookingStatus(booking['_id'], 'declined'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppPalette.error,
                            side: BorderSide(color: AppPalette.error),
                            minimumSize: const Size(90, 40),
                          ),
                          child: const Text('Decline'),
                        ),
                        SizedBox(width: context.spacing.sm),
                        ElevatedButton(
                          onPressed: () =>
                              _updateBookingStatus(booking['_id'], 'confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.successGreen,
                            foregroundColor: AppPalette.white,
                            minimumSize: const Size(90, 40),
                          ),
                          child: const Text('Accept'),
                        ),
                      ] else if (status != 'cancelled' &&
                          status != 'declined') ...[
                        OutlinedButton.icon(
                          onPressed: () => _cancelBooking(booking['_id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppPalette.error,
                            side: BorderSide(color: AppPalette.error),
                            minimumSize: const Size(140, 40),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppPalette.successGreen;
        break;
      case 'pending':
        color = AppPalette.orangeAccent;
        break;
      case 'cancelled':
      case 'declined':
        color = AppPalette.error;
        break;
      case 'completed':
        color = AppPalette.navyPrimary;
        break;
      default:
        color = AppPalette.textDisabled;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
