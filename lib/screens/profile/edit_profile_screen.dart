import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/palette.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/country_codes.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const EditProfileScreen({super.key, this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final GlobalKey _phoneFieldKey = GlobalKey();

  String _selectedCountryCode = '+1'; // Default to +1

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String _userRole = '';
  String? _profileImageUrl;
  String? _userId;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current data or fetch from service
    if (widget.profileData != null) {
      _initializeWithData(widget.profileData!);
    } else {
      _fetchAndInitialize();
    }
  }

  void _initializeWithData(Map<String, dynamic> data) {
    _userRole = data['role'] ?? '';
    _userId = data['_id'] ?? data['id'];
    _profileImageUrl = data['profileImage'];
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
      if (fullPhone.isNotEmpty && fullPhone.startsWith('+')) {
        // Fallback logic if there's no space but we have a plus. For now keep simple
      }
    }

    // Get role-specific data
    String bio = '';
    if (_userRole == 'coach' && data['coachProfile'] != null) {
      bio = data['coachProfile']['bio'] ?? '';
      // Also check for profile photo in coach profile
      _profileImageUrl ??= data['coachProfile']['profilePhoto'];
    } else if (_userRole == 'player' && data['playerProfile'] != null) {
      _profileImageUrl ??= data['playerProfile']['profilePhoto'];
    }
    _bioController.text = bio;
  }

  Future<void> _fetchAndInitialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await ProfileService.getProfile();
      _initializeWithData(profile);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String fullPhone =
          '$_selectedCountryCode ${_phoneController.text.trim()}';

      final updateData = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': fullPhone,
      };

      // Add role-specific fields
      if (_userRole == 'coach' && _bioController.text.trim().isNotEmpty) {
        updateData['bio'] = _bioController.text.trim();
      }

      await ProfileService.updateProfile(updateData);

      // Update local storage so Home Screen reflects changes immediately
      await AuthService.updateStoredUserData(
        _nameController.text.trim(),
        _userRole,
      );

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show image source bottom sheet
      final XFile? pickedFile =
          await StorageService.showImageSourceSheet(context);

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload to Firebase Storage
      final String downloadUrl = await StorageService.uploadProfilePicture(
        userId: _userId!,
        imageFile: File(pickedFile.path),
      );

      // Update profile with new image URL
      await ProfileService.updateProfileImage(downloadUrl);

      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 16,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).shadowColor.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Rounded Header Container
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 16,
              left: 24,
              right: 24,
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Edit
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : null,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                child: _profileImageUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.4),
                                      )
                                    : null,
                              ),
                              if (_isUploadingImage)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: GestureDetector(
                                  onTap: _isUploadingImage
                                      ? null
                                      : _changeProfilePhoto,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _isUploadingImage
                                          ? Colors.grey
                                          : AppPalette.orangeAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _changeProfilePhoto,
                            child: Text(
                              'Change Profile Photo',
                              style: GoogleFonts.inter(
                                color: AppPalette.orangeAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Personal Information
                    Text(
                      "Personal Information",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Full Name",
                      _nameController,
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),

                    if (_userRole == 'coach') ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Bio",
                        _bioController,
                        maxLines: 4,
                        validator: null, // Optional field
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Contact Details
                    Text(
                      "Contact Details",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Email Address",
                      _emailController,
                      icon: Icons.email_outlined,
                      readOnly: true, // Email cannot be changed
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 16),
                    _buildPhoneField(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          // Fixed Continue Button at Bottom
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Continue',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: labelColor.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: _phoneFieldKey,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          color:
                              isDark ? AppPalette.elevatedDark : Colors.white,
                          child: Container(
                            width: fieldWidth,
                            constraints: const BoxConstraints(maxHeight: 260),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.1),
                              ),
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.1),
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
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              // Phone Number Input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(
                    color: labelColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    hintText: 'Phone number',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: labelColor.withValues(alpha: 0.3),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            readOnly: readOnly,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).cardColor,
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
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: icon != null
                  ? Icon(
                      icon,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      size: 20,
                    )
                  : null,
            ),
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
