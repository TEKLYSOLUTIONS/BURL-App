import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../widgets/app_time_picker.dart';
import '../../services/places_service.dart';
import '../../services/session_service.dart';
import '../../widgets/notification_button.dart';
import 'package:go_router/go_router.dart';

class CreateSessionScreen extends StatefulWidget {
  final Map<String, dynamic>? sessionToEdit;

  const CreateSessionScreen({super.key, this.sessionToEdit});

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

  // Overlay & Search
  final _layerLink = LayerLink();
  final _locationFocus = FocusNode();
  Timer? _debounce;
  List<PlacePrediction> _predictions = [];
  OverlayEntry? _overlayEntry;

  // State
  // Selection
  final Set<DateTime> _selectedDates = {};
  DateTime _focusedDay = DateTime.now();

  // Schedule Source of Truth: Date -> List of Slots
  final Map<DateTime, List<Map<String, TimeOfDay>>> _sessionSchedule = {};

  // Logistics State
  int _capacity = 18;
  bool _pricePerPerson = true;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // API State
  bool _isCreating = false;

  bool get _isEditing => widget.sessionToEdit != null;

  @override
  void initState() {
    super.initState();
    // Default selection: Today
    final now = DateTime.now();
    final today = _normalizeDate(now);
    _selectedDates.add(today);
    _focusedDay = today;

    // Default slot for today
    _sessionSchedule[today] = [
      {
        'startTime': const TimeOfDay(hour: 9, minute: 0),
        'endTime': const TimeOfDay(hour: 10, minute: 30),
      },
    ];

    if (_isEditing) {
      _initializeEditingState();
    }
  }

  void _initializeEditingState() {
    final s = widget.sessionToEdit!;
    _titleController.text = s['title'] ?? '';
    _descriptionController.text = s['description'] ?? '';
    _locationController.text = s['location'] ?? '';
    _capacity = s['capacity'] ?? 18;

    // Pricing
    if (s['pricing'] != null) {
      final amount = s['pricing']['amount'];
      _priceController.text = amount != null ? amount.toString() : '0';
      _pricePerPerson = s['pricing']['pricePerPerson'] ?? true;
    }

    // Populate Schedule
    final timeSlots = s['timeSlots'] as List<dynamic>? ?? [];

    // Clear defaults
    _selectedDates.clear();
    _sessionSchedule.clear();

    if (timeSlots.isEmpty) return;

    for (final slot in timeSlots) {
      if (slot['startTime'] == null) continue;

      final startDateTime = DateTime.parse(slot['startTime']).toLocal();
      final endDateTime = slot['endTime'] != null
          ? DateTime.parse(slot['endTime']).toLocal()
          : startDateTime.add(Duration(minutes: slot['durationMinutes'] ?? 60));

      final dateKey = _normalizeDate(startDateTime);
      _selectedDates.add(dateKey); // Select the date

      if (!_sessionSchedule.containsKey(dateKey)) {
        _sessionSchedule[dateKey] = [];
      }

      // Add slot if not duplicate
      final exists = _sessionSchedule[dateKey]!.any(
        (existing) =>
            existing['startTime']!.hour == startDateTime.hour &&
            existing['startTime']!.minute == startDateTime.minute,
      );

      if (!exists) {
        _sessionSchedule[dateKey]!.add({
          'startTime': TimeOfDay.fromDateTime(startDateTime),
          'endTime': TimeOfDay.fromDateTime(endDateTime),
        });
      }
    }

    if (_selectedDates.isNotEmpty) {
      _focusedDay = _selectedDates.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _locationFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      final normalized = _normalizeDate(selectedDay);

      if (_selectedDates.contains(normalized)) {
        _selectedDates.remove(normalized);
      } else {
        _selectedDates.add(normalized);
        if (!_sessionSchedule.containsKey(normalized)) {
          _sessionSchedule[normalized] = [];
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

                  // Unified Schedule Section
                  _buildUnifiedSchedule(),

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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
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
                  _isEditing ? 'Edit Session' : 'Create Session',
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
            color: Theme.of(context).colorScheme.onSurface,
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
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

  Widget _buildUnifiedSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dates & Time',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select multiple dates to create recurring sessions.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),

        // Multi-Select Calendar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDates.contains(_normalizeDate(day)),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              weekendStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final normalized = _normalizeDate(date);
                if (_sessionSchedule.containsKey(normalized) &&
                    _sessionSchedule[normalized]!.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      width: 6.0,
                      height: 6.0,
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              weekendTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 1,
                ),
              ),
              todayTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.secondary,
              ),
              disabledTextStyle: GoogleFonts.inter(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Time Slots Manager
        _buildTimeSlotManager(),
      ],
    );
  }

