import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../config/palette.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/places_service.dart';

class CompleteCoachProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const CompleteCoachProfileScreen({super.key, this.profileData});

  @override
  State<CompleteCoachProfileScreen> createState() =>
      _CompleteCoachProfileScreenState();
}

class _CompleteCoachProfileScreenState
    extends State<CompleteCoachProfileScreen> {
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
    } else {
      _fetchAndInitialize();
    }
  }

  void _initializeWithData(Map<String, dynamic> data) {
    // Basic info
    _nameController.text = data['fullName'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? data['phoneNumber'] ?? '';

    // Coach profile data
    if (data['coachProfile'] != null) {
      final coachProfile = data['coachProfile'];

      _cityController.text = coachProfile['city'] ?? '';
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
      _selectedSpecialties =
          (coachProfile['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _certifications =
          (coachProfile['certifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _achievements =
          (coachProfile['notableAchievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _ageGroups =
          (coachProfile['ageGroupsCoached'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _sessionTypes =
          (coachProfile['sessionTypesOffered'] as List<dynamic>?)
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

    super.dispose();
  }

  Future<void> _saveChanges() async {
    // NOTE: validation is handled by the Stepper controls
    setState(() => _isSaving = true);

    try {
      final updateData = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppPalette.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(
            child: Column(
              children: [
                _buildCustomStepper(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: _buildStepContent(_currentStep),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppPalette.navyPrimary,
                child: Icon(Icons.person, size: 50, color: Colors.white),
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
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo upload coming soon!')),
              );
            },
            child: Text(
              'Change Profile Photo',
              style: GoogleFonts.inter(
                color: Colors.orange,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textPrimaryLight,
                ),
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 4),
              Text(
                '(Optional)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppPalette.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppPalette.navyPrimary),
            filled: true,
            fillColor: Colors.grey[100],
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
              borderSide: const BorderSide(
                color: AppPalette.navyPrimary,
                width: 1.5,
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.orange),
              hint: const Text('Select...'),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item.toUpperCase(), style: GoogleFonts.inter()),
                );
              }).toList(),
              onChanged: onChanged,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppPalette.navyPrimary,
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
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey[300]!,
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
                        color: isSelected ? Colors.orange : Colors.grey[700],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check, size: 16, color: Colors.orange),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListField({
    required String label,
    required List<String> items,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required String hint,
  }) {
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
                color: AppPalette.textPrimaryLight,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18, color: Colors.orange),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.navyPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                hint,
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ...items.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.value, style: GoogleFonts.inter()),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.orange,
                    ),
                    onPressed: () => onRemove(entry.key),
                    color: Colors.red,
                  ),
                ],
              ),
            );
          }),
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
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 48, // 24 padding each side
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(
            0,
            60,
          ), // Adjust offset based on text field height
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = _predictions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      p.mainText,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      p.secondaryText,
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    onTap: () => _onPredictionSelected(p),
                  );
                },
              ),
            ),
          ),
        ),
      ),
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
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number *',
                hint: '+1 234 567 8900',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              CompositedTransformTarget(
                link: _layerLink,
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City/Location',
                  hint: 'Search for your city...',
                  icon: Icons.location_on_outlined,
                  isOptional: true,
                  focusNode: _cityFocus,
                  onChanged: _onSearchChanged,
                ),
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

              _buildListField(
                label: 'Certifications',
                items: _certifications,
                onAdd: () => _showAddDialog(
                  'Add Certification',
                  'E.g., ICC Level 2, ECB Level 3',
                  (value) => setState(() => _certifications.add(value)),
                ),
                onRemove: (index) =>
                    setState(() => _certifications.removeAt(index)),
                hint: 'Add your coaching certifications',
              ),
              const SizedBox(height: 16),
              _buildListField(
                label: 'Notable Achievements',
                items: _achievements,
                onAdd: () => _showAddDialog(
                  'Add Achievement',
                  'E.g., Coached U19 State Team',
                  (value) => setState(() => _achievements.add(value)),
                ),
                onRemove: (index) =>
                    setState(() => _achievements.removeAt(index)),
                hint: 'Add your coaching achievements',
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
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      color: const Color(0xFF0F172A), // Dark Navy
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Text(
            'Edit Profile',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepIndicator(0, 'PERSONAL'),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'PROFESSIONAL'),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'SKILLS'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    final bool isActive = _currentStep == stepIndex;
    final bool isCompleted = _currentStep > stepIndex;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF0F172A) // Dark Navy
                : isActive
                ? Colors.orange
                : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${stepIndex + 1}',
                    style: GoogleFonts.inter(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive || isCompleted
                ? const Color(0xFF64748B)
                : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final bool isCompleted = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        color: isCompleted ? const Color(0xFF0F172A) : Colors.grey[300],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving
              ? null
              : () {
                  if (_formKeys[_currentStep].currentState!.validate()) {
                    if (isLastStep) {
                      _saveChanges();
                    } else {
                      setState(() => _currentStep += 1);
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isSaving
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
      ),
    );
  }
}
