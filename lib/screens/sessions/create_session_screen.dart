import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../services/session_service.dart';
import '../../utils/location_search_delegate.dart';
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
        final days = formData['daysOfWeek'] as List<dynamic>? ?? [];
        final startDate = formData['startDate'] as DateTime?;
        final endDate = formData['endDate'] as DateTime?;

        if (startDate == null || endDate == null || days.isEmpty) {
          throw Exception(
            "Recurring sessions require start date, end date and at least one day selected",
          );
        }

        recurringPattern = {
          'frequency': 'weekly',
          'daysOfWeek': days.map((d) => d.toString().toLowerCase()).toList(),
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        };

        // For recurring, we send a template timeSlot
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
                  style: GoogleFonts.outfit(
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
          _buildSectionTitle('Type'),
          FormBuilderRadioGroup<String>(
            name: 'sessionType',
            decoration: const InputDecoration(border: InputBorder.none),
            options: const [
              FormBuilderFieldOption(
                value: 'one-time',
                child: Text('One Time'),
              ),
              FormBuilderFieldOption(
                value: 'recurring',
                child: Text('Recurring (Series)'),
              ),
              FormBuilderFieldOption(
                value: 'camp',
                child: Text('Camp / Workshop'),
              ),
            ],
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 20),

          _buildLabel('Session Title'),
          FormBuilderTextField(
            name: 'title',
            decoration: _inputDecoration('e.g. Batting Masterclass'),
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 20),

          _buildLabel('Description'),
          FormBuilderTextField(
            name: 'description',
            decoration: _inputDecoration('What will students learn?'),
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
                      // Sync initial value if any
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
                        decoration: _inputDecoration(
                          'Search location',
                          icon: Icons.location_on,
                        ),
                        validator: FormBuilderValidators.required(),
                        onChanged: (val) {
                          // Optional: clear validation errors or handle manual typing
                        },
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners for dropdown
                      child: Container(
                        width: constraints.maxWidth,
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            final description = option['description'] as String;
                            final structuredFormatting =
                                option['structured_formatting'] ?? {};
                            final mainText =
                                structuredFormatting['main_text'] ??
                                description;
                            final secondaryText =
                                structuredFormatting['secondary_text'] ?? '';

                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.grey,
                              ),
                              title: Text(
                                mainText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: secondaryText.isNotEmpty
                                  ? Text(
                                      secondaryText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),

          _buildLabel('Focus Areas'),
          FormBuilderCheckboxGroup<String>(
            name: 'focusAreas',
            decoration: const InputDecoration(border: InputBorder.none),
            orientation: OptionsOrientation.wrap,
            options: const [
              FormBuilderFieldOption(value: 'Batting'),
              FormBuilderFieldOption(value: 'Bowling'),
              FormBuilderFieldOption(value: 'Fielding'),
              FormBuilderFieldOption(value: 'Fitness'),
              FormBuilderFieldOption(value: 'Mental Game'),
              FormBuilderFieldOption(value: 'Strategy'),
            ],
          ),
          const SizedBox(height: 20),

          _buildLabel('Skill Level'),
          FormBuilderDropdown<String>(
            name: 'skillLevel',
            decoration: _inputDecoration('Select Level'),
            items: const [
              DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
              DropdownMenuItem(
                value: 'Intermediate',
                child: Text('Intermediate'),
              ),
              DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
              DropdownMenuItem(value: 'All Levels', child: Text('All Levels')),
            ],
          ),
          const SizedBox(height: 20),

          _buildLabel('Age Groups'),
          FormBuilderCheckboxGroup<String>(
            name: 'ageGroups',
            decoration: const InputDecoration(border: InputBorder.none),
            orientation: OptionsOrientation.wrap,
            options: const [
              FormBuilderFieldOption(value: 'Under 11'),
              FormBuilderFieldOption(value: 'Under 13'),
              FormBuilderFieldOption(value: 'Under 15'),
              FormBuilderFieldOption(value: 'Under 19'),
              FormBuilderFieldOption(value: 'Open'),
            ],
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
                _buildLabel('Date Range'),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderDateTimePicker(
                        name: 'startDate',
                        inputType: InputType.date,
                        decoration: _inputDecoration(
                          'Start Date',
                          icon: Icons.calendar_today,
                        ),
                        validator: FormBuilderValidators.required(),
                        initialDate: DateTime.now(),
                        format: DateFormat('yyyy-MM-dd'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormBuilderDateTimePicker(
                        name: 'endDate',
                        inputType: InputType.date,
                        decoration: _inputDecoration(
                          'End Date',
                          icon: Icons.event,
                        ),
                        validator: FormBuilderValidators.required(),
                        initialDate: DateTime.now().add(
                          const Duration(days: 30),
                        ),
                        format: DateFormat('yyyy-MM-dd'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLabel('Repeats On'),
                FormBuilderCheckboxGroup<String>(
                  name: 'daysOfWeek',
                  decoration: const InputDecoration(border: InputBorder.none),
                  orientation: OptionsOrientation.wrap,
                  options: const [
                    FormBuilderFieldOption(value: 'Monday', child: Text('Mon')),
                    FormBuilderFieldOption(
                      value: 'Tuesday',
                      child: Text('Tue'),
                    ),
                    FormBuilderFieldOption(
                      value: 'Wednesday',
                      child: Text('Wed'),
                    ),
                    FormBuilderFieldOption(
                      value: 'Thursday',
                      child: Text('Thu'),
                    ),
                    FormBuilderFieldOption(value: 'Friday', child: Text('Fri')),
                    FormBuilderFieldOption(
                      value: 'Saturday',
                      child: Text('Sat'),
                    ),
                    FormBuilderFieldOption(value: 'Sunday', child: Text('Sun')),
                  ],
                  validator: FormBuilderValidators.required(),
                ),
              ] else ...[
                _buildLabel('Date'),
                FormBuilderDateTimePicker(
                  name: 'date',
                  inputType: InputType.date,
                  decoration: _inputDecoration(
                    'Select Date',
                    icon: Icons.calendar_today,
                  ),
                  validator: FormBuilderValidators.required(),
                  initialDate: DateTime.now(),
                  format: DateFormat('EEE, MMM d, yyyy'),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Start Time'),
                        FormBuilderField<DateTime>(
                          name: 'startTime',
                          validator: FormBuilderValidators.required(),
                          initialValue: DateTime(
                            2024,
                            1,
                            1,
                            9,
                            0,
                          ), // Default 9 AM
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
                              child: InputDecorator(
                                decoration: _inputDecoration(
                                  'Select Time',
                                  icon: Icons.access_time,
                                ).copyWith(errorText: field.errorText),
                                child: Text(
                                  field.value != null
                                      ? DateFormat(
                                          'h:mm a',
                                        ).format(field.value!)
                                      : 'Select Time',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Duration (min)'),
                        FormBuilderDropdown<int>(
                          name: 'duration',
                          decoration: _inputDecoration('60 min'),
                          initialValue: 60,
                          items: [30, 45, 60, 90, 120, 180]
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text('$t min'),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
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
          FormBuilderSlider(
            name: 'capacity',
            min: 1,
            max: 50,
            divisions: 49,
            initialValue: 18,
            decoration: const InputDecoration(border: InputBorder.none),
          ),

          const SizedBox(height: 20),
          _buildLabel('Pricing Model'),
          FormBuilderRadioGroup<String>(
            name: 'pricingModel',
            decoration: const InputDecoration(border: InputBorder.none),
            options: const [
              FormBuilderFieldOption(
                value: 'per-session',
                child: Text('Per Session'),
              ),
              FormBuilderFieldOption(
                value: 'full-series',
                child: Text('Full Series Price'),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _buildLabel('Amount (USD)'),
          FormBuilderTextField(
            name: 'price',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration('0.00', icon: Icons.attach_money),
            validator: FormBuilderValidators.numeric(),
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
          _buildLabel('Cancellation Policy'),
          FormBuilderDropdown<String>(
            name: 'cancellationPolicy',
            decoration: _inputDecoration('Select Policy'),
            initialValue: 'flexible',
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
          ),
          const SizedBox(height: 30),
          _buildNavigationButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
          )
        else
          Expanded(child: Container()), // Spacer

        const SizedBox(width: 16),

        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
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
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
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

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: Colors.grey)
          : null,
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
