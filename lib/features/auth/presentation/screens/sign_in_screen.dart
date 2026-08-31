import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/forgot_password_dialog.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/services/auth_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signIn),
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
                  const SizedBox(height: 16),
                  const AppLogo(width: 100, height: 100),
                  const SizedBox(height: 16),
                  Text(l10n.signIn, style: context.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    l10n.signInSubTitle,
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
                                  l10n.lockedRoleLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedUserType == 'House Owner' ? 'House Owner' : 'Tenant',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: l10n.roleLockedTooltip,
                            child: const Icon(Icons.lock_rounded, size: 18, color: AppColors.themeColor),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUserType,
                      decoration: const InputDecoration(
                        hintText: 'Select User Type',
                      ),
                      items: ['House Owner', 'Tenant']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUserType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a user type';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailTEController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'Email'),
                    validator: Validators.validateEmail,
                  ),
                
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordTEController,
                    textInputAction: TextInputAction.done,
                    obscureText: _isPasswordObscured,
                    obscuringCharacter: '*',
                    decoration: InputDecoration(
                      hintText: 'Password',
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
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 4),
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
                        Localizations.localeOf(context).languageCode == 'bn'
                            ? 'পাসওয়ার্ড ভুলে গেছেন?'
                            : 'Forgot Password?',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.themeColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _onTapSignInButton,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(l10n.signIn),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.doNotHaveAnAccount,
                        style: context.textTheme.labelLarge,
                      ),
                      TextButton(
                        onPressed: _onTapSignUpNavigation,
                        child: Text(l10n.signUp),
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

  Future<void> _onTapSignInButton() async {
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unauthorized access. Please login as $_selectedUserType.')),
              );
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim())),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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