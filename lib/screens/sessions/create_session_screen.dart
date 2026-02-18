import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart'; // Import TableCalendar
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import Google Maps
import '../../services/session_service.dart';
import '../../utils/location_search_delegate.dart';
import '../../screens/common/location_picker_screen.dart'; // Import Location Picker
import '../../widgets/modern_text_field.dart';
import '../../widgets/modern_duration_selector.dart';
// Removed unused import

class CreateSessionScreen extends StatefulWidget {
  final Map<String, dynamic>? sessionToEdit;

  const CreateSessionScreen({super.key, this.sessionToEdit});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Calendar State
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = {}; // Changed to Set for multi-selection

  // Form Data (Initialized with defaults or edit data)
  late Map<String, dynamic> _initialValues;

  @override
  void initState() {
    super.initState();
    _initialValues = _mapSessionToForm(widget.sessionToEdit);
  }

  Map<String, dynamic> _mapSessionToForm(Map<String, dynamic>? session) {
    if (session == null) {
      return {
        'sessionType': 'one-time',
        'skillLevel': 'All Levels',
        'capacity': 18.0,
        'pricingModel': 'per-session',
        'autoAccept': true,
        'cancellationPolicy': 'flexible',
        'duration': 60,
        'price': '0',
      };
    }
    // Map existing session data to form fields
    return {
      'title': session['title'],
      'description': session['description'],
      'location': session['location'],
      'sessionType':
          session['sessionType'] ??
          (session['isRecurring'] == true ? 'recurring' : 'one-time'),
      'focusAreas': session['focusAreas'] != null
          ? List<String>.from(session['focusAreas'])
          : [],
      'skillLevel': session['skillLevel'] ?? 'All Levels',
      'ageGroups': session['ageGroups'] != null
          ? List<String>.from(session['ageGroups'])
          : [],
      'capacity':
          (session['capacity'] is Map
                  ? session['capacity']['max']
                  : (session['capacity'] ?? 18))
              .toDouble(),
      'pricingModel': session['pricing']?['model'] ?? 'per-session',
      'price': session['pricing']?['amount']?.toString() ?? '0',
    };
  }

