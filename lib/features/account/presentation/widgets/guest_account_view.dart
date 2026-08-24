import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/screens/account_profile_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/widgets/account_action_tile.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/widgets/account_footer.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/widgets/account_setting_tiles.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';

class GuestAccountView extends StatelessWidget {
  const GuestAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header
        const AccountProfileHeader(user: null),
        const SizedBox(height: 18),

        // Welcome Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF004D40), const Color(0xFF00796B)]
                  : [const Color(0xFF00A896), const Color(0xFF028090)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.themeColor.withValues(alpha: isDark ? 0.3 : 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'স্বাগতম / Welcome',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'লগইন করে আপনার অ্যাকাউন্টের সম্পূর্ণ সুবিধা নিন',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pushNamed(context, SignInScreen.name),
                      child: Text(l10n.signIn, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pushNamed(context, SignUpScreen.name),
                      child: Text(l10n.signUp, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Feature Links
        DecoratedSectionHeader(title: l10n.findHome),
        const SizedBox(height: 12),
        AccountActionTile(
          icon: Icons.search_rounded,
          title: l10n.findHome,
          subtitle: 'সহজেই খুঁজুন আপনার স্বপ্নের বাসা',
          onTap: () => context.read<MainNavHolderProvider>().changeIndex(1),
        ),
        AccountActionTile(
          icon: Icons.favorite_border_rounded,
          title: l10n.wishlist,
          subtitle: 'আপনার সংরক্ষিত বাসাগুলো দেখুন',
          onTap: () => context.read<MainNavHolderProvider>().changeIndex(3),
        ),
        const SizedBox(height: 24),

        // App Settings
        DecoratedSectionHeader(title: l10n.appSettings),
        const SizedBox(height: 12),
        const AccountThemeSettingTile(),
        const SizedBox(height: 10),
        const AccountLanguageSettingTile(),
        const SizedBox(height: 28),

        const AccountFooter(),
      ],
    );
  }
}