  Widget _buildTimeSlotManager() {
    if (_selectedDates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 40,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No dates selected',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    // Determine slots to show
    final Set<String> uniqueSlotKeys = {};
    final Map<String, Map<String, TimeOfDay>> keyToSlot = {};
    final Map<String, int> slotCounts = {};

    for (final date in _selectedDates) {
      final slots = _sessionSchedule[date] ?? [];
      for (final slot in slots) {
        final key =
            '${slot['startTime']!.format(context)}-${slot['endTime']!.format(context)}';
        if (!uniqueSlotKeys.contains(key)) {
          uniqueSlotKeys.add(key);
          keyToSlot[key] = slot;
        }
        slotCounts[key] = (slotCounts[key] ?? 0) + 1;
      }
    }

    final sortedKeys = uniqueSlotKeys.toList()
      ..sort((a, b) {
        final tA = keyToSlot[a]!['startTime']!;
        final tB = keyToSlot[b]!['startTime']!;
        if (tA.hour != tB.hour) return tA.hour.compareTo(tB.hour);
        return tA.minute.compareTo(tB.minute);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Time Slots',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_selectedDates.length} Days Selected',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Existing Slots
        ...sortedKeys.map((key) {
          final slot = keyToSlot[key]!;
          final count = slotCounts[key] ?? 0;
          final isAll = count == _selectedDates.length;

          return _buildUnifiedTimeSlotRow(slot, isAll, count);
        }),

        const SizedBox(height: 12),

        // Add Button
        InkWell(
          onTap: () {
            // Add default slot to ALL selected dates
            setState(() {
              for (final date in _selectedDates) {
                if (!_sessionSchedule.containsKey(date)) {
                  _sessionSchedule[date] = [];
                }

                final list = _sessionSchedule[date]!;
                var startHour = 9;
                if (list.isNotEmpty) {
                  startHour = list.last['endTime']!.hour;
                }

                // Avoid duplicates
                final exists = list.any(
                  (s) => s['startTime']!.hour == startHour,
                );
                if (!exists) {
                  list.add({
                    'startTime': TimeOfDay(hour: startHour, minute: 0),
                    'endTime': TimeOfDay(hour: startHour + 1, minute: 30),
                  });
                }
              }
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.5),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Time Slot to All Selected',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedTimeSlotRow(
    Map<String, TimeOfDay> slot,
    bool isAll,
    int count,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAll
                      ? Theme.of(context).dividerColor.withValues(alpha: 0.5)
                      : Colors.orange.withValues(
                          alpha: 0.3,
                        ), // Keep orange warning? or use secondary?
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Start Time
                      InkWell(
                        onTap: () async {
                          final newStart = await AppTimePicker.show(
                            context,
                            initialTime: slot['startTime']!,
                          );
                          if (newStart == null) return;

                          setState(() {
                            for (final date in _selectedDates) {
                              final list = _sessionSchedule[date];
                              if (list == null) continue;

                              for (final s in list) {
                                if (s['startTime']!.hour ==
                                        slot['startTime']!.hour &&
                                    s['startTime']!.minute ==
                                        slot['startTime']!.minute) {
                                  s['startTime'] = newStart;
                                  final startMin =
                                      slot['startTime']!.hour * 60 +
                                      slot['startTime']!.minute;
                                  final endMin =
                                      slot['endTime']!.hour * 60 +
                                      slot['endTime']!.minute;
                                  final duration = endMin - startMin;

                                  final newStartMin =
                                      newStart.hour * 60 + newStart.minute;
                                  final newEndMin = newStartMin + duration;

                                  s['endTime'] = TimeOfDay(
                                    hour: (newEndMin ~/ 60) % 24,
                                    minute: newEndMin % 60,
                                  );
                                }
                              }
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Text(
                              _formatTimeOfDay(slot['startTime']!),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '-',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ),

                      // End Time
                      InkWell(
                        onTap: () async {
                          final newEnd = await AppTimePicker.show(
                            context,
                            initialTime: slot['endTime']!,
                          );
                          if (newEnd == null) return;

                          // Validate validation: End time must be after start time
                          final startMin =
                              slot['startTime']!.hour * 60 +
                              slot['startTime']!.minute;
                          final endMin = newEnd.hour * 60 + newEnd.minute;

                          if (endMin <= startMin) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'End time must be after start time',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }

                          setState(() {
                            for (final date in _selectedDates) {
                              final list = _sessionSchedule[date];
                              if (list == null) continue;

                              for (final s in list) {
                                if (s['startTime']!.hour ==
                                        slot['startTime']!.hour &&
                                    s['startTime']!.minute ==
                                        slot['startTime']!.minute) {
                                  s['endTime'] = newEnd;
                                }
                              }
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Text(
                              _formatTimeOfDay(slot['endTime']!),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ],
                        ),
                      ),

                      if (!isAll)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$count/${_selectedDates.length}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete Button
          InkWell(
            onTap: () {
              setState(() {
                for (final date in _selectedDates) {
                  final list = _sessionSchedule[date];
                  if (list != null) {
                    list.removeWhere(
                      (s) =>
                          s['startTime']!.hour == slot['startTime']!.hour &&
                          s['startTime']!.minute == slot['startTime']!.minute,
                    );
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red[400],
              ),
            ),
          ),
        ],
      ),
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _locationController,
                focusNode: _locationFocus,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  hintText: 'Search or pick on map...',
                  hintStyle: GoogleFonts.inter(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
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
                    target: LatLng(37.422131, -122.084801),
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.groups,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Player Capacity',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Session Fee',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
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
                  hintStyle: GoogleFonts.inter(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
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
              // Only show pricing type selector if multiple dates are selected
              if (_selectedDates.length > 1) ...[
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
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _pricePerPerson
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).dividerColor,
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
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
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
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !_pricePerPerson
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).dividerColor,
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
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
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
      if (!mounted) return;

      setState(() {
        _predictions = predictions;
      });
      if (_predictions.isNotEmpty) {
        if (context.mounted) {
          _showOverlay();
        }
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 48,
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
      _locationController.text =
          "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(position));

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
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.remove,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$value',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => value < max ? onChanged(value + 1) : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.4),
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
                    _isEditing ? 'Save Changes' : 'Create Session',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isEditing ? Icons.save : Icons.calendar_today,
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

    if (_selectedDates.isEmpty) {
      _showError('Please select at least one date');
      return;
    }

    // Validate if dates are in the past and if they have timeslots
    final now = DateTime.now();

    // Check each selected date
    for (final date in _selectedDates) {
      final slots = _sessionSchedule[date];
      if (slots == null || slots.isEmpty) {
        _showError('Please add time slots for all selected dates');
        return;
      }

      for (final slot in slots) {
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

    setState(() => _isCreating = true);

    try {
      final isRecurring = _selectedDates.length > 1;
      List<String> selectedDays = [];
      List<Map<String, dynamic>> timeSlots = [];
      List<Map<String, dynamic>> explicitTimeSlots = [];

      final sortedDates = _selectedDates.toList()
        ..sort((a, b) => a.compareTo(b));

      for (final date in sortedDates) {
        final dateStr = date.toIso8601String().split('T')[0];
        selectedDays.add(dateStr);

        final slots = _sessionSchedule[date]!;
        for (final slot in slots) {
          final startTime = slot['startTime']!;
          final endTime = slot['endTime']!;

          // Calculate duration
          final startMin = startTime.hour * 60 + startTime.minute;
          final endMin = endTime.hour * 60 + endTime.minute;
          final duration = endMin - startMin;

          final dt = DateTime(
            date.year,
            date.month,
            date.day,
            startTime.hour,
            startTime.minute,
          );

          explicitTimeSlots.add({
            'startTime': dt.toIso8601String(),
            'durationMinutes': duration > 0 ? duration : 60,
          });

          if (!isRecurring) {
            timeSlots.add({
              'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
              'durationMinutes': duration > 0 ? duration : 60,
            });
          }
        }
      }

      if (_isEditing) {
        final updates = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'capacity': _capacity,
          'pricing': {
            'amount': double.tryParse(_priceController.text.trim()) ?? 0.0,
            'currency': 'USD',
            'pricePerPerson': _pricePerPerson,
          },
        };

        await SessionService.updateSession(
          widget.sessionToEdit!['_id'],
          updates,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session Updated Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await SessionService.createSession(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          capacity: _capacity,
          timeSlots: timeSlots,
          explicitTimeSlots: explicitTimeSlots,
          selectedDays: selectedDays,
          isRecurring: isRecurring,
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
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to ${_isEditing ? 'update' : 'create'}: $e');
      }
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

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.none,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor, width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
