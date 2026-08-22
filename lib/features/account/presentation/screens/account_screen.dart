import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/language_changer.dart';
import '../../../../app/theme_changer.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/screens/sign_in_screen.dart';
import '../../../auth/presentation/screens/sign_up_screen.dart';
import '../../../home/data/models/property_model.dart';
import '../../../tenant/presentation/screens/tenant_demand_show_screen.dart';
import '../../../tenant/presentation/screens/my_demand_screen.dart';
import '../../../shared/data/services/property_firestore_service.dart';
import '../../../shared/presentation/providers/main_nav_holder_provider.dart';
import '../../../shared/presentation/screens/main_nav_holder_screen.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/decorated_section_header.dart';
import '../../../shared/presentation/widgets/post_icon.dart';
import '../../../wishlist/data/providers/wishlist_provider.dart';
import 'account_profile_header.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    this.email = '',
    this.avatarUrl,
    this.isProfileComplete = false,
  });

  final String email;
  final String? avatarUrl;
  final bool isProfileComplete;

  static const String name = '/account';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final bool isGuest = userProvider.isGuest;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: isGuest ? 12 : 20,
        actions: isGuest
            ? [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FreePostButton(),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: isGuest
              ? const _GuestAccountView()
              : user?.userType == 'House Owner'
                  ? _HouseOwnerAccountView(user: user!)
                  : _TenantAccountView(user: user!),
        ),
      ),
    );
  }
}

