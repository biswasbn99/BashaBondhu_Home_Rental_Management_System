import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/validators.dart';
import '../../data/services/auth_service.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({
    super.key,
    this.initialEmail,
  });

  final String? initialEmail;

  static Future<void> show(BuildContext context, {String? initialEmail}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ForgotPasswordDialog(initialEmail: initialEmail),
    );
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      await AuthService().sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() {
        _isSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'এই ইমেইল দিয়ে কোনো অ্যাকাউন্ট খুঁজে পাওয়া যায়নি।';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'সঠিক ইমেইল ঠিকানা প্রদান করুন।';
        } else {
          _errorMessage = e.message ?? 'পাসওয়ার্ড রিসেট লিংক পাঠাতে সমস্যা হয়েছে।';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF162120) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        child: _isSuccess
            ? _buildSuccessView(context, isDark, isBn)
            : _buildFormView(context, isDark, isBn, theme),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, bool isDark, bool isBn, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.themeColor.withValues(alpha: isDark ? 0.22 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 38,
                color: AppColors.themeColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            isBn ? 'পাসওয়ার্ড রিসেট' : 'Reset Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A2B29),
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            isBn
                ? 'আপনার অ্যাকাউন্টের নিবন্ধিত Gmail দিন। আমরা একটি পাসওয়ার্ড রিসেট লিঙ্ক পাঠিয়ে দেব।'
                : 'Enter your registered Gmail address and we will send you a password reset link.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: widget.initialEmail == null || widget.initialEmail!.isEmpty,
            decoration: InputDecoration(
              hintText: 'user@example.com',
              labelText: isBn ? 'ইমেইল ঠিকানা' : 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
            ),
            validator: Validators.validateEmail,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isBn ? 'বাতিল' : 'Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSendResetEmail,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isBn ? 'রিসেট লিঙ্ক পাঠান' : 'Send Reset Link',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isDark, bool isBn) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 44,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isBn ? 'লিঙ্ক পাঠানো হয়েছে!' : 'Email Sent Successfully!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A2B29),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isBn
              ? '${_emailController.text} ঠিকানায় পাসওয়ার্ড রিসেট করার লিঙ্ক পাঠানো হয়েছে। অনুগ্রহ করে আপনার Gmail ইনবক্স অথবা স্প্যাম (Spam) ফোল্ডার চেক করুন।'
              : 'A password reset link has been sent to ${_emailController.text}. Please check your Inbox and Spam folder.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.themeColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            isBn ? 'ঠিক আছে' : 'Got it',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
