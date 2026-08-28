import 'package:flutter/material.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';

class AuthPromptDialog extends StatelessWidget {
  const AuthPromptDialog({
    super.key,
    required this.requiredRole,
    this.customMessage,
  });

  /// Either 'Tenant' or 'House Owner'
  final String requiredRole;
  final String? customMessage;

  static Future<void> show(
    BuildContext context, {
    required String requiredRole,
    String? customMessage,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AuthPromptDialog(
        requiredRole: requiredRole,
        customMessage: customMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTenant = requiredRole.toLowerCase().contains('tenant');

    final IconData roleIcon = isTenant ? Icons.person_pin_circle_rounded : Icons.home_work_rounded;
    final Color roleColor = isTenant ? const Color(0xFF028090) : AppColors.themeColor;
    final String roleBadgeText = isTenant ? 'TENANT' : 'HOUSE OWNER';

    final String messageText = customMessage ??
        (isTenant ? l10n.signInAsTenantPrompt : l10n.signInAsHouseOwnerPrompt);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role Icon with soft halo
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: roleColor.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(roleIcon, size: 30, color: roleColor),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Role Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 12, color: roleColor),
                    const SizedBox(width: 4),
                    Text(
                      roleBadgeText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Dialog Title
            Text(
              l10n.signInRequired,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.5,
              ),
            ),
            const SizedBox(height: 8),

            // Explanation Message
            Text(
              messageText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isDark ? Colors.grey[300] : const Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 18),

            // 1. Primary Action: Sign In as [Role]
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamed(
                  context,
                  SignInScreen.name,
                  arguments: {
                    'preSelectedUserType': requiredRole,
                    'lockUserType': true,
                  },
                );
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(
                isTenant ? l10n.signInAsTenant : l10n.signInAsHouseOwner,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: roleColor,
                minimumSize: const Size.fromHeight(46),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 2. Secondary Action: Sign Up as [Role]
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamed(
                  context,
                  SignUpScreen.name,
                  arguments: {
                    'preSelectedUserType': requiredRole,
                    'lockUserType': true,
                  },
                );
              },
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: Text(
                isTenant ? l10n.signUpAsTenant : l10n.signUpAsHouseOwner,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: roleColor),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(vertical: 11),
                side: BorderSide(color: roleColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 2),

            // 3. Cancel Action
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