  void _nextStep() {
    // Save current values to ensure form state is up to date
    _formKey.currentState?.save();

    // Validate only fields for the current step
    final currentFields = _getFieldsForStep(_currentStep);
    bool isValid = true;

    // Check validation only for the visible fields of this step
    for (final fieldName in currentFields) {
      final field = _formKey.currentState?.fields[fieldName];
      if (field != null) {
        if (!field.validate()) {
          isValid = false;
        }
      }
    }

    if (isValid) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _submitSession();
      }
    }
  }

  List<String> _getFieldsForStep(int step) {
    if (step == 0) {
      return [
        'sessionType',
        'title',
        'description',
        'location',
        'focusAreas',
        'skillLevel',
        'ageGroups',
      ];
    } else if (step == 1) {
      final sessionType =
          _formKey.currentState?.value['sessionType'] as String? ?? 'one-time';
      final isRecurring = sessionType == 'recurring';

      final fields = <String>['startTime', 'duration'];
      if (isRecurring) {
        fields.addAll(['startDate', 'endDate', 'daysOfWeek']);
      } else {
        fields.add('date');
      }
      return fields;
    } else {
      // Step 2
      return [
        'capacity',
        'pricingModel',
        'price',
        'autoAccept',
        'allowWaitlist',
        'cancellationPolicy',
      ];
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitSession() async {
    setState(() => _isLoading = true);
    try {
      final formData = _formKey.currentState!.value;

      // Safe data extraction with defaults
      final sessionType = formData['sessionType'] as String? ?? 'one-time';
      final isRecurring = sessionType == 'recurring';

      // Construct Time Slots
      List<Map<String, dynamic>> timeSlots = [];
      List<String> selectedDays = [];
      Map<String, dynamic>? recurringPattern;

      final duration = (formData['duration'] as num?)?.toInt() ?? 60;
      final startTime = formData['startTime'] as DateTime?;

      if (startTime == null) throw Exception("Start time is required");

      final startHour = startTime.hour;
      final startMinute = startTime.minute;

      if (isRecurring) {
        if (_selectedDates.isEmpty) {
          throw Exception(
            "At least one date must be selected for recurring sessions",
          );
        }

        // Add all selected dates to selectedDays list
        for (var date in _selectedDates) {
          selectedDays.add(DateFormat('yyyy-MM-dd').format(date));
        }

        // We do NOT set recurringPattern, triggering Backend 'Manual Day Selection' strategy

        // Add template time slot
        timeSlots.add({
          'startTime': {'hour': startHour, 'minute': startMinute},
          'durationMinutes': duration,
        });
      } else {
        // One-time
        final date = formData['date'] as DateTime?;
        if (date == null) {
          throw Exception("Date is required for one-time sessions");
        }

        selectedDays.add(DateFormat('yyyy-MM-dd').format(date));

        timeSlots.add({
          'startTime': {'hour': startHour, 'minute': startMinute},
          'durationMinutes': duration,
        });
      }

      debugPrint('Submitting Session Form Data: $formData');
      debugPrint('Selected Days: $selectedDays');
      debugPrint('Time Slots: $timeSlots');
      debugPrint('Recurring Pattern: $recurringPattern');

      await SessionService.createSession(
        title: formData['title'] as String,
        description: formData['description'] as String? ?? '',
        location: formData['location'] as String? ?? '',
        capacity: (formData['capacity'] as num).toInt(),
        timeSlots: timeSlots,
        selectedDays: selectedDays, // Only for one-time/legacy
        isRecurring: isRecurring,
        // Wizard Fields
        sessionType: sessionType,
        focusAreas: List<String>.from(formData['focusAreas'] ?? []),
        skillLevel: formData['skillLevel'] as String? ?? 'All Levels',
        ageGroups: List<String>.from(formData['ageGroups'] ?? []),
        recurringPattern: recurringPattern,
        pricing: {
          'model': formData['pricingModel'],
          'amount':
              double.tryParse(formData['price']?.toString() ?? '0') ?? 0.0,
          'currency': 'USD',
          'pricePerPerson': true,
        },
        enrollmentSettings: {
          'autoAccept': formData['autoAccept'] ?? true,
          'allowWaitlist': formData['allowWaitlist'] ?? false,
        },
        cancellationPolicy: formData['cancellationPolicy'] as String?,
        status: 'published',
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session created! Status: published, Date: ${selectedDays.isNotEmpty ? selectedDays.first : "N/A"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FormBuilder(
              key: _formKey,
              initialValue: _initialValues,
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep1BasicDetails(),
                  _buildStep2Schedule(),
                  _buildStep3Participants(),
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
                onPressed: () {
                  if (_currentStep > 0) {
                    _prevStep();
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  _currentStep == 0
                      ? 'Create Session'
                      : _currentStep == 1
                      ? 'Schedule'
                      : 'Participants & Pricing',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 40), // Balance back button approx
            ],
          ),
          const SizedBox(height: 24),
          // Progress Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isActive = index <= _currentStep;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 32 : 12,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1BasicDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Type'),
          FormBuilderField<String>(
            name: 'sessionType',
            initialValue: 'one-time',
            builder: (field) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: field.value,
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              field.value == 'one-time'
                                  ? 'One Time'
                                  : field.value == 'recurring'
                                  ? 'Recurring'
                                  : 'Camp',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade400,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) {
                        return ['one-time', 'recurring', 'camp'].map((
                          String value,
                        ) {
                          return PopupMenuItem<String>(
                            value: value,
                            child: Text(
                              value == 'one-time'
                                  ? 'One Time'
                                  : value == 'recurring'
                                  ? 'Recurring'
                                  : 'Camp',
                              style: GoogleFonts.inter(fontSize: 15),
                            ),
                          );
                        }).toList();
                      },
                      onSelected: (value) => field.didChange(value),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          ModernTextField(
            name: 'title',
            labelText: 'Session Title',
            hintText: 'e.g. Batting Masterclass',
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 20),

          ModernTextField(
            name: 'description',
            labelText: 'Description',
            hintText: 'What will students learn?',
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          _buildLabel('Location'),
          LayoutBuilder(
            builder: (context, constraints) {
              return Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  final predictions =
                      await LocationSearchDelegate.getPlacePredictions(
                        textEditingValue.text,
                      );
                  return predictions.cast<Map<String, dynamic>>();
                },
                displayStringForOption: (Map<String, dynamic> option) =>
                    option['description'] ?? '',
                onSelected: (Map<String, dynamic> selection) {
                  final description = selection['description'] as String;
                  _formKey.currentState?.fields['location']?.didChange(
                    description,
                  );
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      if (textEditingController.text.isEmpty) {
                        final initialLocation =
                            _initialValues['location'] as String?;
                        if (initialLocation != null &&
                            initialLocation.isNotEmpty) {
                          textEditingController.text = initialLocation;
                        }
                      }
                      return FormBuilderTextField(
                        name: 'location',
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search location',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.map, color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.push<LatLng>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LocationPickerScreen(),
                                ),
                              );

                              if (result != null) {
                                // Update the text field with coordinates
                                final locString =
                                    '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
                                textEditingController.text = locString;
                                _formKey.currentState?.fields['location']
                                    ?.didChange(locString);
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: FormBuilderValidators.required(),
                        onSubmitted: (_) => onFieldSubmitted(),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8.0,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: constraints.maxWidth,
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                title: Text(
                                  option['description'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          _buildLabel('Focus Areas'),
          FormBuilderField<List<String>>(
            name: 'focusAreas',
            initialValue: const [],
            builder: (field) {
              final val = field.value ?? [];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Batting',
                      'Bowling',
                      'Fielding',
                      'Fitness',
                      'Mental Game',
                      'Strategy',
                    ].map((option) {
                      final isSelected = val.contains(option);
                      return FilterChip(
                        label: Text(
                          option,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onSecondary
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newVal = List<String>.from(val);
                          if (selected) {
                            newVal.add(option);
                          } else {
                            newVal.remove(option);
                          }
                          field.didChange(newVal);
                        },
                        selectedColor: Theme.of(context).colorScheme.secondary,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      );
                    }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          _buildLabel('Skill Level'),
          FormBuilderField<String>(
            name: 'skillLevel',
            initialValue: 'All Levels',
            builder: (field) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: field.value,
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              field.value ?? 'All Levels',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade400,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) {
                        return [
                          'Beginner',
                          'Intermediate',
                          'Advanced',
                          'All Levels',
                        ].map((String value) {
                          return PopupMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.inter(fontSize: 15),
                            ),
                          );
                        }).toList();
                      },
                      onSelected: (val) => field.didChange(val),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          _buildLabel('Age Groups'),
          FormBuilderField<List<String>>(
            name: 'ageGroups',
            initialValue: const [],
            builder: (field) {
              final val = field.value ?? [];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Under 11',
                      'Under 13',
                      'Under 15',
                      'Under 19',
                      'Open',
                    ].map((option) {
                      final isSelected = val.contains(option);
                      return FilterChip(
                        label: Text(
                          option,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onSecondary
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newVal = List<String>.from(val);
                          if (selected) {
                            newVal.add(option);
                          } else {
                            newVal.remove(option);
                          }
                          field.didChange(newVal);
                        },
                        selectedColor: Theme.of(context).colorScheme.secondary,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      );
                    }).toList(),
              );
            },
          ),
          const SizedBox(height: 30),
          _buildNavigationButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep2Schedule() {
    return FormBuilderField<String>(
      name: 'sessionType_listener',
      builder: (FormFieldState<String> field) {
        // We listen to the form state to update the UI dynamically
        final sessionType =
            _formKey.currentState?.fields['sessionType']?.value as String? ??
            'one-time';
        final isRecurring = sessionType == 'recurring';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                isRecurring ? 'Recurring Schedule' : 'Session Schedule',
              ),
              const SizedBox(height: 16),

              if (isRecurring) ...[
                _buildLabel('Select Specific Dates (${_selectedDates.length})'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return _selectedDates.any((d) => isSameDay(d, day));
                    },
                    calendarFormat: CalendarFormat.month,
                    rangeSelectionMode: RangeSelectionMode.toggledOff,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                        // Toggle selection
                        if (_selectedDates.any(
                          (d) => isSameDay(d, selectedDay),
                        )) {
                          _selectedDates.removeWhere(
                            (d) => isSameDay(d, selectedDay),
                          );
                        } else {
                          _selectedDates.add(selectedDay);
                        }
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Display selected dates summary
                if (_selectedDates.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Dates:',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedDates.map((date) {
                            return Chip(
                              label: Text(
                                DateFormat('MMM d').format(date),
                                style: const TextStyle(fontSize: 12),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() {
                                  _selectedDates.remove(date);
                                });
                              },
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                _buildLabel('Date'),
                FormBuilderDateTimePicker(
                  name: 'date',
                  inputType: InputType.date,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: FormBuilderValidators.required(),
                  initialDate: DateTime.now(),
                  format: DateFormat('EEE, MMM d, yyyy'),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Start Time'),
                        FormBuilderField<DateTime>(
                          name: 'startTime',
                          validator: FormBuilderValidators.required(),
                          initialValue: DateTime(2024, 1, 1, 9, 0),
                          builder: (FormFieldState<DateTime> field) {
                            return GestureDetector(
                              onTap: () {
                                showCupertinoModalPopup<void>(
                                  context: context,
                                  builder: (BuildContext context) => Container(
                                    height: 216,
                                    padding: const EdgeInsets.only(top: 6.0),
                                    margin: EdgeInsets.only(
                                      bottom: MediaQuery.of(
                                        context,
                                      ).viewInsets.bottom,
                                    ),
                                    color: CupertinoColors.systemBackground
                                        .resolveFrom(context),
                                    child: SafeArea(
                                      top: false,
                                      child: CupertinoDatePicker(
                                        initialDateTime:
                                            field.value ??
                                            DateTime(2024, 1, 1, 9, 0),
                                        mode: CupertinoDatePickerMode.time,
                                        use24hFormat: false,
                                        onDateTimeChanged: (DateTime newTime) {
                                          field.didChange(newTime);
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      field.value != null
                                          ? DateFormat(
                                              'h:mm a',
                                            ).format(field.value!)
                                          : 'Select Time',
                                      style: GoogleFonts.inter(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLabel('Duration (min)'),
              FormBuilderField<int>(
                name: 'duration',
                initialValue: 60,
                builder: (field) {
                  return ModernDurationSelector<int>(
                    selectedValue: field.value,
                    options: const [30, 45, 60, 90, 120],
                    labelBuilder: (val) => '$val min',
                    onSelected: (val) => field.didChange(val),
                  );
                },
              ),
              const SizedBox(height: 30),
              _buildNavigationButtons(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep3Participants() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Capacity & Pricing'),
          const SizedBox(height: 16),

          _buildLabel('Max Capacity'),
          Row(
            children: [
              Expanded(
                child: FormBuilderField<double>(
                  name: 'capacity',
                  initialValue: 18.0,
                  builder: (field) {
                    final val = field.value?.toInt() ?? 18;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            if (val > 1) field.didChange(val - 1.0);
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            '$val Players',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            if (val < 50) field.didChange(val + 1.0);
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildLabel('Pricing Model'),
          FormBuilderField<String>(
            name: 'pricingModel',
            initialValue: 'per-session',
            builder: (field) {
              return ModernDurationSelector<String>(
                selectedValue: field.value,
                options: const ['per-session', 'full-series'],
                labelBuilder: (val) =>
                    val == 'per-session' ? 'Per Session' : 'Full Series',
                onSelected: (val) => field.didChange(val),
              );
            },
          ),

          const SizedBox(height: 16),
          ModernTextField(
            name: 'price',
            labelText: 'Amount (USD)',
            hintText: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: FormBuilderValidators.numeric(),
            prefixIcon: Icons.attach_money,
          ),

          const SizedBox(height: 30),
          _buildSectionTitle('Enrollment Settings'),
          FormBuilderSwitch(
            name: 'autoAccept',
            title: const Text('Auto-accept Bookings'),
            subtitle: const Text(
              'Students are confirmed immediately upon booking.',
            ),
            initialValue: true,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
          FormBuilderSwitch(
            name: 'allowWaitlist',
            title: const Text('Allow Waitlist'),
            subtitle: const Text('Students can join waitlist if full.'),
            initialValue: false,
            decoration: const InputDecoration(border: InputBorder.none),
          ),

          const SizedBox(height: 20),
          const SizedBox(height: 20),
          _buildLabel('Cancellation Policy'),
          FormBuilderField<String>(
            name: 'cancellationPolicy',
            initialValue: 'flexible',
            builder: (field) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: field.value,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'flexible',
                        child: Text('Flexible (24h refund)'),
                      ),
                      DropdownMenuItem(
                        value: 'moderate',
                        child: Text('Moderate (48h refund)'),
                      ),
                      DropdownMenuItem(
                        value: 'strict',
                        child: Text('Strict (No refund)'),
                      ),
                    ],
                    onChanged: (val) => field.didChange(val),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          _buildNavigationButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B00),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _currentStep == 2 ? 'Create Session' : 'Next Step',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
