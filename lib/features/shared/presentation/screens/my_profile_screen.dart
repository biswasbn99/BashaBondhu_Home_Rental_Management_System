import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/validators.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../widgets/app_bar.dart';
import '../widgets/language_action_button.dart';
import '../widgets/decorated_section_header.dart';

class MyProfileScreen extends StatefulWidget {
  static const String name = '/my-profile';

  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  String? _selectedGender;
  DateTime? _selectedDob;
  String _profileImage = '';
  String _nidFrontImage = '';
  String _nidBackImage = '';

  bool _isSaving = false;
  bool _initialized = false;

  static const Color _grey = Color(0xFF7A8A88);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context).user;

    if (!_initialized) {
      _firstNameController = TextEditingController(text: user?.firstName ?? '');
      _middleNameController = TextEditingController(text: user?.middleName ?? '');
      _lastNameController = TextEditingController(text: user?.lastName ?? '');
      _phoneController = TextEditingController(text: user?.mobile ?? '');

      _selectedGender = (user?.gender != null && user!.gender.isNotEmpty) ? user.gender : null;
      if (user?.dateOfBirth != null && user!.dateOfBirth.isNotEmpty) {
        _selectedDob = DateTime.tryParse(user.dateOfBirth);
      }
      _profileImage = user?.profileImageUrl ?? '';
      _nidFrontImage = user?.nidFrontImageUrl ?? '';
      _nidBackImage = user?.nidBackImageUrl ?? '';

      _initialized = true;
    } else if (user != null) {
      // Re-sync controllers if they were initialized with empty data before user loaded
      if (_firstNameController.text.isEmpty && user.firstName.isNotEmpty) {
        _firstNameController.text = user.firstName;
      }
      if (_lastNameController.text.isEmpty && user.lastName.isNotEmpty) {
        _lastNameController.text = user.lastName;
      }
      if (_phoneController.text.isEmpty && user.mobile.isNotEmpty) {
        _phoneController.text = user.mobile;
      }
      if (_profileImage.isEmpty && user.profileImageUrl.isNotEmpty) {
        _profileImage = user.profileImageUrl;
      }
      if (_nidFrontImage.isEmpty && user.nidFrontImageUrl.isNotEmpty) {
        _nidFrontImage = user.nidFrontImageUrl;
      }
      if (_nidBackImage.isEmpty && user.nidBackImageUrl.isNotEmpty) {
        _nidBackImage = user.nidBackImageUrl;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Calculates dynamic live completion score (0 - 100%)
  int _calculateLiveCompletion() {
    int score = 0;
    if (_firstNameController.text.trim().isNotEmpty) score += 15;
    if (_lastNameController.text.trim().isNotEmpty) score += 15;
    if (_phoneController.text.trim().isNotEmpty) score += 15;
    if (_profileImage.trim().isNotEmpty) score += 15;
    if (_selectedGender != null && _selectedGender!.isNotEmpty) score += 10;
    if (_selectedDob != null) score += 10;
    if (_nidFrontImage.trim().isNotEmpty) score += 10;
    if (_nidBackImage.trim().isNotEmpty) score += 10;
    return score.clamp(0, 100);
  }

  // --- Photo Pickers ---
  Future<void> _pickProfilePhoto() async {
    final source = await _showImageSourceBottomSheet();
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
        setState(() {
          _profileImage = dataUri;
        });
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  Future<void> _pickNidImage({required bool isFront}) async {
    final source = await _showImageSourceBottomSheet();
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
        setState(() {
          if (isFront) {
            _nidFrontImage = dataUri;
          } else {
            _nidBackImage = dataUri;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking NID image: $e');
    }
  }

  Future<ImageSource?> _showImageSourceBottomSheet() {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                l10n.updatePhoto,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.photo_library_outlined, color: AppColors.themeColor),
                ),
                title: Text(l10n.chooseFromGallery, style: const TextStyle(fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(Icons.camera_alt_outlined, color: Colors.teal),
                ),
                title: Text(l10n.takePhoto, style: const TextStyle(fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final initialDate = _selectedDob ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)), // at least 10 yrs
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.themeColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ব্যবহারকারী তথ্য পাওয়া যায়নি। অনুগ্রহ করে সাইন ইন করুন।'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedUser = currentUser.copyWith(
        firstName: _firstNameController.text.trim().isNotEmpty
            ? _firstNameController.text.trim()
            : currentUser.firstName,
        middleName: _middleNameController.text.trim().isNotEmpty
            ? _middleNameController.text.trim()
            : currentUser.middleName,
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : currentUser.lastName,
        mobile: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : currentUser.mobile,
        gender: _selectedGender ?? currentUser.gender,
        dateOfBirth: _selectedDob != null ? _selectedDob!.toIso8601String() : currentUser.dateOfBirth,
        profileImageUrl: _profileImage,
        nidFrontImageUrl: _nidFrontImage,
        nidBackImageUrl: _nidBackImage,
      );

      await userProvider.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.localizations.profileUpdatedSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.localizations.localeName == 'bn' ? 'ত্রুটি ঘটেছে: $e' : 'Error occurred: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    final completion = _calculateLiveCompletion();
    final isComplete = completion >= 100;

    // Initials fallback
    final f = _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim()[0].toUpperCase() : '';
    final l = _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim()[0].toUpperCase() : '';
    final initials = (f + l).isNotEmpty ? (f + l) : (user?.initials ?? 'U');

    return Scaffold(
      appBar: MainAppBar(
        title: Text(l10n.myProfile),
        automaticallyImplyLeading: true,
        actions: const [
          LanguageActionButton(),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Top Profile Card with Avatar & Completion Badge ---
                _buildAvatarSection(theme, l10n, initials, completion, isComplete, user?.userType ?? ''),
                const SizedBox(height: 24),

                // --- Personal Information Section ---
                DecoratedSectionHeader(title: l10n.editPersonalInfo),
                const SizedBox(height: 14),

                // First Name
                _buildFieldLabel(l10n.firstName),
                const SizedBox(height: 6),
                _buildTextFormField(
                  controller: _firstNameController,
                  hint: l10n.firstName,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      return Validators.validateName(val);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Middle Name (Optional)
                _buildFieldLabel('${l10n.middleName} (${l10n.optional})'),
                const SizedBox(height: 6),
                _buildTextFormField(
                  controller: _middleNameController,
                  hint: l10n.middleName,
                  prefixIcon: Icons.badge_outlined,
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      return Validators.validateName(val);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Last Name
                _buildFieldLabel(l10n.lastName),
                const SizedBox(height: 6),
                _buildTextFormField(
                  controller: _lastNameController,
                  hint: l10n.lastName,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      return Validators.validateName(val);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Gender (Optional Dropdown)
                _buildFieldLabel('${l10n.gender} (${l10n.optional})'),
                const SizedBox(height: 6),
                _buildGenderDropdown(l10n),
                const SizedBox(height: 14),

                // Date of Birth (According to NID)
                _buildFieldLabel('${l10n.dateOfBirthNid} (${l10n.optional})'),
                const SizedBox(height: 6),
                _buildDobSelector(theme, l10n),
                const SizedBox(height: 14),

                // Phone Number
                _buildFieldLabel(l10n.mobile),
                const SizedBox(height: 6),
                _buildTextFormField(
                  controller: _phoneController,
                  hint: l10n.enterMobile,
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      return Validators.validatePhoneNumber(val);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- NID Verification Section ---
                DecoratedSectionHeader(title: l10n.uploadNid),
                const SizedBox(height: 14),

                // NID Front Side
                _buildFieldLabel(l10n.nidFrontTitle),
                const SizedBox(height: 8),
                _buildNidUploadBox(
                  imageSrc: _nidFrontImage,
                  hint: l10n.nidFrontHint,
                  icon: Icons.credit_card_rounded,
                  onPick: () => _pickNidImage(isFront: true),
                  onRemove: () => setState(() => _nidFrontImage = ''),
                ),
                const SizedBox(height: 16),

                // NID Back Side
                _buildFieldLabel(l10n.nidBackTitle),
                const SizedBox(height: 8),
                _buildNidUploadBox(
                  imageSrc: _nidBackImage,
                  hint: l10n.nidBackHint,
                  icon: Icons.flip_to_back_rounded,
                  onPick: () => _pickNidImage(isFront: false),
                  onRemove: () => setState(() => _nidBackImage = ''),
                ),
                const SizedBox(height: 28),

                // --- Save Changes Button ---
                FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.saveProfile,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // WIDGET BUILDERS
  // ==========================================================================

  Widget _buildAvatarSection(
    ThemeData theme,
    AppLocalizations l10n,
    String initials,
    int completion,
    bool isComplete,
    String userType,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.themeColor.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with edit button overlay
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _profileImage.isEmpty
                        ? LinearGradient(
                            colors: userType == 'House Owner'
                                ? [const Color(0xFF00A896), const Color(0xFF028090)]
                                : [const Color(0xFF028090), const Color(0xFF00A896)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.themeColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _profileImage.isNotEmpty
                        ? _buildImageWidget(_profileImage, 100, 100)
                        : Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickProfilePhoto,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // User Name & Role
          Text(
            "${_firstNameController.text} ${_lastNameController.text}".trim().isNotEmpty
                ? "${_firstNameController.text} ${_lastNameController.text}".trim()
                : (userType.isNotEmpty
                    ? (l10n.localeName == 'bn'
                        ? (userType == 'House Owner' ? 'বাড়িওয়ালা' : (userType == 'Tenant' ? 'ভাড়াটিয়া' : userType))
                        : userType)
                    : l10n.myProfile),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.localeName == 'bn'
                ? (userType == 'House Owner' ? 'বাড়িওয়ালা' : (userType == 'Tenant' ? 'ভাড়াটিয়া' : userType))
                : userType,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : _grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // Completion Progress Bar & Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : const Color(0xFFF6F8F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isComplete ? Icons.verified_rounded : Icons.info_outline_rounded,
                          size: 18,
                          color: isComplete ? Colors.green : Colors.amber.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.profileCompletion,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isComplete ? Colors.green : Colors.amber.shade700).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isComplete ? Colors.green : Colors.amber.shade700).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        isComplete
                            ? '${'100'.toLocalizedDigits(l10n.localeName)}% ${l10n.complete}'
                            : '${completion.toLocalizedDigits(l10n.localeName)}% ${l10n.incomplete}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isComplete ? Colors.green : Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completion / 100,
                    minHeight: 7,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? Colors.green : AppColors.themeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: _grey, size: 20),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.themeColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      decoration: InputDecoration(
        hintText: l10n.gender,
        prefixIcon: const Icon(Icons.wc_outlined, color: _grey, size: 20),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.themeColor, width: 1.5),
        ),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.gender)),
        DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
        DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
        DropdownMenuItem(value: 'Other', child: Text(l10n.other)),
      ],
      onChanged: (val) => setState(() => _selectedGender = val),
    );
  }

  Widget _buildDobSelector(ThemeData theme, AppLocalizations l10n) {
    final String formattedDate = _selectedDob != null
        ? "${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}"
        : l10n.selectDate;

    return InkWell(
      onTap: _pickDateOfBirth,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: _grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedDob != null ? theme.textTheme.bodyMedium?.color : _grey,
                  fontWeight: _selectedDob != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: _grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNidUploadBox({
    required String imageSrc,
    required String hint,
    required IconData icon,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (imageSrc.isNotEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageWidget(imageSrc, double.infinity, 180),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                      onPressed: onPick,
                      tooltip: l10n.change,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                      onPressed: onRemove,
                      tooltip: l10n.remove,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 130,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            style: BorderStyle.solid,
            width: 1.3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.themeColor.withValues(alpha: 0.1),
              radius: 24,
              child: Icon(icon, color: AppColors.themeColor, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              hint,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String src, double width, double height) {
    if (src.isEmpty) {
      return const Center(child: Icon(Icons.image_not_supported_outlined, size: 40));
    }
    if (src.startsWith('data:image') || src.startsWith('/9j/') || src.startsWith('iVBOR') || src.length > 255) {
      try {
        final base64Str = src.contains(',') ? src.split(',').last : src;
        return Image.memory(
          base64Decode(base64Str.trim()),
          width: width,
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image_rounded, size: 40));
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
      );
    } else {
      try {
        if (src.length <= 255 && !kIsWeb && File(src).existsSync()) {
          return Image.file(
            File(src),
            width: width,
            height: height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
          );
        }
      } catch (_) {}
      return const Center(child: Icon(Icons.broken_image_rounded, size: 40));
    }
  }
}