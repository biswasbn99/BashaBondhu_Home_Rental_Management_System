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
import 'package:bashabondhu_home_rental_management_system/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/faq_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/privacy_policy_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/refund_policy_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/support_policy_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/terms_conditions_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/presentation/screens/subscription_history_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/presentation/screens/tenant_subscription_screen.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
        const SizedBox(height: 16),

        // --- 🌟 Prominent Subscription Status & Upgrade Card ---
        _buildSubscriptionBannerCard(context, user, isDark, l10n),
        const SizedBox(height: 24),

        // Tenant Action Hub
        DecoratedSectionHeader(title: l10n.account),
        const SizedBox(height: 12),

        // 0. BashaBondhu AI Assistant
        AccountActionTile(
          icon: Icons.auto_awesome_rounded,
          title: l10n.localeName == 'bn' ? 'বাসাবন্ধু এআই সহকারী' : 'BashaBondhu AI Assistant',
          subtitle: l10n.localeName == 'bn'
              ? 'চ্যাটে দ্রুত বাসা খুঁজুন ও এলাকার ভাড়ার তথ্য জানুন'
              : 'Smart chat search for rental homes & area insights',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A896), AppColors.themeColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                SizedBox(width: 3),
                Text(
                  'AI Chat',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, AIAssistantScreen.name);
          },
        ),

        // 1. My Subscription Packages Button
        AccountActionTile(
          icon: Icons.card_membership_rounded,
          title: l10n.mySubscription,
          subtitle: user.isSubscribed
              ? (l10n.localeName == 'bn'
                  ? 'প্রিমিয়াম প্যাকেজ সক্রিয় • সকল সুবিধা ও মেয়াদ দেখুন'
                  : 'Premium package active • View perks & validity')
              : (l10n.localeName == 'bn'
                  ? 'বাড়িওয়ালার নম্বর আনলক ও সাপোর্ট প্যাকেজগুলো দেখুন (৳১০০, ৳২০০, ৳৩৫০)'
                  : 'Unlock contact numbers & view support packages (৳100, ৳200, ৳350)'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (user.isSubscribed ? Colors.green : Colors.deepOrange).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isSubscribed ? Icons.verified_rounded : Icons.star_rounded,
                  size: 13,
                  color: user.isSubscribed ? Colors.green : Colors.deepOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  user.isSubscribed ? 'Premium' : 'প্যাকেজ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: user.isSubscribed ? Colors.green : Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, TenantSubscriptionScreen.name);
          },
        ),

        // 2. Subscription History & Receipts
        AccountActionTile(
          icon: Icons.receipt_long_rounded,
          title: l10n.subscriptionHistory,
          subtitle: l10n.localeName == 'bn'
              ? 'অতীতের সকল সাবস্ক্রিপশন প্যাকেজ ও পেমেন্ট হিস্ট্রি দেখুন'
              : 'View all past subscription packages and bKash payment records',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubscriptionHistoryScreen(user: user),
              ),
            );
          },
        ),

        // 3. My Dashboard Button
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
            debugPrint('➡️ Navigating to TenantDashboardScreen');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TenantDashboardScreen()),
            );
          },
        ),

        // 4. Profile Information
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

        // 5. My Demands
        AccountActionTile(
          icon: Icons.assignment_outlined,
          title: l10n.myDemands,
          subtitle: l10n.localeName == 'bn'
              ? 'আপনার পোস্ট করা ভাড়ার চাহিদাসমূহ দেখুন, এডিট বা ডিলিট করুন'
              : 'Manage, edit or delete your posted rental requirements',
          onTap: () => Navigator.pushNamed(context, MyDemandScreen.name),
        ),

        // 6. Find a Home
        AccountActionTile(
          icon: Icons.search_rounded,
          title: l10n.findHome,
          subtitle: l10n.localeName == 'bn'
              ? 'পছন্দের এলাকা ও সুবিধায় বাসা খুঁজুন'
              : 'Explore rental houses and apartments by location',
          onTap: () => navProvider.changeIndex(1),
        ),

        // 7. Wishlist
        AccountActionTile(
          icon: Icons.favorite_border_rounded,
          title: l10n.wishlist,
          subtitle: l10n.localeName == 'bn'
              ? 'আপনার পছন্দের তালিকায় সংরক্ষিত বাসাগুলো দেখুন'
              : 'Access your bookmarked and saved favorite properties',
          onTap: () => navProvider.changeIndex(3),
        ),

        // 8. Demand Post
        AccountActionTile(
          icon: Icons.mark_email_unread_outlined,
          title: l10n.demand,
          subtitle: l10n.localeName == 'bn'
              ? 'নতুন ভাড়ার চাহিদা সরাসরি পোস্ট করুন'
              : 'Post a new rental requirement for landlords to find you',
          onTap: () => navProvider.changeIndex(2),
        ),

        // --- 🛡️ Legal, Policy & Support Hub ---
        const SizedBox(height: 24),
        DecoratedSectionHeader(title: l10n.localeName == 'bn' ? 'তথ্য ও সহায়তা' : 'Support & Legal Policies'),
        const SizedBox(height: 12),

        // 9. Privacy Policy
        AccountActionTile(
          icon: Icons.privacy_tip_outlined,
          title: l10n.localeName == 'bn' ? 'গোপনীয়তা নীতি' : 'Privacy Policy',
          subtitle: l10n.localeName == 'bn'
              ? 'আপনার ব্যক্তিগত তথ্যের নিরাপত্তা ও ব্যবহার সম্পর্কিত নীতিমালা'
              : 'How BashaBondhu protects and respects your personal data',
          onTap: () => Navigator.pushNamed(context, PrivacyPolicyScreen.name),
        ),

        // 10. Support Policy
        AccountActionTile(
          icon: Icons.support_agent_rounded,
          title: l10n.localeName == 'bn' ? 'সাপোর্ট পলিসি' : 'Support Policy',
          subtitle: l10n.localeName == 'bn'
              ? 'গ্রাহক সেবা, সহায়তা চ্যানেল ও রেসপন্স টাইম গাইডলাইন'
              : 'Customer assistance, helpline hours and resolution process',
          onTap: () => Navigator.pushNamed(context, SupportPolicyScreen.name),
        ),

        // 11. Terms and Conditions
        AccountActionTile(
          icon: Icons.gavel_rounded,
          title: l10n.localeName == 'bn' ? 'ব্যবহারের শর্তাবলী' : 'Terms & Conditions',
          subtitle: l10n.localeName == 'bn'
              ? 'প্ল্যাটফর্ম ব্যবহার, আইনি নিয়ম ও সাধারণ নির্দেশিকা'
              : 'Rules, regulations and user agreements for BashaBondhu',
          onTap: () => Navigator.pushNamed(context, TermsConditionsScreen.name),
        ),

        // 12. Refund Policy
        AccountActionTile(
          icon: Icons.replay_rounded,
          title: l10n.localeName == 'bn' ? 'রিফান্ড পলিসি' : 'Refund Policy',
          subtitle: l10n.localeName == 'bn'
              ? 'পেমেন্ট রিফান্ড, সাবস্ক্রিপশন বাতিল ও বিরোধ নিষ্পত্তির নিয়ম'
              : 'Subscription cancellations, refund eligibility and settlement rules',
          onTap: () => Navigator.pushNamed(context, RefundPolicyScreen.name),
        ),

        // 13. FAQ
        AccountActionTile(
          icon: Icons.help_outline_rounded,
          title: l10n.localeName == 'bn' ? 'সচরাচর জিজ্ঞাসা (FAQ)' : 'Frequently Asked Questions (FAQ)',
          subtitle: l10n.localeName == 'bn'
              ? 'বাসা খোঁজা, বুকিং ও অ্যাকাউন্ট সম্পর্কিত সাধারণ প্রশ্নোত্তর'
              : 'Quick answers for finding homes, account security and features',
          onTap: () => Navigator.pushNamed(context, FaqScreen.name),
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

  Widget _buildSubscriptionBannerCard(
    BuildContext context,
    UserModel user,
    bool isDark,
    dynamic l10n,
  ) {
    final bool isSubscribed = user.isSubscribed;
    final int freeUnlocksLeft = user.freePropertyUnlocksRemaining;

    final String languageCode = Localizations.localeOf(context).languageCode;
    final int usedUnlocks = (5 - freeUnlocksLeft) > 0 ? (5 - freeUnlocksLeft) : 0;
    final int usedRadius = (3 - user.freeRadiusSearchesRemaining) > 0 ? (3 - user.freeRadiusSearchesRemaining) : 0;

    final String quotaText = isSubscribed
        ? l10n.tenantPremiumSubtitle
        : l10n.tenantQuotaStatus(
            freeUnlocksLeft.toLocalizedDigits(languageCode),
            usedUnlocks.toLocalizedDigits(languageCode),
            user.freeRadiusSearchesRemaining.toLocalizedDigits(languageCode),
            usedRadius.toLocalizedDigits(languageCode),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSubscribed
              ? (isDark
                  ? [const Color(0xFF163228), const Color(0xFF0F241D)]
                  : [const Color(0xFFE4F9ED), const Color(0xFFC7F3DC)])
              : (isDark
                  ? [const Color(0xFF2E2416), const Color(0xFF20180D)]
                  : [const Color(0xFFFFF4E5), const Color(0xFFFFE7CC)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSubscribed ? Colors.green.shade600 : Colors.deepOrange.shade400,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSubscribed ? Colors.green : Colors.deepOrange).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: (isSubscribed ? Colors.green : Colors.deepOrange).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSubscribed ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                  color: isSubscribed ? Colors.green : Colors.deepOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSubscribed ? l10n.tenantPremiumActive : l10n.freeAccountLimited,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isSubscribed ? Colors.green : Colors.deepOrange.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quotaText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isSubscribed ? Colors.green.shade700 : Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(isSubscribed ? Icons.check_circle_rounded : Icons.star_rounded, size: 18),
              label: Text(
                isSubscribed ? l10n.subscriptionDetailsAndPackages : l10n.activateSupportPackage,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                Navigator.pushNamed(context, TenantSubscriptionScreen.name);
              },
            ),
          ),
        ],
      ),
    );
  }
}