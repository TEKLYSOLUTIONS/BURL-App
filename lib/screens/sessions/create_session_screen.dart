import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final List<DateTime?> _selectedDates = [DateTime(2023, 10, 24)];
  int _sessionCount = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 16, minute: 0);
  int _selectedDuration = 60; // in minutes
  int _maxCapacity = 24;

  final List<String> _participants = [
    'https://i.pravatar.cc/150?u=marcus',
    'https://i.pravatar.cc/150?u=sarah',
    'https://i.pravatar.cc/150?u=david',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session Title
                    const _SectionLabel(label: 'Session Title'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Varsity Drills',
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
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 20),

                    // Description
                    const _SectionLabel(label: 'Description', isOptional: true),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Add session details, objectives, or gear requirements...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),

                    // Timing Section
                    _buildTimingSection().animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),

                    // Logistics Section
                    _buildLogisticsSection().animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 24),

                    // Participants Section
                    _buildParticipantsSection().animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Create Session Button (Fixed at bottom)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          margin: const EdgeInsets.only(
            bottom: 70,
          ), // Extra space for floating nav bar
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              // Handle create session
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.orangeAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Create Session',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppPalette.navyPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Create Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Handle save draft
            },
            child: const Text(
              'Save Draft',
              style: TextStyle(
                color: AppPalette.orangeAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.schedule, color: AppPalette.orangeAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Timing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Session Count Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel(label: 'Number of Days'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_sessionCount > 1) {
                        setState(() {
                          _sessionCount--;
                          if (_selectedDates.length > _sessionCount) {
                            _selectedDates.removeLast();
                          }
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.remove,
                      color: AppPalette.navyPrimary,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    '$_sessionCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _sessionCount++;
                        // Initialize new date as null or day after last selected date
                        final lastDate = _selectedDates.isNotEmpty
                            ? _selectedDates.last
                            : DateTime.now();
                        _selectedDates.add(
                          lastDate?.add(const Duration(days: 1)),
                        );
                      });
                    },
                    icon: const Icon(Icons.add, color: AppPalette.navyPrimary),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Dynamic Date List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedDates.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Row(
              children: [
                // Date Picker
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDates[index] ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDates[index] = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppPalette.orangeAccent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDates[index] != null
                                ? 'Day ${index + 1}: ${_selectedDates[index]!.day}/${_selectedDates[index]!.month}'
                                : 'Select Day ${index + 1}',
                            style: const TextStyle(
                              color: AppPalette.navyPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // Start Time Picker (Common for all days for now, or per day if requested)
        // User asked for "create session screen" -> usually times are consistent,
        // but if they need different times per day that's a larger change.
        // For now, keeping single start time as per existing UI pattern, applied to all days.
        const _SectionLabel(label: 'Start Time (All Days)'),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _startTime,
            );
            if (time != null) {
              setState(() {
                _startTime = time;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: AppPalette.orangeAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  _startTime.format(context),
                  style: const TextStyle(
                    color: AppPalette.navyPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Duration
        const _SectionLabel(label: 'Duration'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDurationChip(30),
            const SizedBox(width: 8),
            _buildDurationChip(60),
            const SizedBox(width: 8),
            _buildDurationChip(90),
            const SizedBox(width: 8),
            _buildDurationChip(null, label: 'Custom'),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationChip(int? minutes, {String? label}) {
    final isSelected = _selectedDuration == minutes;
    final displayLabel = label ?? '$minutes min';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (minutes != null) {
            setState(() {
              _selectedDuration = minutes;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppPalette.orangeAccent : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppPalette.orangeAccent : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              displayLabel,
              style: TextStyle(
                color: isSelected ? Colors.white : AppPalette.navyPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, color: AppPalette.orangeAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Logistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Location
        const _SectionLabel(label: 'Location'),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Main Field - Pitch 1',
            prefixIcon: const Icon(
              Icons.search,
              color: AppPalette.textDisabled,
            ),
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
        const SizedBox(height: 16),

        // Max Capacity
        const _SectionLabel(label: 'Max Capacity'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_maxCapacity > 1) {
                    setState(() {
                      _maxCapacity--;
                    });
                  }
                },
                icon: const Icon(Icons.remove, color: AppPalette.navyPrimary),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_maxCapacity',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.orangeAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _maxCapacity++;
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.group, color: AppPalette.orangeAccent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Participants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Handle add players
              },
              child: const Text(
                'Add Players',
                style: TextStyle(
                  color: AppPalette.orangeAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Participant Avatars
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _participants.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Add Team button
                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppPalette.textDisabled,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add Team',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppPalette.textDisabled,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final participantIndex = index - 1;
              final names = ['Marcus', 'Sarah', 'David'];

              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(
                            _participants[participantIndex],
                          ),
                          backgroundColor: AppPalette.orangeAccent,
                        ),
                        if (participantIndex == 0)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppPalette.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      names[participantIndex],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppPalette.navyPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isOptional;

  const _SectionLabel({required this.label, this.isOptional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppPalette.navyPrimary,
          ),
        ),
        if (isOptional) ...[
          const SizedBox(width: 6),
          Text(
            '(Optional)',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }
}
