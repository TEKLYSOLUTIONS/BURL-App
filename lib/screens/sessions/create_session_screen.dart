import 'dart:async'; // Add this for Timer
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/palette.dart';
import '../../widgets/app_time_picker.dart';
import '../../services/places_service.dart';
import '../../services/session_service.dart';
import '../../widgets/notification_button.dart';
import 'package:go_router/go_router.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  late TabController _tabController;

  // Autocomplete State
  List<PlacePrediction> _predictions = [];
  Timer? _debounce;
  final LayerLink _layerLink = LayerLink(); // For Overlay
  OverlayEntry? _overlayEntry;
  final FocusNode _locationFocus = FocusNode();

  // Calendar State
  DateTime _focusedDay = DateTime.now(); // Re-added

  // Single Session State
  DateTime _singleDate = DateTime.now();
  // List of time slots for single session: [{startTime, endTime}]
  final List<Map<String, TimeOfDay>> _singleTimeSlots = [
    {
      'startTime': const TimeOfDay(hour: 9, minute: 0),
      'endTime': const TimeOfDay(hour: 10, minute: 30),
    },
  ];

  // Recurring (Packet) State
  // Map of dates to their timeslots: {DateTime: [{startTime, endTime}]}
  final Map<DateTime, List<Map<String, TimeOfDay>>> _recurringTimeslots = {};
  DateTime? _selectedRecurringDate; // Currently selected date for editing timeslots

  // Logistics State
  int _capacity = 18;
  bool _pricePerPerson = true; // true = per person, false = per session
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // API State
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to toggle UI
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Normalize date to remove time component for map key
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Handler for Calendar selection
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });

    if (_tabController.index == 1) {
      // Recurring tab - select this date to show/edit timeslots
      setState(() {
        _selectedRecurringDate = _normalizeDate(selectedDay);
        // Initialize with empty list if no timeslots exist
        if (!_recurringTimeslots.containsKey(_selectedRecurringDate)) {
          _recurringTimeslots[_selectedRecurringDate!] = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Session Details'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'e.g. Tactical Drill & Strategy',
                    label: 'Session Title',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    hint: 'Outline objectives...',
                    label: 'Description',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),

                  // Schedule Section (Conditional)
                  if (_tabController.index == 0)
                    _buildSingleSessionSchedule()
                  else
                    _buildRecurringSessionSchedule(),

                  const SizedBox(height: 32),

                  _buildLogisticsSection(),
                  const SizedBox(height: 32),
                  _buildBottomAction(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppPalette.navyPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  'Create Session',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              NotificationButton(
                iconColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                onTap: () => context.push('/coach/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Custom Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: AppPalette.navyPrimary,
              unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Single'),
                Tab(text: 'Recurring'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppPalette.navyPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  // --- Single Session UI ---
  Widget _buildSingleSessionSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Calendar Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _singleDate,
            selectedDayPredicate: (day) => isSameDay(_singleDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _singleDate = selectedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
              leftChevronIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              rightChevronIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
              weekendStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: AppPalette.navyPrimary,
              ),
              weekendTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: AppPalette.navyPrimary,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppPalette.orangeAccent,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: AppPalette.orangeAccent, width: 1),
              ),
              todayTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: AppPalette.orangeAccent,
              ),
              disabledTextStyle: GoogleFonts.inter(color: Colors.grey[300]),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Time Slots Section
        Text(
          'Time Slots',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Time Slots List
        ..._singleTimeSlots.asMap().entries.map((entry) {
          final index = entry.key;
          final slot = entry.value;
          return _buildTimeSlotRow(index, slot);
        }),

        const SizedBox(height: 12),

        // Add Time Slot Button
        InkWell(
          onTap: () {
            setState(() {
              // Add a new time slot starting after the last one
              final lastSlot = _singleTimeSlots.last;
              final lastEndTime = lastSlot['endTime']!;
              final newStartHour = lastEndTime.hour + 1;
              _singleTimeSlots.add({
                'startTime': TimeOfDay(
                  hour: newStartHour > 23 ? 9 : newStartHour,
                  minute: 0,
                ),
                'endTime': TimeOfDay(
                  hour: newStartHour > 22 ? 10 : newStartHour + 1,
                  minute: 30,
                ),
              });
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppPalette.orangeAccent.withValues(alpha: 0.5),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppPalette.orangeAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Time Slot',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build individual time slot row with start and end time
  Widget _buildTimeSlotRow(int index, Map<String, TimeOfDay> slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Start Time
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await AppTimePicker.show(
                  context,
                  initialTime: slot['startTime']!,
                );
                if (picked != null) {
                  setState(() {
                    _singleTimeSlots[index]['startTime'] = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTimeOfDay(slot['startTime']!),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'START',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // End Time
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await AppTimePicker.show(
                  context,
                  initialTime: slot['endTime']!,
                );
                if (picked != null) {
                  setState(() {
                    _singleTimeSlots[index]['endTime'] = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTimeOfDay(slot['endTime']!),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'END',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Remove button (only if more than one slot)
          if (_singleTimeSlots.length > 1) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _singleTimeSlots.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.remove, size: 16, color: Colors.red[400]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper to format TimeOfDay to AM/PM string
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // --- Recurring (Packet) UI ---
  Widget _buildRecurringSessionSchedule() {
    // Count total sessions from all dates
    int totalSessions = _recurringTimeslots.values
        .fold(0, (sum, slots) => sum + slots.length);

    // Get current timeslots for selected date
    final currentTimeslots = _selectedRecurringDate != null
        ? (_recurringTimeslots[_selectedRecurringDate!] ?? [])
        : <Map<String, TimeOfDay>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recurring Sessions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 14,
                    color: AppPalette.orangeAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalSessions Timeslots',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppPalette.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select a date to add timeslots. Highlighted dates have sessions.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calendar Integration
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedRecurringDate != null &&
                isSameDay(day, _selectedRecurringDate!),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, size: 20),
              rightChevronIcon: const Icon(Icons.chevron_right, size: 20),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: Colors.orange),
              selectedDecoration: const BoxDecoration(
                color: AppPalette.orangeAccent,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: GoogleFonts.inter(fontSize: 12),
              weekendTextStyle: GoogleFonts.inter(fontSize: 12),
              outsideDaysVisible: false,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
              weekendStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final normalizedDay = _normalizeDate(day);
                final timeslotCount =
                    _recurringTimeslots[normalizedDay]?.length ?? 0;
                // Only show colored marker if the date has actual timeslots
                if (timeslotCount > 0 &&
                    !isSameDay(day, _selectedRecurringDate)) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppPalette.orangeAccent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.navyPrimary,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.orangeAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$timeslotCount',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Show timeslots section for selected date
        if (_selectedRecurringDate != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time Slots',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppPalette.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d').format(_selectedRecurringDate!),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time slots list
          ...currentTimeslots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                children: [
                  // Start Time
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await AppTimePicker.show(
                          context,
                          initialTime: slot['startTime']!,
                        );
                        if (picked != null) {
                          setState(() {
                            _recurringTimeslots[_selectedRecurringDate!]![index]
                                ['startTime'] = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatTimeOfDay(slot['startTime']!),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'START',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // End Time
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await AppTimePicker.show(
                          context,
                          initialTime: slot['endTime']!,
                        );
                        if (picked != null) {
                          setState(() {
                            _recurringTimeslots[_selectedRecurringDate!]![index]
                                ['endTime'] = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatTimeOfDay(slot['endTime']!),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'END',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Delete button
                  if (currentTimeslots.length > 1) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _recurringTimeslots[_selectedRecurringDate!]!
                              .removeAt(index);
                          // If no timeslots left, remove the date
                          if (_recurringTimeslots[_selectedRecurringDate!]!
                              .isEmpty) {
                            _recurringTimeslots.remove(_selectedRecurringDate);
                            _selectedRecurringDate = null;
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            );
          }),

          // Add time slot button
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  final lastSlot = currentTimeslots.isNotEmpty
                      ? currentTimeslots.last
                      : null;
                  _recurringTimeslots[_selectedRecurringDate!]!.add({
                    'startTime': lastSlot?['endTime'] ??
                        const TimeOfDay(hour: 9, minute: 0),
                    'endTime': TimeOfDay(
                      hour: (lastSlot?['endTime']?.hour ?? 9) + 1,
                      minute: lastSlot?['endTime']?.minute ?? 30,
                    ),
                  });
                });
              },
              icon: const Icon(Icons.add, color: Colors.orange),
              label: Text(
                'Add Time Slot',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.orangeAccent,
                side: const BorderSide(color: AppPalette.orangeAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Remove date button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _recurringTimeslots.remove(_selectedRecurringDate);
                  _selectedRecurringDate = null;
                });
              },
              icon: const Icon(Icons.delete_outline, color: Colors.orange),
              label: Text(
                'Remove This Date',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Logistics'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppPalette.navyPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Search Box wrapped in CompositedTransformTarget for Overlay
            CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _locationController,
                focusNode: _locationFocus,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: AppPalette.orangeAccent,
                  ),
                  hintText: 'Search or pick on map...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 16),

            // Inline Map Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(37.422131, -122.084801), // Default
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_selectedLocation != null) {
                      _mapController?.moveCamera(
                        CameraUpdate.newLatLng(_selectedLocation!),
                      );
                    }
                  },
                  onTap: _onMapTapped,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups, color: AppPalette.navyPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Player Capacity',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.navyPrimary,
                  ),
                ),
              ),
              _buildStepper(
                value: _capacity,
                onChanged: (val) => setState(() => _capacity = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Pricing Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_money, color: AppPalette.orangeAccent),
                  const SizedBox(width: 12),
                  Text(
                    'Session Fee',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText: '60',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  filled: true,
                  fillColor: AppPalette.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              // Only show pricing type selector for recurring sessions
              if (_tabController.index == 1) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _pricePerPerson = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _pricePerPerson
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _pricePerPerson
                                  ? Colors.orange
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            'Per Day',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: _pricePerPerson
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _pricePerPerson
                                  ? Colors.orange
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _pricePerPerson = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_pricePerPerson
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !_pricePerPerson
                                  ? Colors.orange
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            'Per Session',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: !_pricePerPerson
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: !_pricePerPerson
                                  ? Colors.orange
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _removeOverlay();
        return;
      }

      final predictions = await PlacesService.getAutocomplete(query);
      if (mounted) {
        setState(() {
          _predictions = predictions;
        });
        if (_predictions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();
    // context.findRenderObject() not needed if we rely on LayerLink which is pre-composited

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 48, // 24 padding each side
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = _predictions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      p.mainText,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      p.secondaryText,
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    onTap: () => _onPredictionSelected(p),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    _removeOverlay();
    _locationController.text = prediction.description;
    _locationFocus.unfocus();

    final details = await PlacesService.getPlaceDetails(prediction.placeId);
    if (details != null && mounted) {
      _onMapTapped(details.location);
    }
  }

  void _onMapTapped(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
      // Show coordinates temporarily while fetching address
      _locationController.text =
          "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    });

    // Animate camera to center
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));

    // Reverse geocode to get place name/address
    final address = await PlacesService.reverseGeocode(
      position.latitude,
      position.longitude,
    );
    if (address != null && mounted) {
      setState(() {
        _locationController.text = address;
      });
    }
  }

  Widget _buildStepper({
    required int value,
    required ValueChanged<int> onChanged,
    int min = 1,
    int max = 100,
  }) {
    return Row(
      children: [
        InkWell(
          onTap: () => value > min ? onChanged(value - 1) : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove, size: 16),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$value',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => value < max ? onChanged(value + 1) : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.orangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppPalette.orangeAccent.withValues(alpha: 0.4),
        ),
        child: _isCreating
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Session',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _createSession() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a session title');
      return;
    }

    // Validate that session date is not in the past
    final now = DateTime.now();
    if (_tabController.index == 0) {
      // Single session - check if any time slot is in the past
      for (final slot in _singleTimeSlots) {
        final startTime = slot['startTime']!;
        final sessionDateTime = DateTime(
          _singleDate.year,
          _singleDate.month,
          _singleDate.day,
          startTime.hour,
          startTime.minute,
        );
        if (sessionDateTime.isBefore(now)) {
          _showError('Cannot create a session in the past');
          return;
        }
      }
    } else {
      // Recurring sessions - check if any date is in the past
      for (final entry in _recurringTimeslots.entries) {
        final date = entry.key;
        for (final slot in entry.value) {
          final startTime = slot['startTime']!;
          final sessionDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            startTime.hour,
            startTime.minute,
          );
          if (sessionDateTime.isBefore(now)) {
            _showError('Cannot create sessions with past dates');
            return;
          }
        }
      }

      // Check if there are any timeslots
      if (_recurringTimeslots.isEmpty) {
        _showError('Please add at least one recurring session date');
        return;
      }
    }

    setState(() => _isCreating = true);

    try {
      // Prepare data in the format expected by the backend
      List<String> selectedDays;
      List<Map<String, dynamic>> timeSlots;

      if (_tabController.index == 0) {
        // Single session - convert time slots to backend format
        selectedDays = [_singleDate.toIso8601String().split('T')[0]];
        timeSlots = _singleTimeSlots.map((slot) {
          final startTime = slot['startTime']!;
          final endTime = slot['endTime']!;
          // Calculate duration in minutes
          final startMinutes = startTime.hour * 60 + startTime.minute;
          final endMinutes = endTime.hour * 60 + endTime.minute;
          final durationMinutes = endMinutes - startMinutes;
          return {
            'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
            'durationMinutes': durationMinutes > 0
                ? durationMinutes
                : 60, // Default to 60 if invalid
          };
        }).toList();
      } else {
        // Recurring sessions - flatten the map structure
        selectedDays = [];
        timeSlots = [];

        // Sort dates chronologically
        final sortedDates = _recurringTimeslots.keys.toList()
          ..sort((a, b) => a.compareTo(b));

        for (final date in sortedDates) {
          final slots = _recurringTimeslots[date]!;
          for (final slot in slots) {
            selectedDays.add(date.toIso8601String().split('T')[0]);
            final startTime = slot['startTime']!;
            final endTime = slot['endTime']!;
            // Calculate duration in minutes
            final startMinutes = startTime.hour * 60 + startTime.minute;
            final endMinutes = endTime.hour * 60 + endTime.minute;
            final durationMinutes = endMinutes - startMinutes;
            timeSlots.add({
              'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
              'durationMinutes': durationMinutes > 0
                  ? durationMinutes
                  : 60, // Default to 60 if invalid
            });
          }
        }
      }

      // Call the session service to create the session
      await SessionService.createSession(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        capacity: _capacity,
        timeSlots: timeSlots,
        selectedDays: selectedDays,
        isRecurring: _tabController.index == 1,
        participants: <String>[],
        priceAmount: double.tryParse(_priceController.text.trim()) ?? 0.0,
        pricePerPerson: _pricePerPerson,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session Created Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError('Failed to create: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class TimeSlot {
  final TimeOfDay startTime;
  final int durationMinutes;

  TimeSlot({required this.startTime, required this.durationMinutes});

  TimeSlot copyWith({TimeOfDay? startTime, int? durationMinutes}) {
    return TimeSlot(
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

class DottedBorderContainer extends StatelessWidget {
  final Widget child;

  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Simplified fake dotted border using dashed decoration logic or image is heavy.
    // Using simple border for now to avoid custom painter complexity unless requested.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.none,
        ), // Placeholder
      ),
      // Using Stack to simulate Dotted border or just simplified visual
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ), // Dashed effect tricky without package
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
