import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/providers/locale_provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/forgot_password_dialog.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/services/auth_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/language_action_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    this.preSelectedUserType,
    this.lockUserType = false,
  });

  final String? preSelectedUserType;
  final bool lockUserType;

  static const String name = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _selectedUserType;
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  final TextEditingController _emailTEController = TextEditingController();
  final TextEditingController _passwordTEController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedUserType != null && widget.preSelectedUserType!.isNotEmpty) {
      _selectedUserType = widget.preSelectedUserType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final localeProvider = context.watch<LocaleProvider>();
    final isBn = localeProvider.currentLocale.languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'লগইন করুন' : l10n.signIn),
        actions: const [
          LanguageActionButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const AppLogo(width: 95, height: 95),
                  const SizedBox(height: 16),
                  Text(
                    isBn ? 'লগইন করুন' : l10n.signIn,
                    style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn ? 'এগিয়ে যেতে আপনার তথ্য প্রদান করুন' : l10n.signInSubTitle,
                    style: context.textTheme.labelLarge,
                  ),

                  const SizedBox(height: 24),

                  // Role Selection / Locked Badge
                  if (widget.lockUserType && _selectedUserType != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedUserType == 'House Owner'
                                ? Icons.home_work_rounded
                                : Icons.person_pin_circle_rounded,
                            color: AppColors.themeColor,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBn ? 'অ্যাকাউন্টের ধরণ' : l10n.lockedRoleLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedUserType == 'House Owner'
                                      ? (isBn ? 'বাড়িওয়ালা (House Owner)' : 'House Owner')
                                      : (isBn ? 'ভাড়াটিয়া (Tenant)' : 'Tenant'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: isBn ? 'এই ভূমিকাটি লক করা আছে' : l10n.roleLockedTooltip,
                            child: const Icon(Icons.lock_rounded, size: 18, color: AppColors.themeColor),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUserType,
                      decoration: InputDecoration(
                        hintText: isBn ? 'ব্যবহারকারীর ধরণ নির্বাচন করুন' : 'Select User Type',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'House Owner',
                          child: Text(isBn ? 'বাড়িওয়ালা (House Owner)' : 'House Owner'),
                        ),
                        DropdownMenuItem(
                          value: 'Tenant',
                          child: Text(isBn ? 'ভাড়াটিয়া (Tenant)' : 'Tenant'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUserType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isBn ? 'দয়া করে অ্যাকাউন্টের ধরণ নির্বাচন করুন' : 'Please select a user type';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailTEController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: isBn ? 'ইমেইল এড্রেস' : 'Email',
                      labelText: isBn ? 'ইমেইল' : 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isBn ? 'দয়া করে আপনার ইমেইল প্রদান করুন' : 'Please enter your email';
                      }
                      if (!EmailValidator.validate(value.trim())) {
                        return isBn ? 'সঠিক ইমেইল এড্রেস লিখুন' : 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordTEController,
                    textInputAction: TextInputAction.done,
                    obscureText: _isPasswordObscured,
                    obscuringCharacter: '*',
                    decoration: InputDecoration(
                      hintText: isBn ? 'পাসওয়ার্ড' : 'Password',
                      labelText: isBn ? 'পাসওয়ার্ড' : 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isBn ? 'দয়া করে পাসওয়ার্ড প্রদান করুন' : 'Enter your password';
                      }
                      if (value.length < 6) {
                        return isBn ? 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে' : 'Enter a password more than 6 letters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ForgotPasswordDialog.show(
                          context,
                          initialEmail: _emailTEController.text.trim(),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isBn ? 'পাসওয়ার্ড ভুলে গেছেন?' : 'Forgot Password?',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.themeColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : () => _onTapSignInButton(isBn),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(isBn ? 'লগইন করুন' : l10n.signIn),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isBn ? 'কোনো অ্যাকাউন্ট নেই?' : l10n.doNotHaveAnAccount,
                        style: context.textTheme.labelLarge,
                      ),
                      TextButton(
                        onPressed: _onTapSignUpNavigation,
                        child: Text(isBn ? 'রেজিস্ট্রেশন করুন' : l10n.signUp),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTapSignInButton(bool isBn) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final credential = await AuthService().signIn(
          email: _emailTEController.text.trim(),
          password: _passwordTEController.text,
        );

        if (credential?.user != null) {
          final userType = await AuthService().getUserType(credential!.user!.uid);
          
          if (!mounted) return;

          if (userType == _selectedUserType) {
            // Explicitly ensure user data and subscription status are loaded
            await context.read<UserProvider>().fetchUserData(credential.user!.uid);

            if (!mounted) return;

            // Reset nav index before popping
            context.read<MainNavHolderProvider>().resetIndex();
            
            if (mounted) {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          } else {
            await AuthService().signOut();
            if (mounted) {
              final regRole = userType == 'House Owner'
                  ? (isBn ? 'বাড়িওয়ালা (House Owner)' : 'House Owner')
                  : (isBn ? 'ভাড়াটিয়া (Tenant)' : 'Tenant');
              final selRole = _selectedUserType == 'House Owner'
                  ? (isBn ? 'বাড়িওয়ালা (House Owner)' : 'House Owner')
                  : (isBn ? 'ভাড়াটিয়া (Tenant)' : 'Tenant');

              final message = isBn
                  ? 'অননুমোদিত প্রবেশ। আপনি $regRole হিসেবে নিবন্ধিত, কিন্তু $selRole হিসেবে লগইন করতে চেয়েছেন।'
                  : 'Unauthorized access. You are registered as $regRole, but trying to log in as $selRole.';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        final errorMessage = _getLocalizedAuthErrorMessage(e, isBn);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        final errorStr = isBn
            ? 'লগইন ব্যর্থ হয়েছে। আপনার ইমেইল ও পাসওয়ার্ড যাচাই করে আবার চেষ্টা করুন।'
            : 'Login failed. Please verify your email and password and try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorStr),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _getLocalizedAuthErrorMessage(FirebaseAuthException e, bool isBn) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return isBn
            ? 'ভুল ইমেইল বা পাসওয়ার্ড প্রদান করেছেন। দয়া করে সঠিক তথ্য দিন।'
            : 'Incorrect email or password. Please check your credentials and try again.';
      case 'invalid-email':
        return isBn
            ? 'ইমেইল ঠিকানাটি সঠিক নয়।'
            : 'The email address is invalid.';
      case 'user-disabled':
        return isBn
            ? 'এই ব্যবহারকারীর অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে। সহায়তার জন্য যোগাযোগ করুন।'
            : 'This user account has been disabled. Please contact support.';
      case 'too-many-requests':
        return isBn
            ? 'অতিরিক্ত ভুল চেষ্টার কারণে সাময়িকভাবে বন্ধ করা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।'
            : 'Too many unsuccessful attempts. Please try again later.';
      case 'network-request-failed':
        return isBn
            ? 'ইন্টারনেট সংযোগে সমস্যা হচ্ছে। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।'
            : 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return isBn
            ? 'এই মাধ্যমে লগইন বর্তমানে বন্ধ রয়েছে।'
            : 'Sign-in with email and password is not enabled.';
      default:
        return isBn
            ? 'ভুল ইমেইল বা পাসওয়ার্ড প্রদান করেছেন। দয়া করে সঠিক তথ্য দিন।'
            : (e.message ?? 'Login failed. Please check your credentials and try again.');
    }
  }

  void _onTapSignUpNavigation() {
    Navigator.pushReplacementNamed(
      context,
      SignUpScreen.name,
      arguments: {
        'preSelectedUserType': _selectedUserType ?? widget.preSelectedUserType,
        'lockUserType': widget.lockUserType,
      },
    );
  }

  @override
  void dispose() {
    _emailTEController.dispose();
    _passwordTEController.dispose();
    super.dispose();
  }
}