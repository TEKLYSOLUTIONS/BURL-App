import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/palette.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/places_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../providers/theme_provider.dart';
import '../../utils/currency_helper.dart';
import '../../utils/country_codes.dart';

class CompleteCoachProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? profileData;

  const CompleteCoachProfileScreen({super.key, this.profileData});

  @override
  ConsumerState<CompleteCoachProfileScreen> createState() =>
      _CompleteCoachProfileScreenState();
}

class _CompleteCoachProfileScreenState
    extends ConsumerState<CompleteCoachProfileScreen> {
  int _currentStep = 0;
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Basic Info Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final GlobalKey _phoneFieldKey = GlobalKey();

  // Page Controller for Swiping
  final PageController _pageController = PageController();

  String _selectedCountryCode = '+1'; // Default to +1

  // Cricket Coach Controllers
  final TextEditingController _coachTitleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _philosophyController = TextEditingController();
  final TextEditingController _playingCareerController =
      TextEditingController();

  // Pricing Controllers removed as per request

  // Dropdown/Selection State
  String? _primarySpecialization;
  List<String> _selectedSpecialties = [];
  List<String> _certifications = [];
  List<String> _achievements = [];
  List<String> _ageGroups = [];
  List<String> _sessionTypes = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDetectingLocation = false;
  String? _profileImageUrl;
  String? _userId;
  String? _country; // Store country extracted from location
  String? _userCurrency; // Store detected currency

  // Autocomplete State
  List<PlacePrediction> _predictions = [];
  Timer? _debounce;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _cityFocus = FocusNode();

  // Cricket Specialties Options
  final List<String> _specialtyOptions = [
    'Batting',
    'Fast Bowling',
    'Spin Bowling',
    'Wicket Keeping',
    'Fielding',
    'Fitness & Conditioning',
    'Mental Coaching',
    'Technical Analysis',
    'Tactical Planning',
  ];

  // Primary Specialization Options
  final List<String> _primarySpecOptions = [
    'batting',
    'bowling',
    'fitness',
    'fielding',
    'all-round',
    'wicketkeeping',
    'mental',
    'other',
  ];

  // Age Groups Options
  final List<String> _ageGroupOptions = [
    'U10',
    'U12',
    'U15',
    'U17',
    'U19',
    'Senior',
    'Professional',
  ];

  // Session Types Options
  final List<String> _sessionTypeOptions = [
    '1-on-1 Training',
    'Group Sessions',
    'Video Analysis',
    'Fitness Training',
    'Match Preparation',
    'Technical Coaching',
    'Mental Conditioning',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.profileData != null) {
      _initializeWithData(widget.profileData!);
      // Auto-detect only if no country saved
      if (_country == null || _country!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoDetectLocation();
        });
      }
    } else {
      _fetchAndInitialize();
    }
  }

  /// Requests GPS permission, gets current coordinates, then reverse-geocodes
  /// to obtain city and country. Fills [_cityController] and updates [_country]/[_userCurrency].
  Future<void> _autoDetectLocation() async {
    if (!mounted) return;
    setState(() => _isDetectingLocation = true);
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isDetectingLocation = false);
        return;
      }

      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) setState(() => _isDetectingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isDetectingLocation = false);
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Reverse geocode
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        // Pick city: prefer locality â†’ subAdminArea â†’ adminArea
        final city = (placemark.locality?.isNotEmpty == true
                ? placemark.locality
                : placemark.subAdministrativeArea?.isNotEmpty == true
                    ? placemark.subAdministrativeArea
                    : placemark.administrativeArea) ??
            '';
        final country = placemark.country ?? '';
        setState(() {
          if (city.isNotEmpty) _cityController.text = city;
          if (country.isNotEmpty) {
            _country = country;
            _userCurrency = CurrencyHelper.getCurrencyFromLocation(country);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not detect location automatically. Please enter manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _initializeWithData(Map<String, dynamic> data) {
    // Basic info
    _nameController.text = data['fullName'] ?? '';
    _emailController.text = data['email'] ?? '';

    final fullPhone = data['phone'] ?? data['phoneNumber'] ?? '';
    if (fullPhone.isNotEmpty && fullPhone.contains(' ')) {
      final parts = fullPhone.split(' ');
      if (parts.length > 1) {
        _selectedCountryCode = parts.first;
        _phoneController.text = parts.sublist(1).join(' ');
      } else {
        _phoneController.text = fullPhone;
        _selectedCountryCode = '+1';
      }
    } else {
      _phoneController.text = fullPhone;
    }

    _profileImageUrl = data['coachProfile']?['profilePhoto'] ??
        data['profileImage'] ??
        data['profileUrl'] ??
        data['profilePhotoUrl'];
    _userId = data['_id'] ?? data['id'];

    // Coach profile data
    if (data['coachProfile'] != null) {
      final coachProfile = data['coachProfile'];

      _cityController.text = coachProfile['city'] ?? '';

      // Extract country and currency from location
      final city = coachProfile['city'] ?? '';
      _country = coachProfile['country'] ?? CurrencyHelper.extractCountry(city);
      _userCurrency = coachProfile['currency'] ??
          CurrencyHelper.getCurrencyFromLocation(city);

      _coachTitleController.text = coachProfile['coachTitle'] ?? '';
      _bioController.text = coachProfile['aboutMe'] ?? '';
      _experienceController.text =
          coachProfile['experienceYears']?.toString() ?? '0';
      _philosophyController.text = coachProfile['coachingPhilosophy'] ?? '';
      _playingCareerController.text =
          coachProfile['playingCareerBackground'] ?? '';

      // Pricing removed

      _primarySpecialization = coachProfile['primarySpecialization'];

      // Safely convert arrays to List<String>
      _selectedSpecialties = (coachProfile['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _certifications = (coachProfile['certifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _achievements = (coachProfile['notableAchievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _ageGroups = (coachProfile['ageGroupsCoached'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _sessionTypes = (coachProfile['sessionTypesOffered'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    }
  }

  Future<void> _fetchAndInitialize() async {
    setState(() => _isLoading = true);

    try {
      final profile = await ProfileService.getProfile();
      _initializeWithData(profile);
      setState(() => _isLoading = false);
      // Auto-detect country if none was saved
      if (_country == null || _country!.isEmpty) {
        _autoDetectLocation();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _cityFocus.dispose();
    _debounce?.cancel();
    _removeOverlay();
    _coachTitleController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _philosophyController.dispose();
    _playingCareerController.dispose();
    _pageController.dispose();

    super.dispose();
  }

  Future<void> _saveChanges() async {
    // NOTE: validation is handled by the Stepper controls
    setState(() => _isSaving = true);

    try {
      final String fullPhone =
          '$_selectedCountryCode ${_phoneController.text.trim()}';

      final updateData = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': fullPhone,
        'city': _cityController.text.trim(),
        'country': _country,
        'currency': _userCurrency ?? CurrencyHelper.defaultCurrency,
        'hourlyRate': 0, // Default to 0
        'sessionDuration': 60, // Default to 60
        'coachTitle': _coachTitleController.text.trim(),
        'bio': _bioController.text.trim(),
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,
        'primarySpecialization': _primarySpecialization,
        'specialties': _selectedSpecialties,
        'certifications': _certifications,
        'coachingPhilosophy': _philosophyController.text.trim(),
        'notableAchievements': _achievements,
        'playingCareerBackground': _playingCareerController.text.trim(),
        'ageGroupsCoached': _ageGroups,
        'sessionTypesOffered': _sessionTypes,
      };

      final updatedUser = await ProfileService.updateProfile(updateData);

      await AuthService.updateStoredUserData(
        updatedUser['fullName'] ?? _nameController.text,
        updatedUser['role'] ?? 'coach',
      );

      // Dismiss profile completion notification now that profile is saved
      try {
        await NotificationService.markAllAsRead();
      } catch (e) {
        debugPrint('Could not clear notifications: $e');
      }

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final pickedFile = await StorageService.showImageSourceSheet(context);
      if (pickedFile == null) return;

      setState(() {
        _isSaving = true;
      });

      final imageUrl = await StorageService.uploadProfilePicture(
        userId: _userId!,
        imageFile: File(pickedFile.path),
      );

      setState(() {
        _profileImageUrl = imageUrl;
        _isSaving = false;
      });

      // Update profile with new photo URL
      await ProfileService.updateProfile({'profileUrl': imageUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        String errorMessage = 'Error uploading photo.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('object-not-found') ||
            errStr.contains('not-found')) {
          errorMessage =
              'Storage path not found. Please check Firebase Storage is enabled.';
        } else if (errStr.contains('unauthorized') ||
            errStr.contains('permission')) {
          errorMessage =
              'Permission denied. Please check Firebase Storage rules.';
        } else if (errStr.contains('network') || errStr.contains('socket')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        } else {
          errorMessage = 'Upload failed: ${e.toString()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(),
          _buildCustomStepper(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildFormPage(0),
                _buildFormPage(1),
                _buildFormPage(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPage(int stepIndex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      child: Column(
        children: [
          _buildStepContent(stepIndex),
          const SizedBox(height: 24),
          _buildContinueButton(stepIndex),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage:
                    _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _changeProfilePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPalette.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _changeProfilePhoto,
            child: Text(
              'Change Profile Photo',
              style: GoogleFonts.inter(
                color: AppPalette.orangeAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isOptional = false,
    FocusNode? focusNode,
    void Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (isOptional) ...[
                const SizedBox(width: 4),
                Text(
                  '(Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          focusNode: focusNode,
          onChanged: onChanged,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
            prefixIcon: Icon(icon, color: theme.colorScheme.primary),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final labelColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number *",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: _phoneFieldKey,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Country Code Autocomplete
              SizedBox(
                width: 105,
                child: Autocomplete<Map<String, String>>(
                  initialValue: TextEditingValue(text: _selectedCountryCode),
                  displayStringForOption: (option) => option['code']!,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return worldCountryCodes;
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return worldCountryCodes
                        .where((Map<String, String> option) {
                      return option['code']!.toLowerCase().contains(query) ||
                          option['name']!.toLowerCase().contains(query);
                    });
                  },
                  onSelected: (Map<String, String> selection) {
                    setState(() {
                      _selectedCountryCode = selection['code']!;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                    if (controller.text.isEmpty &&
                        _selectedCountryCode.isNotEmpty) {
                      controller.text = _selectedCountryCode;
                    }
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: GoogleFonts.inter(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        suffixIconColor:
                            isDark ? Colors.white54 : Colors.grey[600],
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
                      ),
                      onChanged: (val) => _selectedCountryCode = val,
                      keyboardType: TextInputType.phone,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    final box = _phoneFieldKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    final fieldWidth = box?.size.width ??
                        (MediaQuery.of(context).size.width - 48);
                    return Align(
                      alignment: Alignment.topLeft,
                      child: OverflowBox(
                        maxWidth: fieldWidth,
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          child: Container(
                            width: fieldWidth,
                            constraints: const BoxConstraints(maxHeight: 260),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color:
                                    isDark ? Colors.white24 : Colors.grey[200],
                              ),
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Text(
                                          option['code']!,
                                          style: GoogleFonts.inter(
                                            color: labelColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            option['name']!,
                                            style: GoogleFonts.inter(
                                              color: labelColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
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
              // Vertical Divider
              Container(
                width: 1,
                height: 28,
                color: isDark ? Colors.white24 : Colors.grey[300],
              ),
              // Phone Number Input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: labelColor),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Phone is required' : null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    hintText: '1 234 567 8900',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          initialValue: value,
          onSelected: onChanged,
          position: PopupMenuPosition.under,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 48,
            maxWidth: MediaQuery.of(context).size.width - 48,
          ),
          itemBuilder: (context) => items.map((String item) {
            return PopupMenuItem<String>(
              value: item,
              child: Text(
                item.toUpperCase(),
                style: GoogleFonts.inter(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null ? value.toUpperCase() : 'Select...',
                  style: value != null
                      ? GoogleFonts.inter(
                          color: theme.textTheme.bodyLarge?.color)
                      : TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppPalette.orangeAccent),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips({
    required String label,
    required List<String> options,
    required List<String> selectedOptions,
    required void Function(List<String>) onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return GestureDetector(
              onTap: () {
                final newSelected = List<String>.from(selectedOptions);
                if (isSelected) {
                  newSelected.remove(option);
                } else {
                  newSelected.add(option);
                }
                onChanged(newSelected);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppPalette.orangeAccent.withValues(alpha: 0.1)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppPalette.orangeAccent
                        : isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppPalette.orangeAccent
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScrollableBoxField({
    required String label,
    required List<String> items,
    required String hint,
    required String dialogTitle,
    required String dialogHint,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    // Each card: 56px + 6px bottom margin = 62px total per item
    const double cardHeight = 56;
    const double cardMargin = 6;
    const double itemHeight = cardHeight + cardMargin;
    const int maxVisible = 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            GestureDetector(
              onTap: () => _showAddDialog(
                dialogTitle,
                dialogHint,
                (value) => setState(() => items.add(value)),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 16, color: AppPalette.orangeAccent),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppPalette.orangeAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hint,
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                fontSize: 14,
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: items.length <= maxVisible
                  ? items.length * itemHeight
                  : maxVisible * itemHeight,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: items.length > maxVisible
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: cardMargin),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: accentColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          items[index],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => items.removeAt(index)),
                        child:
                            Icon(Icons.close, size: 18, color: Colors.red[300]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (items.length > maxVisible)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${items.length - maxVisible} more — scroll to see all',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _removeOverlay();
        return;
      }

      final predictions = await PlacesService.getAutocomplete(query);
      if (mounted) {
        setState(() {
          _predictions = predictions;
        });
        if (_predictions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Positioned(
          width: MediaQuery.of(context).size.width - 48, // 24 padding each side
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(
              0,
              60,
            ), // Adjust offset based on text field height
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.white24 : Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final p = _predictions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        p.mainText,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      subtitle: Text(
                        p.secondaryText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      onTap: () => _onPredictionSelected(p),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onPredictionSelected(PlacePrediction prediction) {
    _removeOverlay();
    _cityController.text = prediction.description;

    // Extract country and currency from selected location
    setState(() {
      _country = CurrencyHelper.extractCountry(prediction.description);
      _userCurrency =
          CurrencyHelper.getCurrencyFromLocation(prediction.description);
    });

    _cityFocus.unfocus();
  }

  Future<void> _showAddDialog(
    String title,
    String hint,
    void Function(String) onAdd,
  ) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.navyPrimary,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            children: [
              _buildProfilePhotoSection(),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name *',
                hint: 'John Doe',
                icon: Icons.person_outline,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email *',
                hint: 'john@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'City/Location *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (_isDetectingLocation)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        GestureDetector(
                          onTap: _autoDetectLocation,
                          child: Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                size: 16,
                                color: AppPalette.orangeAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Detect',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppPalette.orangeAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: _buildTextField(
                      controller: _cityController,
                      label: '',
                      hint: 'Search for your city...',
                      icon: Icons.location_on_outlined,
                      focusNode: _cityFocus,
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            children: [
              _buildTextField(
                controller: _coachTitleController,
                label: 'Coach Title',
                hint: 'Head Coach, Batting Coach, etc.',
                icon: Icons.badge_outlined,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _experienceController,
                label: 'Years of Experience *',
                hint: '5',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Experience is required';
                  }
                  if (int.tryParse(value!) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: 'About Me *',
                hint: 'Tell players about your coaching style...',
                icon: Icons.description_outlined,
                maxLines: 4,
                maxLength: 500,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Bio is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _playingCareerController,
                label: 'Playing Career Background',
                hint: 'Former first-class player, played for...',
                icon: Icons.sports,
                maxLines: 3,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _philosophyController,
                label: 'Coaching Philosophy',
                hint: 'Describe your coaching approach...',
                icon: Icons.psychology_outlined,
                maxLines: 3,
                isOptional: true,
              ),
            ],
          ),
        );
      case 2:
        return Form(
          key: _formKeys[2],
          child: Column(
            children: [
              _buildDropdownField(
                label: 'Primary Specialization',
                value: _primarySpecialization,
                items: _primarySpecOptions,
                onChanged: (value) =>
                    setState(() => _primarySpecialization = value),
                icon: Icons.star_outline,
              ),
              const SizedBox(height: 16),
              _buildMultiSelectChips(
                label: 'Cricket Specialties',
                options: _specialtyOptions,
                selectedOptions: _selectedSpecialties,
                onChanged: (selected) =>
                    setState(() => _selectedSpecialties = selected),
              ),
              const SizedBox(height: 16),
              _buildMultiSelectChips(
                label: 'Age Groups You Coach',
                options: _ageGroupOptions,
                selectedOptions: _ageGroups,
                onChanged: (selected) => setState(() => _ageGroups = selected),
              ),
              const SizedBox(height: 16),
              _buildMultiSelectChips(
                label: 'Session Types Offered',
                options: _sessionTypeOptions,
                selectedOptions: _sessionTypes,
                onChanged: (selected) =>
                    setState(() => _sessionTypes = selected),
              ),
              const SizedBox(height: 16),
              _buildScrollableBoxField(
                label: 'Certifications',
                items: _certifications,
                hint: 'Add your coaching certifications',
                dialogTitle: 'Add Certification',
                dialogHint: 'E.g., ICC Level 2, ECB Level 3',
                icon: Icons.workspace_premium,
                accentColor: AppPalette.orangeAccent,
              ),
              const SizedBox(height: 16),
              _buildScrollableBoxField(
                label: 'Notable Achievements',
                items: _achievements,
                hint: 'Add your coaching achievements',
                dialogTitle: 'Add Achievement',
                dialogHint: 'E.g., Coached U19 State Team',
                icon: Icons.emoji_events_outlined,
                accentColor: Colors.amber,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 16,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: AppPalette.navyPrimary,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildCustomStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMinimalStepIndicator(0),
          _buildMinimalStepIndicator(1),
          _buildMinimalStepIndicator(2),
        ],
      ),
    );
  }

  Widget _buildMinimalStepIndicator(int stepIndex) {
    final bool isActive = _currentStep == stepIndex;
    final bool isCompleted = _currentStep > stepIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isCompleted || isActive
            ? AppPalette.orangeAccent
            : Colors.grey[300],
      ),
    );
  }

  Widget _buildContinueButton(int stepIndex) {
    final isLastStep = stepIndex == 2;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving
            ? null
            : () {
                if (_formKeys[stepIndex].currentState!.validate()) {
                  if (isLastStep) {
                    _saveChanges();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.orangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSaving && isLastStep
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastStep ? 'Finish Profile' : 'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (isLastStep) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check, color: Colors.white, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}
