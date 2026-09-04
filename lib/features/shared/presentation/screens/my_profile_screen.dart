import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/validators.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../widgets/app_bar.dart';
import '../widgets/full_screen_image_viewer.dart';
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
  bool _isSubmittingVerification = false;
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

      _firstNameController.addListener(_onFieldChanged);
      _middleNameController.addListener(_onFieldChanged);
      _lastNameController.addListener(_onFieldChanged);
      _phoneController.addListener(_onFieldChanged);

      _selectedGender = (user?.gender != null && user!.gender.isNotEmpty) ? user.gender : null;
      if (user?.dateOfBirth != null && user!.dateOfBirth.isNotEmpty) {
        _selectedDob = DateTime.tryParse(user.dateOfBirth);
      }
      _profileImage = user?.profileImageUrl ?? '';
      _nidFrontImage = user?.nidFrontImageUrl ?? '';
      _nidBackImage = user?.nidBackImageUrl ?? '';

      _initialized = true;
    } else if (user != null) {
      // Re-sync controllers and state if they were initialized with empty data before user loaded
      if (_firstNameController.text.isEmpty && user.firstName.isNotEmpty) {
        _firstNameController.text = user.firstName;
      }
      if (_lastNameController.text.isEmpty && user.lastName.isNotEmpty) {
        _lastNameController.text = user.lastName;
      }
      if (_phoneController.text.isEmpty && user.mobile.isNotEmpty) {
        _phoneController.text = user.mobile;
      }
      if (_selectedGender == null && user.gender.isNotEmpty) {
        _selectedGender = user.gender;
      }
      if (_selectedDob == null && user.dateOfBirth.isNotEmpty) {
        _selectedDob = DateTime.tryParse(user.dateOfBirth);
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

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onFieldChanged);
    _middleNameController.removeListener(_onFieldChanged);
    _lastNameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);

    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Calculates dynamic live completion score (0 - 100%)
  int _calculateLiveCompletion() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    int score = 0;
    if (_firstNameController.text.trim().isNotEmpty || (user?.firstName.trim().isNotEmpty ?? false)) score += 15;
    if (_lastNameController.text.trim().isNotEmpty || (user?.lastName.trim().isNotEmpty ?? false)) score += 15;
    if (_phoneController.text.trim().isNotEmpty || (user?.mobile.trim().isNotEmpty ?? false)) score += 15;
    if (_profileImage.trim().isNotEmpty || (user?.profileImageUrl.trim().isNotEmpty ?? false)) score += 15;
    if ((_selectedGender != null && _selectedGender!.isNotEmpty) || (user?.gender.isNotEmpty ?? false)) score += 10;
    if (_selectedDob != null || (user?.dateOfBirth.isNotEmpty ?? false)) score += 10;
    if (_nidFrontImage.trim().isNotEmpty || (user?.nidFrontImageUrl.trim().isNotEmpty ?? false)) score += 10;
    if (_nidBackImage.trim().isNotEmpty || (user?.nidBackImageUrl.trim().isNotEmpty ?? false)) score += 10;
    return score.clamp(0, 100);
  }

  /// Profile is complete only when all 8 core verification fields are filled
  bool get _isProfileComplete {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final fn = _firstNameController.text.trim().isNotEmpty || (user?.firstName.trim().isNotEmpty ?? false);
    final ln = _lastNameController.text.trim().isNotEmpty || (user?.lastName.trim().isNotEmpty ?? false);
    final phone = _phoneController.text.trim().isNotEmpty || (user?.mobile.trim().isNotEmpty ?? false);
    final pImg = _profileImage.trim().isNotEmpty || (user?.profileImageUrl.trim().isNotEmpty ?? false);
    final gen = (_selectedGender != null && _selectedGender!.isNotEmpty) || (user?.gender.isNotEmpty ?? false);
    final dob = _selectedDob != null || (user?.dateOfBirth.isNotEmpty ?? false);
    final nidF = _nidFrontImage.trim().isNotEmpty || (user?.nidFrontImageUrl.trim().isNotEmpty ?? false);
    final nidB = _nidBackImage.trim().isNotEmpty || (user?.nidBackImageUrl.trim().isNotEmpty ?? false);

    return fn && ln && phone && pImg && gen && dob && nidF && nidB;
  }

  /// Returns missing profile fields list for user guidance
  List<String> _getMissingFields(bool isBn) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final List<String> missing = [];
    if (_firstNameController.text.trim().isEmpty && (user?.firstName.trim().isEmpty ?? true)) {
      missing.add(isBn ? 'নামের প্রথম অংশ' : 'First Name');
    }
    if (_lastNameController.text.trim().isEmpty && (user?.lastName.trim().isEmpty ?? true)) {
      missing.add(isBn ? 'নামের শেষ অংশ' : 'Last Name');
    }
    if (_phoneController.text.trim().isEmpty && (user?.mobile.trim().isEmpty ?? true)) {
      missing.add(isBn ? 'মোবাইল নম্বর' : 'Phone Number');
    }
    if (_profileImage.trim().isEmpty && (user?.profileImageUrl.trim().isEmpty ?? true)) {
      missing.add(isBn ? 'প্রোফাইল ছবি' : 'Profile Picture');
    }
    if ((_selectedGender == null || _selectedGender!.isEmpty) && (user?.gender.isEmpty ?? true)) {
      missing.add(isBn ? 'লিঙ্গ (Gender)' : 'Gender');
    }
    if (_selectedDob == null && (user?.dateOfBirth.isEmpty ?? true)) {
      missing.add(isBn ? 'জন্ম তারিখ (NID অনুযায়ী)' : 'Date of Birth');
    }
    if (_nidFrontImage.trim().isEmpty && (user?.nidFrontImageUrl.trim().isEmpty ?? true)) {
      missing.add(isBn ? 'এনআইডি ফ্রন্ট সাইড ছবি' : 'NID Front Photo');
    }
    if (_nidBackImage.trim().isEmpty && (user?.nidBackImageUrl.trim().isEmpty ?? true)) {
      missing.add(isBn ? 'এনআইডি ব্যাক সাইড ছবি' : 'NID Back Photo');
    }
    return missing;
  }

  Future<void> _pickProfileImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          setState(() {
            _profileImage = base64String;
          });
        } else {
          setState(() {
            _profileImage = pickedFile.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.localizations.localeName == 'bn' ? 'ছবি নির্বাচনে সমস্যা হয়েছে: $e' : 'Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickNidImage({required bool isFront}) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          setState(() {
            if (isFront) {
              _nidFrontImage = base64String;
            } else {
              _nidBackImage = base64String;
            }
          });
        } else {
          setState(() {
            if (isFront) {
              _nidFrontImage = pickedFile.path;
            } else {
              _nidBackImage = pickedFile.path;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.localizations.localeName == 'bn' ? 'এনআইডি ছবি নির্বাচনে সমস্যা হয়েছে: $e' : 'Failed to pick NID image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    final l10n = context.localizations;
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.localeName == 'bn' ? 'ছবি নির্বাচন করুন' : 'Select Image Source',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _saveProfile({bool showSuccessMessage = true}) async {
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

      if (mounted && showSuccessMessage) {
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

  Future<void> _submitForVerification() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    final isBn = context.localizations.localeName == 'bn';

    if (currentUser == null) return;

    if (_nidFrontImage.isEmpty && _nidBackImage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'অনুগ্রহ করে জাতীয় পরিচয়পত্রের (NID) ছবি যুক্ত করুন।' : 'Please upload your NID card photos first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.themeColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBn ? 'ভেরিফিকেশনের আবেদন নিশ্চিত করুন' : 'Submit for Verification',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
              ),
            ),
          ],
        ),
        content: Text(
          isBn
              ? 'আপনার প্রোফাইল ও জাতীয় পরিচয়পত্র (NID) অ্যাডমিনের নিকট পর্যালোচনার জন্য পাঠানো হবে। তথ্য যাচাই শেষে আপনার প্রোফাইলে ভেরিফাইড ব্যাজ যুক্ত হবে। আপনি কি নিশ্চিত?'
              : 'Your profile and NID will be submitted to the Admin for review. Once verified, a verified badge will be added to your profile. Do you want to submit?',
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isBn ? 'হ্যাঁ, আবেদন জমা দিন' : 'Yes, Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmittingVerification = true);

    try {
      // First save all latest field edits
      final updatedUser = currentUser.copyWith(
        firstName: _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : currentUser.firstName,
        middleName: _middleNameController.text.trim().isNotEmpty ? _middleNameController.text.trim() : currentUser.middleName,
        lastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : currentUser.lastName,
        mobile: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : currentUser.mobile,
        gender: _selectedGender ?? currentUser.gender,
        dateOfBirth: _selectedDob != null ? _selectedDob!.toIso8601String() : currentUser.dateOfBirth,
        profileImageUrl: _profileImage,
        nidFrontImageUrl: _nidFrontImage,
        nidBackImageUrl: _nidBackImage,
        verificationStatus: 'pending',
        verificationFeedback: '',
      );

      await userProvider.updateUserProfile(updatedUser);

      // Write to verification_requests collection so admin has a dedicated log
      try {
        await FirebaseFirestore.instance
            .collection('verification_requests')
            .doc(currentUser.uid)
            .set({
          'uid': currentUser.uid,
          'email': currentUser.email,
          'fullName': updatedUser.fullName,
          'mobile': updatedUser.mobile,
          'userType': updatedUser.userType,
          'profileImageUrl': updatedUser.profileImageUrl,
          'nidFrontImageUrl': updatedUser.nidFrontImageUrl,
          'nidBackImageUrl': updatedUser.nidBackImageUrl,
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Note: verification_requests log error: $e');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBn ? 'আবেদন সফল হয়েছে!' : 'Application Submitted!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: Text(
              isBn
                  ? 'আপনার প্রোফাইল ভেরিফিকেশন আবেদন সফলভাবে গ্রহণ করা হয়েছে। অ্যাডমিন শীঘ্রই আপনার তথ্য যাচাই করে স্ট্যাটাস আপডেট করবে।'
                  : 'Your verification request has been received. The administrator will review your information shortly.',
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
                onPressed: () => Navigator.pop(ctx),
                child: Text(isBn ? 'ঠিক আছে' : 'OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingVerification = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = l10n.localeName == 'bn';
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
                const SizedBox(height: 16),

                // --- Real-time Verification Status Banner ---
                _buildVerificationStatusCard(user, isDark, isBn),
                const SizedBox(height: 20),

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
                  isFront: true,
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
                  isFront: false,
                  onPick: () => _pickNidImage(isFront: false),
                  onRemove: () => setState(() => _nidBackImage = ''),
                ),
                const SizedBox(height: 28),

                // --- Action Buttons (Save Changes & Submit for Verification) ---
                FilledButton(
                  onPressed: _isSaving ? null : () => _saveProfile(showSuccessMessage: true),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.saveProfile,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),

                // Verify Profile Action Button (Enabled only when 100% profile information is complete)
                if (user != null && !user.isVerified && !user.isVerificationPending) ...[
                  const SizedBox(height: 14),

                  if (!_isProfileComplete) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBn
                                      ? 'প্রোফাইল ভেরিফিকেশন বাটন সক্রিয় করতে সকল তথ্য পূরণ করুন:'
                                      : 'Complete all fields to enable profile verification:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getMissingFields(isBn).map((f) => '• $f').join('\n'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  ElevatedButton.icon(
                    onPressed: (_isSubmittingVerification)
                        ? null
                        : (!_isProfileComplete)
                            ? () {
                                final missing = _getMissingFields(isBn);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isBn
                                          ? 'ভেরিফিকেশনের জন্য আগে সকল তথ্য (${missing.join(", ")}) পূরণ করুন।'
                                          : 'Please complete all fields (${missing.join(", ")}) before submitting.',
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            : _submitForVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProfileComplete
                          ? const Color(0xFF10B981)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                      foregroundColor: _isProfileComplete
                          ? Colors.white
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: _isProfileComplete ? 2 : 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSubmittingVerification
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            _isProfileComplete ? Icons.verified_user_rounded : Icons.lock_outline_rounded,
                            size: 20,
                          ),
                    label: Text(
                      isBn
                          ? (_isProfileComplete ? '🛡️ ভেরিফাই প্রোফাইল (এডমিনে পাঠান)' : '🛡️ ভেরিফাই প্রোফাইল (তথ্য অসম্পূর্ণ)')
                          : (_isProfileComplete ? '🛡️ Verify Profile (Submit to Admin)' : '🛡️ Verify Profile (Incomplete)'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // VERIFICATION STATUS BANNER
  // ==========================================================================

  Widget _buildVerificationStatusCard(UserModel? user, bool isDark, bool isBn) {
    if (user == null) return const SizedBox.shrink();

    if (user.isVerified) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.45 : 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? '✓ ভেরিফাইড প্রোফাইল (Verified Account)' : '✓ Verified Account',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isBn
                        ? 'আপনার জাতীয় পরিচয়পত্র (NID) সফলভাবে ভেরিফাইড হয়েছে। আপনার বিজ্ঞাপনে ভেরিফাইড ব্যাজ সক্রিয়।'
                        : 'Your National ID (NID) has been verified by the administrator. Verified badge is active.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (user.isVerificationPending) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade700.withValues(alpha: isDark ? 0.5 : 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade800,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? '⏳ ভেরিফিকেশন অপেক্ষমান (Under Review)' : '⏳ Verification Under Review',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isBn
                        ? 'আপনার তথ্য ও এনআইডি ছবি অ্যাডমিনের পর্যালোচনার জন্য জমা রয়েছে। খুব দ্রুত যাচাই করা হবে।'
                        : 'Your documents are currently being reviewed by the admin. Verification status will update soon.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (user.isVerificationRejected) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withValues(alpha: isDark ? 0.5 : 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? '⚠️ তথ্যে সংশোধন প্রয়োজন (Action Required)' : '⚠️ Correction Required',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: Colors.redAccent,
                    ),
                  ),
                  if (user.verificationFeedback.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      isBn ? 'অ্যাডমিন মেসেজ: ${user.verificationFeedback}' : 'Admin Feedback: ${user.verificationFeedback}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    isBn
                        ? 'সঠিক তথ্য বা পরিষ্কার NID ছবি আপলোড করে পুনরায় আবেদন জমা দিন।'
                        : 'Please update your details or re-upload clear NID images and submit again.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162B27) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF22443D) : const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[400],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'প্রোফাইল অ-ভেরিফাইড (Unverified Profile)' : 'Unverified Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isBn
                        ? 'এনআইডি ছবি ও প্রয়োজনীয় তথ্য সম্পূর্ণ করে ভেরিফিকেশনের জন্য আবেদন করুন।'
                        : 'Complete your profile information and upload NID photos to submit for verification.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
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
    final isBn = l10n.localeName == 'bn';

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
          // Avatar with edit button overlay and Zoom onTap
          Center(
            child: Stack(
              children: [
                InkWell(
                  onTap: _profileImage.isNotEmpty
                      ? () => FullScreenImageViewer.show(
                            context,
                            images: [_profileImage],
                            title: isBn ? 'প্রোফাইল ছবি' : 'Profile Photo',
                          )
                      : null,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
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
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: AppColors.themeColor,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickProfileImage,
                      child: const Padding(
                        padding: EdgeInsets.all(7.0),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // User Type Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              userType.isNotEmpty ? userType : (isBn ? 'ভাড়াটিয়া' : 'Tenant'),
              style: const TextStyle(
                color: AppColors.themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Completion Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.profileCompletion,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  if (isComplete) ...[
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '$completion%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isComplete ? const Color(0xFF10B981) : AppColors.themeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completion / 100.0,
              minHeight: 7,
              backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFF10B981) : AppColors.themeColor,
              ),
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
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _grey,
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
      onChanged: (_) => setState(() {}), // Trigger live completion recalc
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: _grey, size: 20),
      ),
    );
  }

  Widget _buildGenderDropdown(AppLocalizations l10n) {
    final isBn = l10n.localeName == 'bn';
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.wc_rounded, color: _grey, size: 20),
      ),
      hint: Text(isBn ? 'লিঙ্গ নির্বাচন করুন' : 'Select Gender'),
      items: [
        DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
        DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
        DropdownMenuItem(value: 'Other', child: Text(l10n.other)),
      ],
      onChanged: (val) {
        setState(() {
          _selectedGender = val;
        });
      },
    );
  }

  Widget _buildDobSelector(ThemeData theme, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = _selectedDob != null
        ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
        : l10n.selectDate;

    return InkWell(
      onTap: _pickDateOfBirth,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : const Color(0xFFF9FBFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : const Color(0xFFD6E2E0),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: _grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _selectedDob != null ? FontWeight.w600 : FontWeight.normal,
                  color: _selectedDob != null ? theme.textTheme.bodyMedium?.color : _grey,
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
    required bool isFront,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final l10n = context.localizations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBn = l10n.localeName == 'bn';

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
            InkWell(
              onTap: () {
                FullScreenImageViewer.show(
                  context,
                  images: [
                    imageSrc,
                    if (isFront && _nidBackImage.isNotEmpty) _nidBackImage,
                    if (!isFront && _nidFrontImage.isNotEmpty) _nidFrontImage,
                  ],
                  initialIndex: 0,
                  title: isFront ? (isBn ? 'জাতীয় পরিচয়পত্র (সামনে)' : 'NID Front Side') : (isBn ? 'জাতীয় পরিচয়পত্র (পেছনে)' : 'NID Back Side'),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImageWidget(imageSrc, double.infinity, 180),
              ),
            ),
            // Zoom Prompt
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      isBn ? 'জুম করে দেখুন' : 'Tap to Zoom',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            // Action Buttons (Change & Delete)
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
