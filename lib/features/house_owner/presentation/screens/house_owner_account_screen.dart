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
import 'package:bashabondhu_home_rental_management_system/features/home/data/models/property_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/presentation/screens/house_owner_dashboard_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/services/property_firestore_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/my_profile_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/tenant_demand_show_screen.dart';

class HouseOwnerAccountScreen extends StatelessWidget {
  const HouseOwnerAccountScreen({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
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
            const SizedBox(height: 16),

            // House Owner Quick Stats Bar
            Row(
              children: [
                Expanded(
                  child: AccountStatCard(
                    icon: Icons.apartment_rounded,
                    iconColor: AppColors.themeColor,
                    count: postCount.toString(),
                    label: l10n.myPost,
                    onTap: () => navProvider.changeIndex(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AccountStatCard(
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: Colors.teal,
                    count: '➕',
                    label: l10n.postRentalTitle,
                    onTap: () => navProvider.changeIndex(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AccountStatCard(
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
            AccountActionTile(
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
                Navigator.pushNamed(context, HouseOwnerDashboardScreen.name);
              },
            ),
            AccountActionTile(
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
            AccountActionTile(
              icon: Icons.view_list_rounded,
              title: l10n.myPost,
              subtitle: 'আপনার পোস্ট করা বাসার তথ্য দেখুন, এডিট বা ডিলিট করুন',
              onTap: () => navProvider.changeIndex(2),
            ),
            AccountActionTile(
              icon: Icons.add_home_work_outlined,
              title: l10n.postNow,
              subtitle: 'নতুন বাসা ভাড়ার বিজ্ঞাপন পোস্ট করুন',
              onTap: () => navProvider.changeIndex(1),
            ),
            AccountActionTile(
              icon: Icons.campaign_rounded,
              title: l10n.allTenantDemands,
              subtitle: 'ভাড়াটিয়াদের ভাড়ার চাহিদা তালিকা দেখুন',
              onTap: () => Navigator.pushNamed(context, TenantDemandShowScreen.name),
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
      },
    );
  }
}