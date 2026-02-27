import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../services/guardian_service.dart';
import '../../services/storage_service.dart';
import 'dart:io';

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
  File? _pickedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

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
    _playerId = data?['_id'] ?? data?['id'] ?? '';
    _existingImageUrl =
        data?['profileUrl'] ?? data?['profilePhoto'] ?? data?['profileImage'];

    _firstNameController = TextEditingController(text: fullName);
    _medicalIssuesController = TextEditingController(
      text: data?['medicalIssues'] ?? '',
    );
    _ageController = TextEditingController(text: data?['age'] ?? '10');

    // Cricket-specific fields — fall back to first item if stored value not in list
    final rawRole = data?['role'] ?? '';
    _selectedRole = _roles.contains(rawRole) ? rawRole : _roles.first;

    final rawBattingStyle = data?['battingStyle'] ?? '';
    _selectedBattingStyle = _battingStyles.contains(rawBattingStyle)
        ? rawBattingStyle
        : _battingStyles.first;

    final rawBowlingStyle = data?['bowlingStyle'] ?? '';
    _selectedBowlingStyle = _bowlingStyles.contains(rawBowlingStyle)
        ? rawBowlingStyle
        : _bowlingStyles.first;
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remove Player',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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

      setState(() => _isLoading = true);

      // Upload image if selected
      String? finalImageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        finalImageUrl = await StorageService.uploadProfilePicture(
          userId: _playerId,
          imageFile: _pickedImage!,
        );
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
        profilePhoto: finalImageUrl,
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await StorageService.showImageSourceSheet(context);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surface;
    final onSurface = cs.onSurface;
    final divider = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Player',
          style: GoogleFonts.inter(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: onSurface,
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: divider, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: cs.surfaceContainerHighest,
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : (_existingImageUrl != null &&
                                        _existingImageUrl!.isNotEmpty
                                    ? NetworkImage(_existingImageUrl!)
                                        as ImageProvider
                                    : null),
                            child: (_pickedImage == null &&
                                    (_existingImageUrl == null ||
                                        _existingImageUrl!.isEmpty))
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: onSurface.withValues(alpha: 0.3),
                                  )
                                : null,
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
                              border: Border.all(color: surface, width: 2),
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
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _playerName,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: #${_playerId.substring(0, 6)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: onSurface.withValues(alpha: 0.5),
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
                _buildDropdown(
                  value: _selectedRole,
                  items: _roles,
                  onChanged: (val) =>
                      setState(() => _selectedRole = val ?? _selectedRole),
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
                _buildDropdown(
                  value: _selectedBattingStyle,
                  items: _battingStyles,
                  onChanged: (val) => setState(() =>
                      _selectedBattingStyle = val ?? _selectedBattingStyle),
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
                _buildDropdown(
                  value: _selectedBowlingStyle,
                  items: _bowlingStyles,
                  onChanged: (val) => setState(() =>
                      _selectedBowlingStyle = val ?? _selectedBowlingStyle),
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
                onPressed: _isLoading ? null : _saveChanges,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F00), // Darker orange
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.inter(
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      isExpanded: true,
      // Forces menu to always open BELOW the field
      menuMaxHeight: 240,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.orangeAccent),
        ),
      ),
      icon:
          const Icon(Icons.keyboard_arrow_down, color: AppPalette.orangeAccent),
      dropdownColor: Theme.of(context).colorScheme.surface,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
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
            fillColor: Theme.of(context).colorScheme.surface,
            suffixIcon: icon != null ? Icon(icon, color: Colors.orange) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
          style:
              GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }
}
