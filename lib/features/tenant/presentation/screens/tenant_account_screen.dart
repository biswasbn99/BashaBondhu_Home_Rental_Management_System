import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/screens/account_profile_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/widgets/account_action_tile.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/widgets/account_footer.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/widgets/account_logout_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/widgets/account_setting_tiles.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/widgets/account_stat_card.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/models/user_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/my_profile_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/my_demand_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/tenant_dashboard_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/wishlist/data/providers/wishlist_provider.dart';

class TenantAccountScreen extends StatelessWidget {
  const TenantAccountScreen({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final wishlistProvider = context.watch<WishlistProvider>();
    final navProvider = context.read<MainNavHolderProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header
        AccountProfileHeader(user: user),
        const SizedBox(height: 16),

        // Tenant Quick Stats Bar
        Row(
          children: [
            Expanded(
              child: AccountStatCard(
                icon: Icons.favorite_rounded,
                iconColor: Colors.redAccent,
                count: wishlistProvider.wishlistProperties.length.toString(),
                label: l10n.savedHouses,
                onTap: () => navProvider.changeIndex(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AccountStatCard(
                icon: Icons.search_rounded,
                iconColor: AppColors.themeColor,
                count: '🔍',
                label: l10n.findHome,
                onTap: () => navProvider.changeIndex(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AccountStatCard(
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
        DecoratedSectionHeader(title: l10n.account),
        const SizedBox(height: 12),

        // 1. My Dashboard Button (Right ABOVE Profile Information)
        AccountActionTile(
          icon: Icons.dashboard_customize_rounded,
          title: l10n.myDashboard,
          subtitle: l10n.localeName == 'bn'
              ? 'চাহিদা, পছন্দের তালিকা ও সকল কার্যক্রমের ওভারভিউ'
              : 'Overview of your rental demands, wishlist & activity',
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
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.themeColor,
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TenantDashboardScreen()),
            );
          },
        ),

        // 2. Profile Information
        AccountActionTile(
          icon: Icons.person_pin_circle_outlined,
          title: l10n.myProfile,
          subtitle: l10n.localeName == 'bn'
              ? 'ছবি, ব্যক্তিগত তথ্য ও এনআইডি ভেরিফিকেশন আপডেট করুন'
              : 'Update profile photo, personal info & NID verification',
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

        // 3. My Demands
        AccountActionTile(
          icon: Icons.assignment_outlined,
          title: l10n.myDemands,
          subtitle: l10n.localeName == 'bn'
              ? 'আপনার পোস্ট করা ভাড়ার চাহিদাসমূহ দেখুন, এডিট বা ডিলিট করুন'
              : 'Manage, edit or delete your posted rental requirements',
          onTap: () => Navigator.pushNamed(context, MyDemandScreen.name),
        ),

        // 4. Find a Home
        AccountActionTile(
          icon: Icons.search_rounded,
          title: l10n.findHome,
          subtitle: l10n.localeName == 'bn'
              ? 'পছন্দের এলাকা ও সুবিধায় বাসা খুঁজুন'
              : 'Explore rental houses and apartments by location',
          onTap: () => navProvider.changeIndex(1),
        ),

        // 5. Wishlist
        AccountActionTile(
          icon: Icons.favorite_border_rounded,
          title: l10n.wishlist,
          subtitle: l10n.localeName == 'bn'
              ? 'আপনার পছন্দের তালিকায় সংরক্ষিত বাসাগুলো দেখুন'
              : 'Access your bookmarked and saved favorite properties',
          onTap: () => navProvider.changeIndex(3),
        ),

        // 6. Demand Post
        AccountActionTile(
          icon: Icons.mark_email_unread_outlined,
          title: l10n.demand,
          subtitle: l10n.localeName == 'bn'
              ? 'নতুন ভাড়ার চাহিদা সরাসরি পোস্ট করুন'
              : 'Post a new rental requirement for landlords to find you',
          onTap: () => navProvider.changeIndex(2),
        ),
        const SizedBox(height: 24),

        // App Settings
        DecoratedSectionHeader(title: l10n.appSettings),
        const SizedBox(height: 12),
        const AccountThemeSettingTile(),
        const SizedBox(height: 10),
        const AccountLanguageSettingTile(),
        const SizedBox(height: 24),

        // Logout Button
        const AccountLogoutButton(),
        const SizedBox(height: 24),

        const AccountFooter(),
      ],
    );
  }
}