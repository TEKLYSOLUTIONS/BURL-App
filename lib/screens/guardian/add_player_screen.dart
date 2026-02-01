import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../services/guardian_service.dart';

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guardianService = GuardianService();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController =
      TextEditingController(); // Replaced DOB with Age for consistency with service/backend
  final TextEditingController _jerseyController = TextEditingController();
  final TextEditingController _teamController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();

  // State
  bool _isLoading = false;
  String _selectedRole = 'Batsman';
  String _selectedBattingStyle = 'Right-hand bat';
  String _selectedBowlingStyle = 'Right-arm fast';

  // Dropdown Options
  final List<String> _roles = [
    'Batsman',
    'Bowler',
    'All-Rounder',
    'Wicket Keeper',
  ];
  final List<String> _battingStyles = ['Right-hand bat', 'Left-hand bat'];
  final List<String> _bowlingStyles = [
    'Right-arm fast',
    'Right-arm medium',
    'Right-arm spin',
    'Left-arm fast',
    'Left-arm medium',
    'Left-arm spin',
    'None',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _jerseyController.dispose();
    _teamController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter Age')));
      return;
    }

    // Backend restriction check
    if (int.tryParse(_ageController.text) != null &&
        int.parse(_ageController.text) >= 16) {
      _showTeenagerDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _guardianService.addPlayer(
        fullName: _nameController.text.trim(),
        age: _ageController.text.trim(),
        role: _selectedRole,
        battingStyle: _selectedBattingStyle,
        bowlingStyle: _selectedBowlingStyle,
        jerseyNumber: _jerseyController.text.trim(),
        teamName: _teamController.text.trim(),
      );

      // Notify other screens (like Home) to refresh their data
      GuardianService.playerUpdateNotifier.value =
          !GuardianService.playerUpdateNotifier.value;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player Added Successfully!'),
          backgroundColor: AppPalette.successGreen,
        ),
      );
      context.go('/guardian/home'); // Navigate to home instead of popping
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTeenagerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Age Restriction"),
        content: const Text(
          "Players aged 16 and above must create their own account to manage their profile and stats.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Add New Athlete',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitData,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.outfit(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar (Placeholder)
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[200]!, width: 2),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey[300],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Full Name
              _buildTextField(
                "Full Name",
                _nameController,
                hint: "e.g. John Doe",
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              // Age (Number input for now to match backend simple age field)
              _buildTextField(
                "Age",
                _ageController,
                hint: "e.g. 12",
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter age' : null,
              ),
              const SizedBox(height: 24),

              // Role Dropdown
              _buildLabel("Role"),
              const SizedBox(height: 8),
              _buildDropdown(_roles, _selectedRole, (val) {
                if (val != null) setState(() => _selectedRole = val);
              }),
              const SizedBox(height: 24),

              // Batting Style
              _buildLabel("Batting Style"),
              const SizedBox(height: 8),
              _buildDropdown(_battingStyles, _selectedBattingStyle, (val) {
                if (val != null) setState(() => _selectedBattingStyle = val);
              }),
              const SizedBox(height: 24),

              // Bowling Style
              _buildLabel("Bowling Style"),
              const SizedBox(height: 8),
              _buildDropdown(_bowlingStyles, _selectedBowlingStyle, (val) {
                if (val != null) setState(() => _selectedBowlingStyle = val);
              }),
              const SizedBox(height: 32),

              const Divider(),
              const SizedBox(height: 16),

              // Medical (Optional)
              _buildLabel("Medical Notes (Optional)"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _medicalController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Allergies, conditions...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitData,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(_isLoading ? "Adding..." : "Add Player"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: AppPalette.navyPrimary,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool isCenter = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textAlign: isCenter ? TextAlign.center : TextAlign.start,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.inter(color: AppPalette.textPrimaryLight),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String currentValue,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: currentValue,
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.orange),
        ),
      ),
    );
  }
}
