import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../config/palette.dart';
import '../../widgets/app_time_picker.dart';
import '../../services/session_service.dart';

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
  late TabController _tabController;

  // Calendar State
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDays = {DateTime.now()};

  // Time Slots State
  final List<TimeSlot> _timeSlots = [
    TimeSlot(
      startTime: const TimeOfDay(hour: 9, minute: 0),
      durationMinutes: 90,
    ),
  ];

  // Logistics State
  int _capacity = 18;

  // Participants State
  final List<String> _participants = [
    'https://i.pravatar.cc/150?u=kevin',
    'https://i.pravatar.cc/150?u=marcus',
    'https://i.pravatar.cc/150?u=phil',
  ];
  final Set<int> _selectedParticipants = {0}; // Select first by default

  // API State
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          // Clear multiple selections if switching to Single
          if (_tabController.index == 0 && _selectedDays.length > 1) {
            final first = _selectedDays.first;
            _selectedDays.clear();
            _selectedDays.add(first);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      if (_tabController.index == 0) {
        // Single Session: Clear and select only one
        _selectedDays.clear();
        _selectedDays.add(selectedDay);
      } else {
        // Recurring Session: Toggle selection
        if (_isDaySelected(selectedDay)) {
          _selectedDays.removeWhere((d) => isSameDay(d, selectedDay));
        } else {
          _selectedDays.add(selectedDay);
        }
      }
    });
  }

  bool _isDaySelected(DateTime day) {
    return _selectedDays.any((d) => isSameDay(d, day));
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

                  _buildScheduleSection(),
                  const SizedBox(height: 32),

                  _buildLogisticsSection(),
                  const SizedBox(height: 32),

                  _buildParticipantsSection(),
                  const SizedBox(height: 32),
                  _buildBottomAction(), // Moved to end of page
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      // bottomSheet removed
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
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 24), // Balance the back button
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

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Schedule & Time',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
            if (_tabController.index ==
                1) // Only show RECURRING label in Recurring mode
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'RECURRING',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.only(bottom: 12),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 0)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: _isDaySelected,
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
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'DEFINED TIME SLOTS',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ..._timeSlots.asMap().entries.map(
          (entry) => _buildTimeSlotCard(entry.key, entry.value),
        ),
        _buildAddTimeSlotButton(),
      ],
    );
  }

  Widget _buildTimeSlotCard(int index, TimeSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Time',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await AppTimePicker.show(
                      context,
                      initialTime: slot.startTime,
                    );
                    if (time != null) {
                      setState(() {
                        _timeSlots[index] = slot.copyWith(startTime: time);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          slot.startTime.format(context),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.access_time_filled,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: slot.durationMinutes,
                      isExpanded: true,
                      icon: const Icon(Icons.expand_more, size: 16),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppPalette.navyPrimary,
                      ),
                      items: [30, 60, 90, 120].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value min'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _timeSlots[index] = slot.copyWith(
                              durationMinutes: val,
                            );
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_timeSlots.length > 1)
            IconButton(
              onPressed: () {
                setState(() {
                  _timeSlots.removeAt(index);
                });
              },
              icon: Icon(Icons.close, size: 16, color: Colors.grey[400]),
            ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildAddTimeSlotButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _timeSlots.add(
            TimeSlot(
              startTime: const TimeOfDay(hour: 16, minute: 30),
              durationMinutes: 60,
            ),
          );
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: DottedBorderContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle,
              color: AppPalette.orangeAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Add Another Time Slot',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
                color: AppPalette.navyPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: AppPalette.orangeAccent,
                ),
                hintText: 'Search for training ground...',
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
      ],
    );
  }

  Widget _buildStepper({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        InkWell(
          onTap: () => value > 1 ? onChanged(value - 1) : null,
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
          onTap: () => onChanged(value + 1),
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

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Assign Players',
          action: TextButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.add,
              size: 16,
              color: AppPalette.orangeAccent,
            ),
            label: Text(
              'Add All',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppPalette.orangeAccent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._participants.asMap().entries.map((entry) {
                final isSelected = _selectedParticipants.contains(entry.key);
                final names = ['Kevin D.', 'Marcus R.', 'Phil F.'];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedParticipants.remove(entry.key);
                            } else {
                              _selectedParticipants.add(entry.key);
                            }
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppPalette.orangeAccent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(entry.value),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppPalette.orangeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        names[entry.key],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Column(
                children: [
                  Container(
                    height: 62, // Matches avatar size with padding
                    width: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle
                            .solid, // Dashed would strictly require custom painter
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.group_add, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Teams',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createSession() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a session title');
      return;
    }

    if (_selectedDays.isEmpty) {
      _showError('Please select at least one date');
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter a location');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Transform UI data to API format
      final timeSlots = _timeSlots
          .map(
            (slot) => {
              'startTime': {
                'hour': slot.startTime.hour,
                'minute': slot.startTime.minute,
              },
              'durationMinutes': slot.durationMinutes,
            },
          )
          .toList();

      final selectedDays = _selectedDays
          .map((date) => DateFormat('yyyy-MM-dd').format(date))
          .toList();

      // Call API
      await SessionService.createSession(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        capacity: _capacity,
        timeSlots: timeSlots,
        selectedDays: selectedDays,
        isRecurring: _tabController.index == 1,
        participants: [], // Empty for now
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to create session: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildBottomAction() {
    final isRecurring = _tabController.index == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.orangeAccent,
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isCreating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isRecurring ? 'Create Recurring Session' : 'Create Session',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
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
