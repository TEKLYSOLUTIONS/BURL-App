import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../config/palette.dart';
import '../../services/profile_service.dart';
import '../../services/guardian_service.dart';
import '../../services/storage_service.dart';
import '../../utils/country_codes.dart';

// ── Google Places API Key (same as AndroidManifest)
const _kMapsApiKey = 'AIzaSyA49gBcEHS6benjXtwA2rakOLejlmDFd-0';

class GuardianEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const GuardianEditProfileScreen({super.key, this.profileData});

  @override
  State<GuardianEditProfileScreen> createState() =>
      _GuardianEditProfileScreenState();
}

class _GuardianEditProfileScreenState extends State<GuardianEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressFocus = FocusNode();

  String _selectedCountryCode = '+94'; // Default to Sri Lanka
  final _phoneFieldKey = GlobalKey();

  bool _isLoading = false;
  bool _isSaving = false;

  // Map / location state
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isDetectingLocation = false;

  // Places autocomplete state
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  bool _fetchingSuggestions = false;

  String? _profileImageUrl;
  String? _userId;

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
        // Delay hiding suggestions slightly so any tap on a suggestion
        // has time to register before the widget is removed from the tree.
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  void _initializeWithData(Map<String, dynamic> data) {
    _nameController.text = data['fullName'] ?? '';
    _emailController.text = data['email'] ?? '';
    // Split phone number if it contains a country code
    String phone = data['phone'] ?? data['phoneNumber'] ?? '';
    if (phone.startsWith('+')) {
      // Find the first space, or just use common lengths if no space.
      // Easiest is to check against known codes we support, or just take the first part if space exists.
      if (phone.startsWith('+94')) {
        _selectedCountryCode = '+94';
        phone = phone.substring(3).trim();
      } else if (phone.startsWith('+1')) {
        _selectedCountryCode = '+1';
        phone = phone.substring(2).trim();
      } else if (phone.startsWith('+44')) {
        _selectedCountryCode = '+44';
        phone = phone.substring(3).trim();
      } else if (phone.startsWith('+61')) {
        _selectedCountryCode = '+61';
        phone = phone.substring(3).trim();
      } else if (phone.contains(' ')) {
        final parts = phone.split(' ');
        _selectedCountryCode = parts.first;
        phone = parts.skip(1).join(' ');
      }
    }
    _phoneController.text = phone;

    _profileImageUrl =
        data['profileUrl'] ?? data['profilePhoto'] ?? data['profileImage'];
    _userId = data['_id'] ?? data['id'];

    final guardianProfile = data['guardianProfile'] as Map<String, dynamic>?;
    if (guardianProfile != null) {
      _addressController.text = guardianProfile['address'] ?? '';
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _addressFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Places Autocomplete ───────────────────────────────────────────────────

  Future<void> _onAddressChanged() async {
    final query = _addressController.text.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _fetchingSuggestions = true);

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=$_kMapsApiKey',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List<dynamic>? ?? [];
        setState(() {
          _suggestions = predictions
              .map((p) => {
                    'placeId': p['place_id'] as String,
                    'description': p['description'] as String,
                    'mainText':
                        p['structured_formatting']?['main_text'] as String? ??
                            p['description'],
                    'secondaryText': p['structured_formatting']
                            ?['secondary_text'] as String? ??
                        '',
                  })
              .toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _fetchingSuggestions = false);
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final description = suggestion['description'] as String;
    debugPrint('Selecting suggestion: $description');

    _addressController.removeListener(_onAddressChanged);
    _addressController.text = description;
    _addressController.addListener(_onAddressChanged);

    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _addressFocus.unfocus();

    // Geocode to get lat/lng for map preview
    await _geocodeAddress(suggestion['placeId'] as String, description);
  }

  Future<void> _geocodeAddress(String placeId, String address) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=$_kMapsApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loc = data['result']?['geometry']?['location'];
        if (loc != null) {
          final latlng = LatLng(loc['lat'] as double, loc['lng'] as double);
          setState(() => _selectedLocation = latlng);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(latlng, 15),
          );
        }
      }
    } catch (_) {}
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final String fullPhone =
          '$_selectedCountryCode ${_phoneController.text.trim()}';

      await ProfileService.updateProfile({
        'fullName': _nameController.text.trim(),
        'phone': fullPhone,
      });
      await GuardianService().updateGuardianProfile({
        'address': _addressController.text.trim(),
        'phoneNumber': fullPhone,
      });
      if (mounted) {
        _showSnack('Profile updated successfully!', isError: false);
        context.pop(true);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppPalette.error : AppPalette.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    if (_userId == null) {
      if (mounted) {
        _showSnack('User ID not found. Please try again.', isError: true);
      }
      return;
    }

    try {
      final pickedFile = await StorageService.showImageSourceSheet(context);
      if (pickedFile == null) return;

      setState(() => _isSaving = true);

      final imageUrl = await StorageService.uploadProfilePicture(
        userId: _userId!,
        imageFile: File(pickedFile.path),
      );

      setState(() {
        _profileImageUrl = imageUrl;
        _isSaving = false;
      });

      await ProfileService.updateProfile({'profileUrl': imageUrl});

      if (mounted) {
        _showSnack('Profile photo updated successfully!', isError: false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) _showSnack('Error uploading photo: $e', isError: true);
    }
  }

  Future<void> _autoDetectLocation() async {
    if (!mounted) return;
    setState(() => _isDetectingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isDetectingLocation = false);
        return;
      }

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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final addressParts = <String>[];
        if (placemark.street?.isNotEmpty == true) {
          addressParts.add(placemark.street!);
        }
        if (placemark.locality?.isNotEmpty == true) {
          addressParts.add(placemark.locality!);
        }
        if (placemark.administrativeArea?.isNotEmpty == true) {
          addressParts.add(placemark.administrativeArea!);
        }
        if (placemark.country?.isNotEmpty == true) {
          addressParts.add(placemark.country!);
        }

        final city = addressParts.join(', ');

        setState(() {
          if (city.isNotEmpty) {
            _addressController.removeListener(_onAddressChanged);
            _addressController.text = city;
            _addressController.addListener(_onAddressChanged);
          }
        });

        // Also move the map
        final latlng = LatLng(position.latitude, position.longitude);
        setState(() => _selectedLocation = latlng);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latlng, 15),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
            'Could not detect location automatically. Please enter manually.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final labelColor =
        isDark ? AppPalette.textPrimaryDark : AppPalette.textPrimaryLight;
    final subColor =
        isDark ? AppPalette.textSecondaryDark : AppPalette.textSecondaryLight;
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(labelColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _showSuggestions = false);
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(labelColor),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                _buildAvatar(isDark).animate().fadeIn(delay: 50.ms),
                const SizedBox(height: 32),

                // Personal Info
                _buildSectionLabel('PERSONAL INFORMATION', subColor),
                const SizedBox(height: 12),
                _buildField(
                  label: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  labelColor: labelColor,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 28),

                // Contact
                _buildSectionLabel('CONTACT DETAILS', subColor),
                const SizedBox(height: 12),
                _buildField(
                  label: 'Email Address',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  labelColor: labelColor,
                  readOnly: true,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildPhoneField(
                  isDark: isDark,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  labelColor: labelColor,
                ),
                const SizedBox(height: 28),

                // Address
                _buildSectionLabel('HOME ADDRESS', subColor),
                const SizedBox(height: 12),

                // Address field + overlay dropdown
                _buildAddressFieldWithOverlay(
                  isDark: isDark,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  labelColor: labelColor,
                  subColor: subColor,
                ),

                // Map preview after selection
                if (_selectedLocation != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 190,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation!,
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('sel'),
                            position: _selectedLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueOrange,
                            ),
                          ),
                        },
                        onMapCreated: (c) => _mapController = c,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                    ),
                  ).animate().fadeIn().scale(
                        begin: const Offset(0.95, 0.95),
                      ),
                ],
                const SizedBox(height: 36),

                // Save
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.orangeAccent,
                      disabledBackgroundColor:
                          AppPalette.orangeAccent.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressFieldWithOverlay({
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Home Address label is already added above this widget
            // Add an auto-detect location button here
            TextButton.icon(
              onPressed: _isDetectingLocation ? null : _autoDetectLocation,
              icon: _isDetectingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppPalette.orangeAccent,
                      ),
                    )
                  : const Icon(Icons.my_location,
                      size: 18, color: AppPalette.orangeAccent),
              label: Text(
                'Auto-detect location',
                style: GoogleFonts.inter(
                  color: AppPalette.orangeAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Address text field
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _addressFocus.hasFocus
                  ? AppPalette.orangeAccent
                  : borderColor,
              width: _addressFocus.hasFocus ? 1.5 : 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Icon(
                  Icons.location_on_outlined,
                  color: _addressFocus.hasFocus
                      ? AppPalette.orangeAccent
                      : subColor.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  focusNode: _addressFocus,
                  style: GoogleFonts.inter(
                    color: labelColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search address…',
                    hintStyle: GoogleFonts.inter(
                      color: subColor.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              if (_fetchingSuggestions)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppPalette.orangeAccent,
                    ),
                  ),
                )
              else if (_addressController.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: subColor.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    _addressController.clear();
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                      _selectedLocation = null;
                    });
                  },
                ),
            ],
          ),
        ),

        // Dropdown suggestions
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: isDark ? AppPalette.elevatedDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: borderColor,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, i) {
                final s = _suggestions[i];
                return Listener(
                  onPointerDown: (_) {
                    debugPrint('PointerDown on suggestion index $i');
                    _selectSuggestion(s);
                  },
                  child: InkWell(
                    onTap: () {}, // Handled by Listener
                    borderRadius: i == 0
                        ? const BorderRadius.vertical(top: Radius.circular(14))
                        : i == _suggestions.length - 1
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(14))
                            : BorderRadius.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppPalette.orangeAccent
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_pin,
                              size: 16,
                              color: AppPalette.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['mainText'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: labelColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if ((s['secondaryText'] as String).isNotEmpty)
                                  Text(
                                    s['secondaryText'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: subColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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

        if (!_showSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              'Type to search and select from suggestions',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: subColor.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _changeProfilePhoto,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppPalette.orangeAccent, width: 3),
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage:
                    _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 2,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppPalette.orangeAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppPalette.backgroundDark : Colors.white,
                    width: 2,
                  ),
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
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
        Text(
          'Phone Number',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: labelColor,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: _phoneFieldKey,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
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
                              border: Border.all(color: borderColor),
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1, color: borderColor),
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
                color: borderColor,
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
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.3),
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

  AppBar _buildAppBar(Color labelColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: labelColor),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Edit Profile',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: labelColor,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSectionLabel(String text, Color subColor) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: subColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color labelColor,
    IconData? icon,
    Widget? prefixWidget,
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
            color: labelColor,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.inter(
              color: readOnly ? labelColor.withValues(alpha: 0.4) : labelColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: prefixWidget ??
                  (icon != null
                      ? Icon(
                          icon,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.grey[400],
                          size: 20,
                        )
                      : null),
            ),
          ),
        ),
      ],
    );
  }
}
