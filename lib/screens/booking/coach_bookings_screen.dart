import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
        ).showSnackBar(SnackBar(content: Text('Failed to load bookings: $e')));
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
        ).showSnackBar(SnackBar(content: Text('Booking $status successfully')));
        _loadBookings(); // Refresh lists
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Future<String?> _showReasonDialog(String title, String label) async {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to ${title.toLowerCase()}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      appBar: AppBar(
        title: Text(
          'Manage Bookings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(),
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final player = booking['player'] ?? {};
        final session = booking['session'] ?? {};
        final date = DateTime.parse(booking['occurrenceDate']).toLocal();
        final status = booking['status'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        player['profilePhoto'] ?? 'https://i.pravatar.cc/150',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player['fullName'] ?? 'Unknown Player',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session['title'] ?? 'Unknown Session',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('MMM d, y').format(date)} • ${DateFormat('h:mm a').format(date)}',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                  fontSize: 13,
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
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status == 'pending') ...[
                        OutlinedButton(
                          onPressed: () =>
                              _updateBookingStatus(booking['_id'], 'declined'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _updateBookingStatus(booking['_id'], 'confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept'),
                        ),
                      ] else if (status != 'cancelled' &&
                          status != 'declined') ...[
                        OutlinedButton.icon(
                          onPressed: () => _cancelBooking(booking['_id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel / Refund'),
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
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
      case 'declined':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
