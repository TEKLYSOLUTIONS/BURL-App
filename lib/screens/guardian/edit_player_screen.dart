import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import 'package:intl/intl.dart';

class EditPlayerScreen extends StatefulWidget {
  final Map<String, dynamic>? playerData;

  const EditPlayerScreen({super.key, this.playerData});

  @override
  State<EditPlayerScreen> createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends State<EditPlayerScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _jerseyController;
  late TextEditingController _teamController;

  late DateTime _selectedDate;
  late String _selectedSport;
  final List<String> _sports = ['Soccer', 'Cricket', 'Basketball', 'Tennis'];

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
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    _playerName = fullName;
    _playerId = data?['_id'] ?? '';

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _jerseyController = TextEditingController(text: '');
    _teamController = TextEditingController(text: '');

    // Parse age to approximate birth date
    final ageString = data?['age'];
    if (ageString != null) {
      final age = int.tryParse(ageString.toString()) ?? 10;
      _selectedDate = DateTime.now().subtract(Duration(days: age * 365));
    } else {
      _selectedDate = DateTime(2015, 6, 24);
    }

    _selectedSport = 'Cricket'; // Default to Cricket for cricket app
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
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
            Row(
              children: [
                Expanded(
                  child: _buildTextField("First Name", _firstNameController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField("Last Name", _lastNameController),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabel("Date of Birth"),
            const SizedBox(height: 8),
            InkWell(
              onTap: _presentDatePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDate),
                      style: GoogleFonts.inter(
                        color: AppPalette.textPrimaryLight,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Primary Sport"),
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
                            value: _selectedSport,
                            items: _sports
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(
                              () => _selectedSport = val ?? _selectedSport,
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    "Jersey #",
                    _jerseyController,
                    isCenter: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField(
              "Current Team",
              _teamController,
              icon: Icons.people_alt_rounded,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Save Changes Clicked!')),
                  );
                  context.pop();
                },
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
              onPressed: () {
                // Destructive action
              },
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
