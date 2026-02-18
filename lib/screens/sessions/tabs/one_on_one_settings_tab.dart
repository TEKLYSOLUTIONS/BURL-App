import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../services/coach_service.dart';
import '../../../widgets/modern_text_field.dart';
import '../../../widgets/modern_duration_selector.dart';

class OneOnOneSettingsTab extends StatefulWidget {
  const OneOnOneSettingsTab({super.key});

  @override
  State<OneOnOneSettingsTab> createState() => _OneOnOneSettingsTabState();
}

class _OneOnOneSettingsTabState extends State<OneOnOneSettingsTab> {
  bool _isLoading = true;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormBuilderState>();

  // Form Controllers & State
  final _hourlyRateController = TextEditingController();
  int _sessionDuration = 60; // minutes
  int _bufferTime = 15; // minutes
  int _minAdvance = 24; // hours
  int _maxAdvance = 30; // days

  String _cancellationPolicy = 'flexible';
  bool _autoAccept = true;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await CoachService.getSessionSettings();
      final defaultPricing = data['defaultPricing'] ?? {};
      final bookingSettings = data['bookingSettings'] ?? {};

      setState(() {
        _hourlyRateController.text = (defaultPricing['hourlyRate'] ?? 0)
            .toString();
        _sessionDuration = (defaultPricing['sessionDuration'] ?? 60).toInt();
        _currency = defaultPricing['currency'] ?? 'USD';

        _bufferTime = (bookingSettings['bufferTime'] ?? 15).toInt();
        _minAdvance = (bookingSettings['minAdvanceBookingHours'] ?? 24).toInt();
        _maxAdvance = (bookingSettings['maxAdvanceBookingDays'] ?? 30).toInt();
        _cancellationPolicy =
            bookingSettings['cancellationPolicy'] ?? 'flexible';
        _autoAccept = bookingSettings['autoAccept'] ?? true;

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;

    setState(() => _isSaving = true);
    try {
      final settingsData = {
        'defaultPricing': {
          'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0,
          'sessionDuration': _sessionDuration,
          'currency': _currency,
        },
        'bookingSettings': {
          'bufferTime': _bufferTime,
          'minAdvanceBookingHours': _minAdvance,
          'maxAdvanceBookingDays': _maxAdvance,
          'cancellationPolicy': _cancellationPolicy,
          'autoAccept': _autoAccept,
        },
      };

      await CoachService.updateSessionSettings(settingsData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Pricing & Duration'),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 1,
                        child: ModernTextField(
                          name: 'hourlyRate',
                          controller: _hourlyRateController,
                          labelText: 'Rate',
                          hintText: '0',
                          prefixIcon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: FormBuilderValidators.required(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Duration',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: PopupMenuButton<int>(
                                  initialValue: _sessionDuration,
                                  offset: const Offset(0, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color: Colors.white,
                                  elevation: 4,
                                  constraints: const BoxConstraints(
                                    minWidth: 150,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$_sessionDuration min',
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
                                    return [30, 45, 60, 90, 120].map((
                                      int value,
                                    ) {
                                      return PopupMenuItem<int>(
                                        value: value,
                                        child: Text(
                                          '$value min',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  onSelected: (val) {
                                    setState(() => _sessionDuration = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Booking Rules'),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                _buildLabel('Buffer Time Between Sessions'),
                ModernDurationSelector<int>(
                  selectedValue: _bufferTime,
                  options: const [0, 15, 30, 45, 60],
                  labelBuilder: (val) => '$val min',
                  onSelected: (val) => setState(() => _bufferTime = val),
                ),
                const SizedBox(height: 24),

                _buildLabel('Min Advance Booking'),
                ModernDurationSelector<int>(
                  selectedValue: _minAdvance,
                  options: const [6, 12, 24, 48],
                  labelBuilder: (val) => '$val hours',
                  onSelected: (val) => setState(() => _minAdvance = val),
                ),
                const SizedBox(height: 24),

                _buildLabel('Max Advance Booking'),
                ModernDurationSelector<int>(
                  selectedValue: _maxAdvance,
                  options: const [7, 14, 30, 60, 90],
                  labelBuilder: (val) => '$val days',
                  onSelected: (val) => setState(() => _maxAdvance = val),
                ),
                const SizedBox(height: 24),

                _buildLabel('Cancellation Policy'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _cancellationPolicy,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'flexible',
                          child: Text('Flexible (24h prior)'),
                        ),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text('Moderate (48h prior)'),
                        ),
                        DropdownMenuItem(
                          value: 'strict',
                          child: Text('Strict (No refund)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _cancellationPolicy = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SwitchListTile(
                  title: Text(
                    'Auto-Accept Bookings',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Automatically confirm booking requests if time is available',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  value: _autoAccept,
                  onChanged: (val) => setState(() => _autoAccept = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
