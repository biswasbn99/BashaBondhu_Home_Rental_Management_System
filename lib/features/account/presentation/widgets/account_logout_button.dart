import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/services/auth_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/main_nav_holder_screen.dart';

class AccountLogoutButton extends StatelessWidget {
  const AccountLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(l10n.logout, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showLogoutConfirmation(context),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        backgroundColor: theme.colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logout Warning Icon Halo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: isDark ? 0.25 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.logout_rounded, size: 30, color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                l10n.logoutConfirmTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                l10n.logoutConfirmSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: isDark ? Colors.grey[300] : const Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 24),

              // 2 Action Buttons (Same Design, Different Color)
              Row(
                children: [
                  // 1. Cancel Button
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                        foregroundColor: isDark ? Colors.grey[200] : const Color(0xFF2D3748),
                        minimumSize: const Size.fromHeight(46),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 2. Yes, Logout Button
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        await AuthService().signOut();
                        if (context.mounted) {
                          context.read<MainNavHolderProvider>().resetIndex();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            MainNavHolderScreen.name,
                            (route) => false,
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.yesLogout,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
