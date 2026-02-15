import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/coach_service.dart';

class OneOnOneSettingsTab extends StatefulWidget {
  const OneOnOneSettingsTab({super.key});

  @override
  State<OneOnOneSettingsTab> createState() => _OneOnOneSettingsTabState();
}

class _OneOnOneSettingsTabState extends State<OneOnOneSettingsTab> {
  bool _isLoading = true;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _hourlyRateController = TextEditingController();
  final _sessionDurationController = TextEditingController(); // minutes
  final _bufferTimeController = TextEditingController(); // minutes
  final _minAdvanceController = TextEditingController(); // hours
  final _maxAdvanceController = TextEditingController(); // days

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
    _sessionDurationController.dispose();
    _bufferTimeController.dispose();
    _minAdvanceController.dispose();
    _maxAdvanceController.dispose();
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
        _sessionDurationController.text =
            (defaultPricing['sessionDuration'] ?? 60).toString();
        _currency = defaultPricing['currency'] ?? 'USD';

        _bufferTimeController.text = (bookingSettings['bufferTime'] ?? 15)
            .toString();
        _minAdvanceController.text =
            (bookingSettings['minAdvanceBookingHours'] ?? 24).toString();
        _maxAdvanceController.text =
            (bookingSettings['maxAdvanceBookingDays'] ?? 30).toString();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final settingsData = {
        'defaultPricing': {
          'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0,
          'sessionDuration':
              int.tryParse(_sessionDurationController.text) ?? 60,
          'currency': _currency,
        },
        'bookingSettings': {
          'bufferTime': int.tryParse(_bufferTimeController.text) ?? 15,
          'minAdvanceBookingHours':
              int.tryParse(_minAdvanceController.text) ?? 24,
          'maxAdvanceBookingDays':
              int.tryParse(_maxAdvanceController.text) ?? 30,
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Pricing & Duration'),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _hourlyRateController,
                        label: 'Hourly Rate',
                        hint: '0',
                        prefix: '\$',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _sessionDurationController,
                        label: 'Session Duration',
                        hint: '60',
                        suffix: 'min',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Booking Rules'),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                _buildTextField(
                  controller: _bufferTimeController,
                  label: 'Buffer Time Between Sessions',
                  hint: '15',
                  suffix: 'min',
                  keyboardType: TextInputType.number,
                  helperText: 'Time needed to reset between sessions',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _minAdvanceController,
                        label: 'Min Advance Booking',
                        hint: '24',
                        suffix: 'hours',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _maxAdvanceController,
                        label: 'Max Advance Booking',
                        hint: '30',
                        suffix: 'days',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(_cancellationPolicy),
                  initialValue: _cancellationPolicy,
                  decoration: InputDecoration(
                    labelText: 'Cancellation Policy',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
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
                    if (val != null) setState(() => _cancellationPolicy = val);
                  },
                ),
                const SizedBox(height: 16),
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
                        style: GoogleFonts.outfit(
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
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    String? suffix,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixText: prefix,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }
}
