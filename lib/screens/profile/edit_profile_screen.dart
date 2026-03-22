import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../config/palette.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../utils/country_codes.dart';

const _kMapsApiKey = 'AIzaSyA49gBcEHS6benjXtwA2rakOLejlmDFd-0';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const EditProfileScreen({super.key, this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // ── Step 1 controllers ────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressFocus = FocusNode();
  final _phoneFieldKey = GlobalKey();
  String _selectedCountryCode = '+94';

  // ── Step 2 controllers ────────────────────────────────────────────────────
  final _dobController = TextEditingController();
  final _medicalController = TextEditingController();
  String _selectedCricketRole = 'Batsman';
  String _selectedBattingStyle = 'Right-hand bat';
  String _selectedBowlingStyle = 'Right-arm fast';

  static const _cricketRoles = ['Batsman', 'Bowler', 'All-Rounder', 'Wicket Keeper'];
  static const _battingStyles = ['Right-hand bat', 'Left-hand bat'];
  static const _bowlingStyles = [
    'Right-arm fast', 'Right-arm medium', 'Right-arm spin',
    'Left-arm fast', 'Left-arm medium', 'Left-arm spin', 'None',
  ];

  // ── Shared state ──────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isDetectingLocation = false;
  String _userRole = 'player';
  String? _profileImageUrl;
  String? _userId;
  String? _openDropdown; // tracks which dropdown is currently open

  // ── Places autocomplete ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  bool _fetchingSuggestions = false;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.profileData != null) {
      _initializeWithData(widget.profileData!);
    } else {
      _fetchAndInitialize();
    }

    _addressController.addListener(_onAddressChanged);
    _addressFocus.addListener(() {
      if (!_addressFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  void _initializeWithData(Map<String, dynamic> data) {
    _userRole = data['role'] ?? 'player';
    _userId = data['_id'] ?? data['id'];
    _nameController.text = data['fullName'] ?? '';
    _emailController.text = data['email'] ?? '';

    // Phone
    String phone = data['phone'] ?? data['phoneNumber'] ?? '';
    if (phone.isNotEmpty && phone.contains(' ')) {
      final parts = phone.split(' ');
      _selectedCountryCode = parts.first;
      _phoneController.text = parts.sublist(1).join(' ');
    } else {
      _phoneController.text = phone;
    }

    // Profile image from user or player profile
    final playerProfile = data['playerProfile'] as Map<String, dynamic>?;
    _profileImageUrl = data['profileImage'] ??
        data['profilePhoto'] ??
        playerProfile?['profilePhoto'];

    // Player-specific
    if (playerProfile != null) {
      _addressController.text = playerProfile['address'] ?? '';
      _dobController.text = playerProfile['dateOfBirth'] ?? playerProfile['dob'] ?? '';
      _medicalController.text = playerProfile['medicalIssues'] ?? '';

      final role = playerProfile['role'] as String?;
      if (role != null && _cricketRoles.contains(role)) {
        _selectedCricketRole = role;
      }
      final batting = playerProfile['battingStyle'] as String?;
      if (batting != null && _battingStyles.contains(batting)) {
        _selectedBattingStyle = batting;
      }
      final bowling = playerProfile['bowlingStyle'] as String?;
      if (bowling != null && _bowlingStyles.contains(bowling)) {
        _selectedBowlingStyle = bowling;
      }
    }
  }

  Future<void> _fetchAndInitialize() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileService.getProfile();
      _initializeWithData(profile);
    } catch (e) {
      if (mounted) _showSnack('Error loading profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _addressFocus.dispose();
    _mapController?.dispose();
    _dobController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  // ── Google Places autocomplete ────────────────────────────────────────────

  Future<void> _onAddressChanged() async {
    final query = _addressController.text.trim();
    if (query.length < 3) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    setState(() => _fetchingSuggestions = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}&key=$_kMapsApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List<dynamic>? ?? [];
        setState(() {
          _suggestions = predictions.map((p) => {
            'placeId': p['place_id'] as String,
            'description': p['description'] as String,
            'mainText': p['structured_formatting']?['main_text'] as String? ?? p['description'],
            'secondaryText': p['structured_formatting']?['secondary_text'] as String? ?? '',
          }).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _fetchingSuggestions = false);
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final description = suggestion['description'] as String;
    _addressController.removeListener(_onAddressChanged);
    _addressController.text = description;
    _addressController.addListener(_onAddressChanged);
    setState(() { _suggestions = []; _showSuggestions = false; });
    _addressFocus.unfocus();
    await _geocodeAddress(suggestion['placeId'] as String);
  }

  Future<void> _geocodeAddress(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId&fields=geometry&key=$_kMapsApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loc = data['result']?['geometry']?['location'];
        if (loc != null) {
          final latlng = LatLng(loc['lat'] as double, loc['lng'] as double);
          setState(() => _selectedLocation = latlng);
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 15));
        }
      }
    } catch (_) {}
  }

  Future<void> _autoDetectLocation() async {
    if (!mounted) return;
    setState(() => _isDetectingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street?.isNotEmpty == true) p.street!,
          if (p.locality?.isNotEmpty == true) p.locality!,
          if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea!,
          if (p.country?.isNotEmpty == true) p.country!,
        ];
        final city = parts.join(', ');
        setState(() {
          if (city.isNotEmpty) {
            _addressController.removeListener(_onAddressChanged);
            _addressController.text = city;
            _addressController.addListener(_onAddressChanged);
          }
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Could not detect location. Please enter manually.', isError: true);
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  // ── Step navigation ───────────────────────────────────────────────────────

  void _goToStep2() {
    if (!_formKeyStep1.currentState!.validate()) return;
    _autoSaveProgress();
    setState(() => _currentStep = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goToStep1() {
    setState(() => _currentStep = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _autoSaveProgress() async {
    try {
      final String fullPhone = '$_selectedCountryCode ${_phoneController.text.trim()}';
      await ProfileService.updateProfile({
        'fullName': _nameController.text.trim(),
        'phone': fullPhone,
        'address': _addressController.text.trim(),
      });
      await AuthService.updateStoredUserData(_nameController.text.trim(), _userRole);
    } catch (e) {
      debugPrint('Auto-save failed: $e');
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    if (!_formKeyStep2.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final String fullPhone = '$_selectedCountryCode ${_phoneController.text.trim()}';

      await ProfileService.updateProfile({
        'fullName': _nameController.text.trim(),
        'phone': fullPhone,
        // Player profile fields
        'address': _addressController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'role': _selectedCricketRole,
        'battingStyle': _selectedBattingStyle,
        'bowlingStyle': _selectedBowlingStyle,
        'medicalIssues': _medicalController.text.trim(),
      });

      await AuthService.updateStoredUserData(_nameController.text.trim(), _userRole);

      // Dismiss profile completion notification now that profile is saved
      try {
        await NotificationService.markAllAsRead();
      } catch (e) {
        debugPrint('Could not clear notifications: $e');
      }

      if (mounted) {
        _showSnack('Profile updated successfully!', isError: false);
        context.pop(true);
      }
    } catch (e) {
      if (mounted) _showSnack('Error updating profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeProfilePhoto() async {
    if (_userId == null) {
      _showSnack('User ID not found. Please try again.', isError: true);
      return;
    }
    try {
      final XFile? pickedFile = await StorageService.showImageSourceSheet(context);
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);
      final String downloadUrl = await StorageService.uploadProfilePicture(
        userId: _userId!,
        imageFile: File(pickedFile.path),
      );
      await ProfileService.updateProfileImage(downloadUrl);

      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploadingImage = false;
      });
      if (mounted) _showSnack('Profile picture updated!', isError: false);
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) _showSnack('Error uploading photo: $e', isError: true);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppPalette.error : AppPalette.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? Colors.white54 : Colors.grey.shade500;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(children: [
          _buildHeader(labelColor),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ]),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() { _showSuggestions = false; _openDropdown = null; });
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildHeader(labelColor),
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentStep == i ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentStep == i
                        ? AppPalette.orangeAccent
                        : (isDark ? Colors.white24 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(isDark, labelColor, subColor, cardColor, borderColor),
                  _buildStep2(isDark, labelColor, subColor, cardColor, borderColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(Color labelColor) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 16,
          left: 8,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: labelColor),
              onPressed: () {
                if (_currentStep == 1) {
                  _goToStep1();
                } else if (context.canPop()) {
                  context.pop();
                }
              },
            ),
            Expanded(
              child: Text(
                _currentStep == 0 ? 'Personal Info' : 'Cricket Info',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Personal Info + Address ──────────────────────────────────────

  Widget _buildStep1(bool isDark, Color labelColor, Color subColor, Color cardColor, Color borderColor) {
    return Form(
      key: _formKeyStep1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(height: 28),

            _buildSectionLabel('PERSONAL INFORMATION', subColor),
            const SizedBox(height: 12),
            _buildField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
              isDark: isDark, cardColor: cardColor, borderColor: borderColor, labelColor: labelColor,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 28),

            _buildSectionLabel('CONTACT DETAILS', subColor),
            const SizedBox(height: 12),
            _buildField(
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email_outlined,
              isDark: isDark, cardColor: cardColor, borderColor: borderColor, labelColor: labelColor,
              readOnly: true,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _buildPhoneField(isDark: isDark, cardColor: cardColor, borderColor: borderColor, labelColor: labelColor),
            const SizedBox(height: 28),

            _buildSectionLabel('HOME ADDRESS', subColor),
            const SizedBox(height: 8),
            _buildAddressSection(isDark: isDark, cardColor: cardColor, borderColor: borderColor, labelColor: labelColor, subColor: subColor),
            const SizedBox(height: 32),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _goToStep2,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Cricket Info ──────────────────────────────────────────────────

  Widget _buildStep2(bool isDark, Color labelColor, Color subColor, Color cardColor, Color borderColor) {
    return Form(
      key: _formKeyStep2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('PLAYER DETAILS', subColor),
            const SizedBox(height: 12),

            // Date of Birth
            _buildField(
              label: 'Date of Birth',
              controller: _dobController,
              icon: Icons.cake_outlined,
              isDark: isDark, cardColor: cardColor, borderColor: borderColor, labelColor: labelColor,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: isDark
                            ? const ColorScheme.dark(
                                primary: AppPalette.orangeAccent,
                                onPrimary: Colors.white,
                                surface: Color(0xFF1E2340),
                                onSurface: Colors.white,
                              )
                            : const ColorScheme.light(
                                primary: AppPalette.orangeAccent,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black87,
                              ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                }
              },
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Date of Birth is required' : null,
            ),
            const SizedBox(height: 28),

            _buildSectionLabel('CRICKET PROFILE', subColor),
            const SizedBox(height: 12),

            // Cricket Role
            _buildDropdownField(
              id: 'role',
              label: 'Playing Role',
              icon: Icons.sports_cricket,
              value: _selectedCricketRole,
              items: _cricketRoles,
              onChanged: (v) => setState(() => _selectedCricketRole = v),
              isDark: isDark, cardColor: cardColor, borderColor: borderColor, labelColor: labelColor,
            ),
            const SizedBox(height: 14),

            // Batting Style
            _buildDropdownField(
              id: 'batting',
              label: 'Batting Style',
              icon: Icons.swipe_right_outlined,
              value: _selectedBattingStyle,
              items: _battingStyles,
              onChanged: (v) => setState(() => _selectedBattingStyle = v),
              isDark: isDark, cardColor: cardColor, borderColor: borderColor, labelColor: labelColor,
            ),
            const SizedBox(height: 14),

            // Bowling Style
            _buildDropdownField(
              id: 'bowling',
              label: 'Bowling Style',
              icon: Icons.rotate_right_outlined,
              value: _selectedBowlingStyle,
              items: _bowlingStyles,
              onChanged: (v) => setState(() => _selectedBowlingStyle = v),
              isDark: isDark, cardColor: cardColor, borderColor: borderColor, labelColor: labelColor,
            ),
            const SizedBox(height: 28),

            _buildSectionLabel('MEDICAL NOTES (OPTIONAL)', subColor),
            const SizedBox(height: 12),

            // Medical
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextFormField(
                controller: _medicalController,
                maxLines: 3,
                style: GoogleFonts.inter(color: labelColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Allergies, conditions, injuries...',
                  hintStyle: GoogleFonts.inter(color: labelColor.withValues(alpha: 0.4), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  disabledBackgroundColor: AppPalette.orangeAccent.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Save Changes', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                backgroundColor: AppPalette.orangeAccent.withValues(alpha: 0.1),
                child: _profileImageUrl == null
                    ? Icon(Icons.person, size: 52, color: AppPalette.orangeAccent.withValues(alpha: 0.4))
                    : null,
              ),
              if (_isUploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 4,
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _changeProfilePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isUploadingImage ? Colors.grey : AppPalette.orangeAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _changeProfilePhoto,
            child: Text(
              'Change Profile Photo',
              style: GoogleFonts.inter(color: AppPalette.orangeAccent, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms);
  }

  Widget _buildSectionLabel(String text, Color subColor) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: subColor, letterSpacing: 1.2),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color labelColor,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: labelColor.withValues(alpha: 0.8), fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.inter(color: readOnly ? labelColor.withValues(alpha: 0.5) : labelColor, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(icon, color: AppPalette.orangeAccent, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String id,
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String) onChanged,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color labelColor,
  }) {
    final isOpen = _openDropdown == id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: labelColor.withValues(alpha: 0.8),
                fontSize: 13)),
        const SizedBox(height: 8),
        // ── Field row (tap to toggle) ──────────────────────────────────────
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() {
              _openDropdown = isOpen ? null : id;
              _showSuggestions = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: isOpen
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.circular(12),
              border: Border.all(
                color: isOpen ? AppPalette.orangeAccent : borderColor,
                width: isOpen ? 1.5 : 1,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
            ),
            child: Row(
              children: [
                Icon(icon, color: AppPalette.orangeAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(value,
                      style: GoogleFonts.inter(
                          color: labelColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down,
                      color: AppPalette.orangeAccent, size: 22),
                ),
              ],
            ),
          ),
        ),
        // ── Inline option list ─────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => SizeTransition(
            sizeFactor: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          child: isOpen
              ? Container(
                  key: ValueKey('$id-open'),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2940) : Colors.white,
                    border: Border(
                      left: BorderSide(color: AppPalette.orangeAccent, width: 1.5),
                      right: BorderSide(color: AppPalette.orangeAccent, width: 1.5),
                      bottom: BorderSide(color: AppPalette.orangeAccent, width: 1.5),
                    ),
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Column(
                    children: items.map((item) {
                      final isSelected = item == value;
                      return InkWell(
                        onTap: () {
                          onChanged(item);
                          setState(() => _openDropdown = null);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppPalette.orangeAccent.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border(
                              bottom: items.last == item
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.grey.shade100),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppPalette.orangeAccent
                                        : labelColor,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_rounded,
                                    size: 18, color: AppPalette.orangeAccent),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('closed')),
        ),
      ],
    );
  }

  Widget _buildPhoneField({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phone Number', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: labelColor.withValues(alpha: 0.8), fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          key: _phoneFieldKey,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 105,
                child: Autocomplete<Map<String, String>>(
                  initialValue: TextEditingValue(text: _selectedCountryCode),
                  displayStringForOption: (o) => o['code']!,
                  optionsBuilder: (v) {
                    final q = v.text.toLowerCase();
                    return q.isEmpty
                        ? worldCountryCodes
                        : worldCountryCodes.where((o) =>
                            o['code']!.toLowerCase().contains(q) ||
                            o['name']!.toLowerCase().contains(q));
                  },
                  onSelected: (s) => setState(() => _selectedCountryCode = s['code']!),
                  fieldViewBuilder: (ctx, ctrl, focus, onEditingComplete) {
                    if (ctrl.text.isEmpty && _selectedCountryCode.isNotEmpty) {
                      ctrl.text = _selectedCountryCode;
                    }
                    return TextField(
                      controller: ctrl,
                      focusNode: focus,
                      style: GoogleFonts.inter(color: labelColor, fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        suffixIconColor: isDark ? Colors.white54 : Colors.grey[600],
                        suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
                      ),
                      onChanged: (val) => _selectedCountryCode = val,
                      keyboardType: TextInputType.phone,
                    );
                  },
                  optionsViewBuilder: (ctx, onSelected, options) {
                    final box = _phoneFieldKey.currentContext?.findRenderObject() as RenderBox?;
                    final width = box?.size.width ?? (MediaQuery.of(context).size.width - 48);
                    return Align(
                      alignment: Alignment.topLeft,
                      child: OverflowBox(
                        maxWidth: width,
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? const Color(0xFF1E2340) : Colors.white,
                          child: Container(
                            width: width,
                            constraints: const BoxConstraints(maxHeight: 240),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                              itemBuilder: (_, i) {
                                final o = options.elementAt(i);
                                return InkWell(
                                  onTap: () => onSelected(o),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Text(o['code']!, style: GoogleFonts.inter(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(width: 12),
                                        Flexible(child: Text(o['name']!, style: GoogleFonts.inter(color: labelColor, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(width: 1, height: 28, color: borderColor),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: labelColor, fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    hintText: 'Phone number',
                    hintStyle: GoogleFonts.inter(fontSize: 14, color: labelColor.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color labelColor,
    required Color subColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _isDetectingLocation ? null : _autoDetectLocation,
              icon: _isDetectingLocation
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.orangeAccent))
                  : const Icon(Icons.my_location, size: 18, color: AppPalette.orangeAccent),
              label: Text('Locate Me', style: GoogleFonts.inter(color: AppPalette.orangeAccent, fontSize: 13, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _addressFocus.hasFocus ? AppPalette.orangeAccent : borderColor,
              width: _addressFocus.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Icon(
                  Icons.location_on_outlined,
                  color: _addressFocus.hasFocus ? AppPalette.orangeAccent : subColor.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  focusNode: _addressFocus,
                  style: GoogleFonts.inter(color: labelColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search address…',
                    hintStyle: GoogleFonts.inter(color: subColor.withValues(alpha: 0.5), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  ),
                ),
              ),
              if (_fetchingSuggestions)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.orangeAccent)),
                )
              else if (_addressController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: subColor.withValues(alpha: 0.5)),
                  onPressed: () {
                    _addressController.clear();
                    setState(() { _suggestions = []; _showSuggestions = false; _selectedLocation = null; });
                  },
                ),
            ],
          ),
        ),

        // Suggestions
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2340) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
              itemBuilder: (ctx, i) {
                final s = _suggestions[i];
                return Listener(
                  onPointerDown: (_) => _selectSuggestion(s),
                  child: InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppPalette.orangeAccent.withValues(alpha: 0.12), shape: BoxShape.circle),
                            child: const Icon(Icons.location_pin, size: 16, color: AppPalette.orangeAccent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['mainText'] as String, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if ((s['secondaryText'] as String).isNotEmpty)
                                  Text(s['secondaryText'] as String, style: GoogleFonts.inter(fontSize: 12, color: subColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(duration: 180.ms).slideY(begin: -0.05),

        // Map preview
        if (_selectedLocation != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 170,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: _selectedLocation!, zoom: 15),
                markers: {
                  Marker(
                    markerId: const MarkerId('sel'),
                    position: _selectedLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                  ),
                },
                onMapCreated: (c) => _mapController = c,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
        ],
      ],
    );
  }
}
