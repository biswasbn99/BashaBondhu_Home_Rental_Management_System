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
import 'package:bashabondhu_home_rental_management_system/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/faq_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/privacy_policy_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/refund_policy_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/support_policy_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/terms_conditions_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/presentation/screens/house_owner_subscription_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/presentation/screens/subscription_history_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/tenant_demand_show_screen.dart';

class HouseOwnerAccountScreen extends StatefulWidget {
  const HouseOwnerAccountScreen({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  State<HouseOwnerAccountScreen> createState() => _HouseOwnerAccountScreenState();
}

class _HouseOwnerAccountScreenState extends State<HouseOwnerAccountScreen> {
  late Stream<List<PropertyModel>> _propertiesStream;

  @override
  void initState() {
    super.initState();
    _propertiesStream = PropertyFirestoreService().streamOwnerProperties(
      widget.user.uid,
      ownerEmail: widget.user.email,
    );
  }

  @override
  void didUpdateWidget(covariant HouseOwnerAccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid || oldWidget.user.email != widget.user.email) {
      _propertiesStream = PropertyFirestoreService().streamOwnerProperties(
        widget.user.uid,
        ownerEmail: widget.user.email,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navProvider = context.read<MainNavHolderProvider>();

    return StreamBuilder<List<PropertyModel>>(
      stream: _propertiesStream,
      builder: (context, snapshot) {
        final properties = snapshot.data ?? [];
        final int postCount = properties.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            AccountProfileHeader(user: widget.user),
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
            const SizedBox(height: 16),

            // --- 🌟 Prominent Subscription Status & Upgrade Card for House Owner ---
            _buildOwnerSubscriptionBannerCard(context, widget.user, isDark, l10n, postCount),
            const SizedBox(height: 24),

            // House Owner Action Hub
            DecoratedSectionHeader(title: l10n.account),
            const SizedBox(height: 12),

            // 0. BashaBondhu AI Assistant for House Owner
            AccountActionTile(
              icon: Icons.auto_awesome_rounded,
              title: l10n.localeName == 'bn' ? 'বাসাবন্ধু এআই সহকারী' : 'BashaBondhu AI Assistant',
              subtitle: l10n.localeName == 'bn'
                  ? 'বিজ্ঞাপন তৈরি, ভাড়ার মূল্য নির্ধারণ ও সম্ভাব্য ভাড়াটিয়া খুঁজুন'
                  : 'Write To-Let ads, evaluate fair rent & find prospective tenants',
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
              subtitle: widget.user.isSubscribed
                  ? (l10n.localeName == 'bn'
                      ? 'বাড়িওয়ালা প্রিমিয়াম প্যাকেজ সক্রিয় • সকল সুবিধা ও মেয়াদ দেখুন'
                      : 'Owner Premium active • View perks & validity')
                  : (l10n.localeName == 'bn'
                      ? 'আনলিমিটেড বিজ্ঞাপন ও ভাড়াটিয়া নম্বর আনলক প্যাকেজ (৳৩০০, ৳৫০০, ৳১০০০)'
                      : 'Unlimited listings & tenant unlocking packs (৳300, ৳500, ৳1000)'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (widget.user.isSubscribed ? Colors.green : Colors.amber.shade800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.user.isSubscribed ? Icons.verified_rounded : Icons.star_rounded,
                      size: 13,
                      color: widget.user.isSubscribed ? Colors.green : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.user.isSubscribed ? 'Premium' : 'প্যাকেজ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.user.isSubscribed ? Colors.green : Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
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
                    builder: (_) => SubscriptionHistoryScreen(user: widget.user),
                  ),
                );
              },
            ),

            // 3. My Dashboard Button
            AccountActionTile(
              icon: Icons.dashboard_customize_rounded,
              title: l10n.myDashboard,
              subtitle: l10n.localeName == 'bn'
                  ? 'বিজ্ঞাপন অ্যানালিটিক্স, ভাড়াটিয়া চাহিদা রাডার ও কার্যক্রম ইতিহাস'
                  : 'Listing analytics, market radar, and activity history',
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
                debugPrint('➡️ Navigating to HouseOwnerDashboardScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HouseOwnerDashboardScreen()),
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
                  color: (widget.user.isProfileComplete ? Colors.green : Colors.amber.shade800).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.user.profileCompletionPercentage}% ${widget.user.isProfileComplete ? l10n.complete : l10n.incomplete}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.user.isProfileComplete ? Colors.green : Colors.amber.shade800,
                  ),
                ),
              ),
              onTap: () => Navigator.pushNamed(context, MyProfileScreen.name),
            ),

            // 5. My Post
            AccountActionTile(
              icon: Icons.view_list_rounded,
              title: l10n.myPost,
              subtitle: l10n.localeName == 'bn'
                  ? 'আপনার পোস্ট করা বাসার তথ্য দেখুন, এডিট বা ডিলিট করুন'
                  : 'Manage, edit or delete your posted rental listings',
              onTap: () => navProvider.changeIndex(2),
            ),

            // 6. Post Now
            AccountActionTile(
              icon: Icons.add_home_work_outlined,
              title: l10n.postNow,
              subtitle: l10n.localeName == 'bn'
                  ? 'নতুন বাসা ভাড়ার বিজ্ঞাপন পোস্ট করুন'
                  : 'Publish a new home rental advertisement',
              onTap: () => navProvider.changeIndex(1),
            ),

            // 7. All Tenant Demands
            AccountActionTile(
              icon: Icons.campaign_rounded,
              title: l10n.allTenantDemands,
              subtitle: l10n.localeName == 'bn'
                  ? 'ভাড়াটিয়াদের ভাড়ার চাহিদা তালিকা দেখুন'
                  : 'Browse what potential tenants are looking for',
              onTap: () => Navigator.pushNamed(context, TenantDemandShowScreen.name),
            ),

            // --- 🛡️ Legal, Policy & Support Hub ---
            const SizedBox(height: 24),
            DecoratedSectionHeader(title: l10n.localeName == 'bn' ? 'তথ্য ও সহায়তা' : 'Support & Legal Policies'),
            const SizedBox(height: 12),

            // 8. Privacy Policy
            AccountActionTile(
              icon: Icons.privacy_tip_outlined,
              title: l10n.localeName == 'bn' ? 'গোপনীয়তা নীতি' : 'Privacy Policy',
              subtitle: l10n.localeName == 'bn'
                  ? 'আপনার ব্যক্তিগত তথ্যের নিরাপত্তা ও ব্যবহার সম্পর্কিত নীতিমালা'
                  : 'How BashaBondhu protects and respects your personal data',
              onTap: () => Navigator.pushNamed(context, PrivacyPolicyScreen.name, arguments: 'house_owner'),
            ),

            // 9. Support Policy
            AccountActionTile(
              icon: Icons.support_agent_rounded,
              title: l10n.localeName == 'bn' ? 'সাপোর্ট পলিসি' : 'Support Policy',
              subtitle: l10n.localeName == 'bn'
                  ? 'গ্রাহক সেবা, সহায়তা চ্যানেল ও রেসপন্স টাইম গাইডলাইন'
                  : 'Customer assistance, helpline hours and resolution process',
              onTap: () => Navigator.pushNamed(context, SupportPolicyScreen.name, arguments: 'house_owner'),
            ),

            // 10. Terms and Conditions
            AccountActionTile(
              icon: Icons.gavel_rounded,
              title: l10n.localeName == 'bn' ? 'ব্যবহারের শর্তাবলী' : 'Terms & Conditions',
              subtitle: l10n.localeName == 'bn'
                  ? 'প্ল্যাটফর্ম ব্যবহার, আইনি নিয়ম ও সাধারণ নির্দেশিকা'
                  : 'Rules, regulations and user agreements for BashaBondhu',
              onTap: () => Navigator.pushNamed(context, TermsConditionsScreen.name, arguments: 'house_owner'),
            ),

            // 11. Refund Policy
            AccountActionTile(
              icon: Icons.replay_rounded,
              title: l10n.localeName == 'bn' ? 'রিফান্ড পলিসি' : 'Refund Policy',
              subtitle: l10n.localeName == 'bn'
                  ? 'পেমেন্ট রিফান্ড, সাবস্ক্রিপশন বাতিল ও বিরোধ নিষ্পত্তির নিয়ম'
                  : 'Subscription cancellations, refund eligibility and settlement rules',
              onTap: () => Navigator.pushNamed(context, RefundPolicyScreen.name, arguments: 'house_owner'),
            ),

            // 12. FAQ
            AccountActionTile(
              icon: Icons.help_outline_rounded,
              title: l10n.localeName == 'bn' ? 'সচরাচর জিজ্ঞাসা (FAQ)' : 'Frequently Asked Questions (FAQ)',
              subtitle: l10n.localeName == 'bn'
                  ? 'বাসা খোঁজা, বুকিং ও অ্যাকাউন্ট সম্পর্কিত সাধারণ প্রশ্নোত্তর'
                  : 'Quick answers for finding homes, account security and features',
              onTap: () => Navigator.pushNamed(context, FaqScreen.name, arguments: 'house_owner'),
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

  Widget _buildOwnerSubscriptionBannerCard(
    BuildContext context,
    UserModel user,
    bool isDark,
    dynamic l10n,
    int postCount,
  ) {
    final bool isSubscribed = user.isSubscribed;
    final int freeDemandUnlocksLeft = user.freeDemandUnlocksRemaining;
    final int remainingPosts = (2 - postCount) > 0 ? (2 - postCount) : 0;
    final int usedPosts = postCount > 2 ? 2 : postCount;
    final int usedUnlocks = (2 - freeDemandUnlocksLeft) > 0 ? (2 - freeDemandUnlocksLeft) : 0;

    final String languageCode = Localizations.localeOf(context).languageCode;

    final String quotaText = isSubscribed
        ? l10n.ownerPremiumSubtitle
        : l10n.ownerQuotaStatus(
            remainingPosts.toLocalizedDigits(languageCode),
            usedPosts.toLocalizedDigits(languageCode),
            freeDemandUnlocksLeft.toLocalizedDigits(languageCode),
            usedUnlocks.toLocalizedDigits(languageCode),
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
                  ? [const Color(0xFF332910), const Color(0xFF241C08)]
                  : [const Color(0xFFFFF9E6), const Color(0xFFFFECC0)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSubscribed ? Colors.green.shade600 : Colors.amber.shade700,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSubscribed ? Colors.green : Colors.amber).withValues(alpha: 0.1),
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
                  color: (isSubscribed ? Colors.green : Colors.amber).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSubscribed ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                  color: isSubscribed ? Colors.green : Colors.amber.shade800,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSubscribed ? l10n.ownerPremiumActive : l10n.freeOwnerAccountLimited,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isSubscribed ? Colors.green : Colors.amber.shade900,
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
                backgroundColor: isSubscribed ? Colors.green.shade700 : Colors.amber.shade800,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(isSubscribed ? Icons.check_circle_rounded : Icons.star_rounded, size: 18),
              label: Text(
                isSubscribed ? l10n.subscriptionDetailsAndPackages : l10n.activateOwnerPackage,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
              },
            ),
          ),
        ],
      ),
    );
  }
}