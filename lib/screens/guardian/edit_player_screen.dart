import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';

class EditPlayerScreen extends StatefulWidget {
  const EditPlayerScreen({super.key});

  @override
  State<EditPlayerScreen> createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends State<EditPlayerScreen> {
  // Pre-filled with mock data
  final TextEditingController _nameController = TextEditingController(
    text: "Rahul Jr.",
  );
  final TextEditingController _ageController = TextEditingController(
    text: "12",
  );

  String _selectedRole = 'Boys U14'; // Adjusted mock roles
  String _selectedBattingStyle = 'Right Hand';
  String _selectedBowlingStyle = 'Right Arm - Spin';

  final List<String> _roles = [
    'Boys U12',
    'Boys U14',
    'Boys U16',
    'Girls U12',
    'Girls U14',
  ];
  final List<String> _battingStyles = ['Right Hand', 'Left Hand'];
  final List<String> _bowlingStyles = [
    'Right Arm - Fast',
    'Right Arm - Spin',
    'Left Arm - Fast',
    'Left Arm - Spin',
    'None',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Player',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar Edit
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=8',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppPalette.orangeAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildTextField("Full Name", _nameController),
            const SizedBox(height: 16),
            _buildTextField("Age", _ageController, isNumber: true),
            const SizedBox(height: 16),
            _buildDropdown(
              "Age Group / Role",
              _selectedRole,
              _roles,
              (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              "Batting Style",
              _selectedBattingStyle,
              _battingStyles,
              (val) => setState(() => _selectedBattingStyle = val!),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              "Bowling Style",
              _selectedBowlingStyle,
              _bowlingStyles,
              (val) => setState(() => _selectedBowlingStyle = val!),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Player Updated Successfully!'),
                    ),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 80), // To clear bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppPalette.navyPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppPalette.navyPrimary,
                width: 1.5,
              ),
            ),
          ),
          style: GoogleFonts.inter(color: AppPalette.textPrimaryLight),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppPalette.navyPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppPalette.navyPrimary,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      color: AppPalette.textPrimaryLight,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
