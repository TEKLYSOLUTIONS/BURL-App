import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../services/profile_service.dart';

class CompleteCoachProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const CompleteCoachProfileScreen({super.key, this.profileData});

  @override
  State<CompleteCoachProfileScreen> createState() =>
      _CompleteCoachProfileScreenState();
}

class _CompleteCoachProfileScreenState
    extends State<CompleteCoachProfileScreen> {
  final _formKey = GlobalKey<FormState>();

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
  
  // Pricing Controllers
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _sessionDurationController = TextEditingController(text: '60');

  // Dropdown/Selection State
  String? _primarySpecialization;
  List<String> _selectedSpecialties = [];
  List<String> _certifications = [];
  List<String> _achievements = [];
  List<String> _ageGroups = [];
  List<String> _sessionTypes = [];

  bool _isLoading = false;
  bool _isSaving = false;

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

      // Pricing
      if (coachProfile['defaultPricing'] != null) {
        _hourlyRateController.text = 
            coachProfile['defaultPricing']['hourlyRate']?.toString() ?? '';
        _sessionDurationController.text = 
            coachProfile['defaultPricing']['sessionDuration']?.toString() ?? '60';
      }

      _primarySpecialization = coachProfile['primarySpecialization'];
      _selectedSpecialties =
          List<String>.from(coachProfile['specialties'] ?? []);
      _certifications = List<String>.from(coachProfile['certifications'] ?? []);
      _achievements =
          List<String>.from(coachProfile['notableAchievements'] ?? []);
      _ageGroups = List<String>.from(coachProfile['ageGroupsCoached'] ?? []);
      _sessionTypes =
          List<String>.from(coachProfile['sessionTypesOffered'] ?? []);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _coachTitleController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _philosophyController.dispose();
    _playingCareerController.dispose();
    _hourlyRateController.dispose();
    _sessionDurationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'hourlyRate': double.tryParse(_hourlyRateController.text.trim()) ?? 0,
        'sessionDuration': int.tryParse(_sessionDurationController.text.trim()) ?? 60,
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

      await ProfileService.updateProfile(updateData);

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
      appBar: AppBar(
        backgroundColor: AppPalette.navyPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              _buildProfilePhotoSection(),
              const SizedBox(height: 32),

              // Basic Information
              _buildSectionTitle('Basic Information', Icons.person),
              const SizedBox(height: 16),
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
              _buildTextField(
                controller: _cityController,
                label: 'City/Location',
                hint: 'New York, USA',
                icon: Icons.location_on_outlined,
                isOptional: true,
              ),
              const SizedBox(height: 32),

              // Pricing for Individual Bookings
              _buildSectionTitle('Pricing for Individual Bookings', Icons.attach_money),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _hourlyRateController,
                      label: 'Hourly Rate',
                      hint: '60',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      isOptional: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _sessionDurationController,
                      label: 'Duration (min)',
                      hint: '60',
                      icon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      isOptional: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Players will see this rate when booking individual sessions',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppPalette.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),

              // Cricket Coaching Details
              _buildSectionTitle('Cricket Coaching Details', Icons.sports_cricket),
              const SizedBox(height: 16),
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
                  if (value?.isEmpty ?? true) return 'Experience is required';
                  if (int.tryParse(value!) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Primary Specialization Dropdown
              _buildDropdownField(
                label: 'Primary Specialization',
                value: _primarySpecialization,
                items: _primarySpecOptions,
                onChanged: (value) =>
                    setState(() => _primarySpecialization = value),
                icon: Icons.star_outline,
              ),
              const SizedBox(height: 16),

              // Multiple Specialties
              _buildMultiSelectChips(
                label: 'Cricket Specialties',
                options: _specialtyOptions,
                selectedOptions: _selectedSpecialties,
                onChanged: (selected) =>
                    setState(() => _selectedSpecialties = selected),
              ),
              const SizedBox(height: 16),

              // Bio
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
              const SizedBox(height: 32),

              // Professional Background
              _buildSectionTitle('Professional Background', Icons.military_tech),
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
              const SizedBox(height: 32),

              // Training Details
              _buildSectionTitle('Training Details', Icons.groups),
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
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
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
                  child: const Icon(Icons.camera_alt,
                      size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Photo upload coming soon!')),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppPalette.navyPrimary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
      ],
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
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppPalette.navyPrimary),
            filled: true,
            fillColor: Colors.white,
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
              borderSide:
                  const BorderSide(color: AppPalette.navyPrimary, width: 2),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
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
                  child: Text(
                    item.toUpperCase(),
                    style: GoogleFonts.inter(),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedOptions);
                if (selected) {
                  newSelection.add(option);
                } else {
                  newSelection.remove(option);
                }
                onChanged(newSelection);
              },
              selectedColor: AppPalette.navyPrimary.withValues(alpha: 0.2),
              checkmarkColor: AppPalette.navyPrimary,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? AppPalette.navyPrimary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
              border: Border.all(color: Colors.grey[300]!),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.inter(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.orange),
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

  Future<void> _showAddDialog(
    String title,
    String hint,
    void Function(String) onAdd,
  ) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
}