// ============================================================================
// 1. GUEST USER ACCOUNT VIEW
// ============================================================================
class _GuestAccountView extends StatelessWidget {
  const _GuestAccountView();

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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.welcomeGuestTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.welcomeGuestSubtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Sign In & Sign Up Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pushNamed(context, SignInScreen.name),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: Text(l10n.signIn, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pushNamed(context, SignUpScreen.name),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text(l10n.signUp, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Key Features Spotlight
        DecoratedSectionHeader(title: l10n.guestFeaturesTitle),
        const SizedBox(height: 12),
        _buildFeatureItem(Icons.search_rounded, l10n.featureFindHome, theme, isDark),
        _buildFeatureItem(Icons.add_home_work_rounded, l10n.featurePostHome, theme, isDark),
        _buildFeatureItem(Icons.mark_email_unread_rounded, l10n.featureDemandHome, theme, isDark),
        _buildFeatureItem(Icons.favorite_rounded, l10n.featureWishlist, theme, isDark),
        const SizedBox(height: 24),

        // App Settings
        DecoratedSectionHeader(title: l10n.appSettings),
        const SizedBox(height: 12),
        const ThemeChangerDropdown(),
        const SizedBox(height: 12),
        const LocaleChangerDropdown(),
        const SizedBox(height: 24),

        // App Footer
        _buildFooter(theme, l10n),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.themeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. TENANT USER ACCOUNT VIEW
// ============================================================================
class _TenantAccountView extends StatelessWidget {
  const _TenantAccountView({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final wishlistProvider = context.watch<WishlistProvider>();
    final navProvider = context.read<MainNavHolderProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header
        AccountProfileHeader(user: user),
        const SizedBox(height: 18),

        // Tenant Quick Stats Bar
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.favorite_rounded,
                iconColor: Colors.redAccent,
                count: wishlistProvider.wishlistProperties.length.toString(),
                label: l10n.savedHouses,
                onTap: () => navProvider.changeIndex(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.search_rounded,
                iconColor: AppColors.themeColor,
                count: '🔍',
                label: l10n.findHome,
                onTap: () => navProvider.changeIndex(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.post_add_rounded,
                iconColor: Colors.orange,
                count: '📝',
                label: l10n.myDemands,
                onTap: () => Navigator.pushNamed(context, MyDemandScreen.name),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tenant Action Hub
        DecoratedSectionHeader(title: l10n.myProfile),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.assignment_outlined,
          title: l10n.myDemands,
          subtitle: 'আপনার পোস্ট করা ভাড়ার চাহিদাসমূহ দেখুন, এডিট বা ডিলিট করুন',
          onTap: () => Navigator.pushNamed(context, MyDemandScreen.name),
        ),
        _ActionTile(
          icon: Icons.search_rounded,
          title: l10n.findHome,
          subtitle: 'পছন্দের এলাকা ও সুবিধায় বাসা খুঁজুন',
          onTap: () => navProvider.changeIndex(1),
        ),
        _ActionTile(
          icon: Icons.favorite_border_rounded,
          title: l10n.wishlist,
          subtitle: 'আপনার পছন্দের তালিকায় সংরক্ষিত বাসাগুলো দেখুন',
          onTap: () => navProvider.changeIndex(3),
        ),
        _ActionTile(
          icon: Icons.mark_email_unread_outlined,
          title: l10n.demand,
          subtitle: 'নতুন ভাড়ার চাহিদা সরাসরি পোস্ট করুন',
          onTap: () => navProvider.changeIndex(2),
        ),
        const SizedBox(height: 24),

        // App Settings
        DecoratedSectionHeader(title: l10n.appSettings),
        const SizedBox(height: 12),
        const ThemeChangerDropdown(),
        const SizedBox(height: 12),
        const LocaleChangerDropdown(),
        const SizedBox(height: 24),

        // Logout
        _buildLogoutButton(context, l10n),
        const SizedBox(height: 16),

        _buildFooter(theme, l10n),
      ],
    );
  }
}

// ============================================================================
// 3. HOUSE OWNER USER ACCOUNT VIEW
// ============================================================================
class _HouseOwnerAccountView extends StatelessWidget {
  const _HouseOwnerAccountView({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final navProvider = context.read<MainNavHolderProvider>();
    final firestoreService = PropertyFirestoreService();

    return StreamBuilder<List<PropertyModel>>(
      stream: firestoreService.streamOwnerProperties(user.uid, ownerEmail: user.email),
      builder: (context, snapshot) {
        final ownerPosts = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            AccountProfileHeader(user: user),
            const SizedBox(height: 18),

            // House Owner Quick Stats Bar
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.home_work_rounded,
                    iconColor: AppColors.themeColor,
                    count: ownerPosts.length.toString(),
                    label: l10n.activePosts,
                    onTap: () => navProvider.changeIndex(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: Colors.teal,
                    count: '➕',
                    label: l10n.postRentalTitle,
                    onTap: () => navProvider.changeIndex(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_alt_outlined,
                    iconColor: Colors.blueAccent,
                    count: '👥',
                    label: l10n.demand,
                    onTap: () => navProvider.changeIndex(0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // House Owner Action Hub
            DecoratedSectionHeader(title: l10n.myProfile),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.view_list_rounded,
              title: l10n.myPost,
              subtitle: 'আপনার পোস্ট করা বাসার তথ্য দেখুন, এডিট বা ডিলিট করুন',
              onTap: () => navProvider.changeIndex(2),
            ),
            _ActionTile(
              icon: Icons.add_home_work_outlined,
              title: l10n.postNow,
              subtitle: 'ছবি ও বিস্তারিত তথ্য দিয়ে নতুন বাসাভাড়া পোস্ট করুন',
              onTap: () => navProvider.changeIndex(1),
            ),
            _ActionTile(
              icon: Icons.domain_add_rounded,
              title: l10n.viewTenantDemands,
              subtitle: 'ভাড়াটিয়াদের চাহিদার তালিকা দেখুন ও যোগাযোগ করুন',
              onTap: () {
                Navigator.pushNamed(context, TenantDemandShowScreen.name);
              },
            ),
            const SizedBox(height: 24),

            // Host Guidelines & Settings
            DecoratedSectionHeader(title: l10n.appSettings),
            const SizedBox(height: 12),
            const ThemeChangerDropdown(),
            const SizedBox(height: 12),
            const LocaleChangerDropdown(),
            const SizedBox(height: 24),

            // Logout Button
            _buildLogoutButton(context, l10n),
            const SizedBox(height: 16),

            _buildFooter(theme, l10n),
          ],
        );
      },
    );
  }
}

// ============================================================================
// SHARED WIDGETS & HELPERS
// ============================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 6),
              Text(
                count,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.themeColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildLogoutButton(BuildContext context, dynamic l10n) {
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
      onPressed: () => _showLogoutConfirmation(context, l10n),
    ),
  );
}

void _showLogoutConfirmation(BuildContext context, dynamic l10n) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.logout_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Text(l10n.logoutConfirmTitle),
        ],
      ),
      content: Text(l10n.logoutConfirmSubtitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () async {
            Navigator.pop(ctx);
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
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
}

Widget _buildFooter(ThemeData theme, dynamic l10n) {
  return Center(
    child: Column(
      children: [
        Text(
          'BashaBondhu Home Rental • ${l10n.appVersion} 1.0.0',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '© 2026 BashaBondhu Inc. All rights reserved.',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            fontSize: 10.5,
          ),
        ),
      ],
    ),
  );
}
