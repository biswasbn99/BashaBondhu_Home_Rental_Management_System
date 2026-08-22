import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../../../app/providers/theme_provider.dart';
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
import '../../../shared/presentation/screens/my_profile_screen.dart';
import '../../../tenant/presentation/screens/tenant_dashboard_screen.dart';
import '../../../house_owner/presentation/screens/house_owner_dashboard_screen.dart';
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
        _ActionTile(
          icon: Icons.search_rounded,
          title: l10n.findHome,
          subtitle: 'সহজেই খুঁজুন আপনার স্বপ্নের বাসা',
          onTap: () => context.read<MainNavHolderProvider>().changeIndex(1),
        ),
        _ActionTile(
          icon: Icons.favorite_border_rounded,
          title: l10n.wishlist,
          subtitle: 'আপনার সংরক্ষিত বাসাগুলো দেখুন',
          onTap: () => context.read<MainNavHolderProvider>().changeIndex(3),
        ),
        const SizedBox(height: 24),

        // App Settings
        DecoratedSectionHeader(title: l10n.appSettings),
        const SizedBox(height: 12),
        const _ThemeSettingTile(),
        const SizedBox(height: 10),
        const _LanguageSettingTile(),
        const SizedBox(height: 28),

        _buildFooter(theme, l10n),
      ],
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
        
        // Profile Completion Banner
        _ProfileCompletionBanner(user: user),
        const SizedBox(height: 12),

        // Prominent My Dashboard Hero Banner
        _DashboardBanner(
          title: l10n.myDashboard,
          subtitle: 'চাহিদা, সংরক্ষিত বাসা ও সকল অ্যাক্টিভিটি হিস্টোরি',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TenantDashboardScreen()),
            );
          },
        ),
        const SizedBox(height: 16),

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
        DecoratedSectionHeader(title: l10n.myDashboard),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.dashboard_customize_rounded,
          title: l10n.myDashboard,
          subtitle: 'চাহিদা, পছন্দের তালিকা ও সকল অ্যাকাউন্টের হিস্টোরি ও কার্যক্রম দেখুন',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights_rounded, size: 13, color: AppColors.themeColor),
                SizedBox(width: 4),
                Text(
                  'Overview',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                ),
              ],
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TenantDashboardScreen()),
            );
          },
        ),
        _ActionTile(
          icon: Icons.person_pin_circle_outlined,
          title: l10n.myProfile,
          subtitle: 'ছবি, ব্যক্তিগত তথ্য ও এনআইডি ভেরিফিকেশন আপডেট করুন',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (user.isProfileComplete ? Colors.green : Colors.amber.shade800).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${user.profileCompletionPercentage}% ${user.isProfileComplete ? l10n.complete : l10n.incomplete}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: user.isProfileComplete ? Colors.green : Colors.amber.shade800,
              ),
            ),
          ),
          onTap: () => Navigator.pushNamed(context, MyProfileScreen.name),
        ),
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
        const _ThemeSettingTile(),
        const SizedBox(height: 10),
        const _LanguageSettingTile(),
        const SizedBox(height: 24),

        // Logout Button
        _buildLogoutButton(context, l10n),
        const SizedBox(height: 24),

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

    return StreamBuilder<List<PropertyModel>>(
      stream: PropertyFirestoreService().streamOwnerProperties(user.uid, ownerEmail: user.email),
      builder: (context, snapshot) {
        final properties = snapshot.data ?? [];
        final int postCount = properties.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            AccountProfileHeader(user: user),
            
            // Profile Completion Banner
            _ProfileCompletionBanner(user: user),
            const SizedBox(height: 12),

            // Prominent My Dashboard Hero Banner
            _DashboardBanner(
              title: l10n.myDashboard,
              subtitle: 'বিজ্ঞাপন অ্যানালিটিক্স, ভাড়াটিয়াদের চাহিদা রাডার ও হিস্টোরি',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HouseOwnerDashboardScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            // House Owner Quick Stats Bar
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.apartment_rounded,
                    iconColor: AppColors.themeColor,
                    count: postCount.toString(),
                    label: l10n.myPost,
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
            DecoratedSectionHeader(title: l10n.myDashboard),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.dashboard_customize_rounded,
              title: l10n.myDashboard,
              subtitle: 'বিজ্ঞাপন অ্যানালিটিক্স, ভাড়াটিয়া চাহিদা রাডার ও কার্যক্রম ইতিহাস দেখুন',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_rounded, size: 13, color: AppColors.themeColor),
                    SizedBox(width: 4),
                    Text(
                      'Analytics',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HouseOwnerDashboardScreen()),
                );
              },
            ),
            _ActionTile(
              icon: Icons.person_pin_circle_outlined,
              title: l10n.myProfile,
              subtitle: 'ছবি, ব্যক্তিগত তথ্য ও এনআইডি ভেরিফিকেশন আপডেট করুন',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (user.isProfileComplete ? Colors.green : Colors.amber.shade800).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${user.profileCompletionPercentage}% ${user.isProfileComplete ? l10n.complete : l10n.incomplete}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: user.isProfileComplete ? Colors.green : Colors.amber.shade800,
                  ),
                ),
              ),
              onTap: () => Navigator.pushNamed(context, MyProfileScreen.name),
            ),
            _ActionTile(
              icon: Icons.view_list_rounded,
              title: l10n.myPost,
              subtitle: 'আপনার পোস্ট করা বাসার তথ্য দেখুন, এডিট বা ডিলিট করুন',
              onTap: () => navProvider.changeIndex(2),
            ),
            _ActionTile(
              icon: Icons.add_home_work_outlined,
              title: l10n.postNow,
              subtitle: 'নতুন বাসা ভাড়ার বিজ্ঞাপন পোস্ট করুন',
              onTap: () => navProvider.changeIndex(1),
            ),
            _ActionTile(
              icon: Icons.campaign_rounded,
              title: l10n.allTenantDemands,
              subtitle: 'ভাড়াটিয়াদের ভাড়ার চাহিদা তালিকা দেখুন',
              onTap: () => Navigator.pushNamed(context, TenantDemandShowScreen.name),
            ),
            const SizedBox(height: 24),

            // App Settings
            DecoratedSectionHeader(title: l10n.appSettings),
            const SizedBox(height: 12),
            const _ThemeSettingTile(),
            const SizedBox(height: 10),
            const _LanguageSettingTile(),
            const SizedBox(height: 24),

            // Logout Button
            _buildLogoutButton(context, l10n),
            const SizedBox(height: 24),

            _buildFooter(theme, l10n),
          ],
        );
      },
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

