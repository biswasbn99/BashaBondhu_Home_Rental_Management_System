import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/app/language_changer.dart';
import 'package:bashabondhu_home_rental_management_system/app/theme_changer.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/screens/account_profile_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/services/auth_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/tenant_demand/presentation/screens/tenant_demand_show_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/main_nav_holder_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    required this.email,
    this.avatarUrl,
    this.isProfileComplete = false,
  });

  final String email;
  final String? avatarUrl;
  final bool isProfileComplete;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final l10n = context.localizations;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          l10n.account,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Premium Header ---
              AccountProfileHeader(
                user: userProvider.user,
                onTap: () {},
              ),
              const SizedBox(height: 24),

              // --- Actions Section ---
              if (userProvider.isGuest) ...[
                _buildAuthButtons(context, l10n),
              ] else ...[
                _buildUserActions(context, l10n, userProvider.user!.userType),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // --- App Settings ---
              Text(
                'App Settings',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const ThemeChangerDropdown(),
              const SizedBox(height: 16),
              const LocaleChangerDropdown(),
              const SizedBox(height: 24),

              if (!userProvider.isGuest)
                _buildLogoutButton(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButtons(BuildContext context, var l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, SignInScreen.name),
            icon: const Icon(Icons.login_rounded),
            label: Text(l10n.signIn),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, SignUpScreen.name),
            icon: const Icon(Icons.person_add_alt_rounded),
            label: Text(l10n.signUp),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.themeColor),
              foregroundColor: AppColors.themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserActions(BuildContext context, var l10n, String userType) {
    return Column(
      children: [
        if (userType == 'House Owner')
          _ActionTile(
            title: 'View Tenant Demands',
            icon: Icons.domain_add_rounded,
            onTap: () => Navigator.pushNamed(context, TenantDemandShowScreen.name),
          ),
        const _ActionTile(
          title: 'My Profile',
          icon: Icons.account_circle_outlined,
        ),
        const _ActionTile(
          title: 'Saved Houses',
          icon: Icons.favorite_border_rounded,
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, var l10n) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          await AuthService().signOut();
          if (context.mounted) {
            context.read<MainNavHolderProvider>().resetIndex();
            Navigator.pushNamedAndRemoveUntil(context, MainNavHolderScreen.name, (route) => false);
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: Text(
          l10n.logout,
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, required this.icon, this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.themeColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
