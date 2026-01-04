import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class CoachAvailabilityScreen extends StatefulWidget {
  const CoachAvailabilityScreen({super.key});

  @override
  State<CoachAvailabilityScreen> createState() =>
      _CoachAvailabilityScreenState();
}

class _CoachAvailabilityScreenState extends State<CoachAvailabilityScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock slots
  // final Map<DateTime, List<String>> _events = {
  //   DateTime.now(): ['10:00 AM - 11:00 AM', '02:00 PM - 03:00 PM'],
  // };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Availability',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Tab page
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddSlotDialog();
        },
        backgroundColor: AppPalette.orangeAccent,
        icon: const Icon(Icons.add),
        label: const Text('Add Slot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppPalette.navyPrimary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppPalette.navyPrimary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppPalette.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(),

            const SizedBox(height: 24),

            Text(
              'Available Slots',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // Slots List
            _buildSlotsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsList() {
    // For demo, just show dummy slots if date matches today or random
    // In real app, fetch from _events based on _selectedDay
    List<String> slots = isSameDay(_selectedDay, DateTime.now())
        ? ['10:00 AM - 11:00 AM', '02:00 PM - 03:00 PM', '04:00 PM - 05:00 PM']
        : [];

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No slots added for this day.',
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPalette.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppPalette.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    slots[index],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppPalette.navyPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                onPressed: () {
                  // Remove slot logic
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 100 + 300).ms).slideX();
      },
    );
  }

  void _showAddSlotDialog() {
    // Mock Dialog
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Availability',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start Time',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _mockTimePicker('10:00 AM'),
              const SizedBox(height: 16),
              Text(
                'End Time',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _mockTimePicker('11:00 AM'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.navyPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Slot'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mockTimePicker(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time, style: GoogleFonts.inter(fontSize: 16)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