class _DashboardBanner extends StatelessWidget {
  const _DashboardBanner({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: Color(0xFF00A896),
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF00A896)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSettingTile extends StatelessWidget {
  const _ThemeSettingTile();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentThemeMode == ThemeMode.dark ||
        (themeProvider.currentThemeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Colors.amber.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Theme Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            activeTrackColor: AppColors.themeColor,
            onChanged: (val) {
              themeProvider.changeThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageSettingTile extends StatelessWidget {
  const _LanguageSettingTile();

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isBangla = localeProvider.currentLocale.languageCode == 'bn';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              color: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.language_rounded, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Language / ভাষা',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                Text(
                  isBangla ? 'বাংলা (Bangla)' : 'English',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isBangla,
            activeTrackColor: AppColors.themeColor,
            onChanged: (val) {
              localeProvider.changeLocale(Locale(val ? 'bn' : 'en'));
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileCompletionBanner extends StatelessWidget {
  const _ProfileCompletionBanner({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final int completion = user.profileCompletionPercentage;
    final bool isComplete = user.isProfileComplete;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2625) : const Color(0xFFF9FBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isComplete ? Colors.green : Colors.amber.shade700).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isComplete ? Colors.green : Colors.amber.shade700).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                  color: isComplete ? Colors.green : Colors.amber.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileCompletion,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isComplete
                          ? 'প্রোফাইল ভেরিফাইড ও সম্পূর্ণ'
                          : 'ছবি, এনআইডি ও তথ্য দিয়ে প্রোফাইল ১০০% করুন',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamed(context, MyProfileScreen.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isComplete ? Colors.green : AppColors.themeColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completion%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 6,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : AppColors.themeColor,
              ),
            ),
          ),
        ],
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
