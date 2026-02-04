import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../services/guardian_service.dart';

class EditPlayerScreen extends StatefulWidget {
  final Map<String, dynamic>? playerData;

  const EditPlayerScreen({super.key, this.playerData});

  @override
  State<EditPlayerScreen> createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends State<EditPlayerScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _medicalIssuesController;
  late TextEditingController _ageController;

  late String _selectedRole;
  late String _selectedBattingStyle;
  late String _selectedBowlingStyle;

  final List<String> _roles = [
    'Batsman',
    'Bowler',
    'All-Rounder',
    'Wicket-Keeper',
  ];
  final List<String> _battingStyles = ['Right-hand bat', 'Left-hand bat'];
  final List<String> _bowlingStyles = [
    'Right-arm fast',
    'Left-arm fast',
    'Right-arm spin',
    'Left-arm spin',
    'N/A',
  ];

  String _playerName = '';
  String _playerId = '';

  @override
  void initState() {
    super.initState();
    _initializeWithData();
  }

  void _initializeWithData() {
    final data = widget.playerData;

    // Extract name parts
    final fullName = data?['fullName'] ?? 'Player';

    _playerName = fullName;
    _playerId = data?['_id'] ?? '';

    _firstNameController = TextEditingController(text: fullName);
    _medicalIssuesController = TextEditingController(
      text: data?['medicalIssues'] ?? '',
    );
    _ageController = TextEditingController(text: data?['age'] ?? '10');

    // Cricket-specific fields
    _selectedRole = data?['role'] ?? 'Batsman';
    _selectedBattingStyle = data?['battingStyle'] ?? 'Right-hand bat';
    _selectedBowlingStyle = data?['bowlingStyle'] ?? 'N/A';
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remove Player',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove this player? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _removePlayer();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Remove',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removePlayer() async {
    try {
      // Call API to remove player
      await GuardianService().removePlayer(_playerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player removed successfully!')),
        );
        context.pop(true); // Return true to refresh player list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove player: $e')));
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      // Validate inputs
      if (_firstNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
        return;
      }

      if (_ageController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter an age')));
        return;
      }

      // Call API to update player
      await GuardianService().updatePlayer(
        _playerId,
        fullName: _firstNameController.text.trim(),
        age: _ageController.text.trim(),
        role: _selectedRole,
        battingStyle: _selectedBattingStyle,
        bowlingStyle: _selectedBowlingStyle,
        medicalIssues: _medicalIssuesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player updated successfully!')),
        );
        context.pop(true); // Return true to refresh player list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: Text(
          'Edit Player',
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
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage(
                            'assets/images/user_placeholder_soccer.png',
                          ), // Mock
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _playerName,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: #${_playerId.substring(0, 6)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField("Full Name", _firstNameController),
            const SizedBox(height: 16),

            _buildTextField("Age", _ageController, isCenter: false),
            const SizedBox(height: 16),

            // Role Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Role"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRole,
                      items: _roles
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedRole = val ?? _selectedRole),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Batting Style Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Batting Style"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedBattingStyle,
                      items: _battingStyles
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) => setState(
                        () => _selectedBattingStyle =
                            val ?? _selectedBattingStyle,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bowling Style Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Bowling Style"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedBowlingStyle,
                      items: _bowlingStyles
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) => setState(
                        () => _selectedBowlingStyle =
                            val ?? _selectedBowlingStyle,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField(
              "Medical Issues/Conditions (Optional)",
              _medicalIssuesController,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F00), // Darker orange
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
              ),
            ),
            const SizedBox(height: 24),

            TextButton.icon(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              label: Text(
                'Remove Player Profile',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 40), // To clear bottom nav if needed
          ],
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
    bool isCenter = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textAlign: isCenter ? TextAlign.center : TextAlign.start,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: icon != null ? Icon(icon, color: Colors.orange) : null,
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
}
