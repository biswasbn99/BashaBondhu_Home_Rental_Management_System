import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/free_tier_policy_model.dart';
import '../../data/providers/subscription_provider.dart';
import 'subscription_history_screen.dart';
import '../widgets/payment_method_sheet.dart';
import '../widgets/subscription_status_details_modal.dart';

class TenantSubscriptionScreen extends StatelessWidget {
  const TenantSubscriptionScreen({super.key});

  static const String name = '/tenant-subscription';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final subProvider = context.watch<SubscriptionProvider>();

    if (user == null) {
      return Scaffold(
        appBar: MainAppBar(automaticallyImplyLeading: true),
        body: Center(child: Text(isBn ? 'অনুগ্রহ করে প্রথমে লগইন করুন' : 'Please log in first')),
      );
    }

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.subscriptionPackages,
            maxLines: 1,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.subscriptionHistory,
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubscriptionHistoryScreen(user: user),
                ),
              );
            },
          ),
          const LanguageActionButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Real-Time Active Plan or Free Tier Status Card ---
            StreamBuilder<FreeTierPolicyModel>(
              stream: subProvider.streamFreeTierPolicy(),
              initialData: subProvider.currentPolicy ?? FreeTierPolicyModel.defaultPolicy(),
              builder: (context, policySnap) {
                final policy = policySnap.data ?? FreeTierPolicyModel.defaultPolicy();
                if (user.isSubscribed) {
                  return _buildActivePlanCard(context, user, isDark, isBn, policy);
                } else {
                  return _buildFreeAccountCard(context, user, isDark, isBn, policy);
                }
              },
            ),

            // --- 2. Notice Message Modern Card (Localized) ---
            _buildNoticeCard(context, l10n, isDark, isBn),
            const SizedBox(height: 20),

            // --- 3. Packages Header ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    isBn ? 'প্যাকেজ নির্বাচন করুন' : 'Select Subscription Package',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        isBn ? 'তাৎক্ষণিক সক্রিয়' : 'Instant Activation',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- 4. Stream of Tenant Packages ---
            StreamBuilder<List<SubscriptionPlanModel>>(
              stream: subProvider.streamTenantPlans(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.themeColor),
                    ),
                  );
                }

                final plans = snapshot.data ?? [];
                if (plans.isEmpty) {
                  return Center(child: Text(isBn ? 'কোনো প্যাকেজ পাওয়া যায়নি' : 'No packages found'));
                }

                return Column(
                  children: plans.map((plan) {
                    return _TenantPackageCard(
                      plan: plan,
                      user: user,
                      isDark: isDark,
                      l10n: l10n,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, dynamic l10n, bool isDark, bool isBn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2D2A), const Color(0xFF162320)]
              : [const Color(0xFFE8F5F3), const Color(0xFFD4ECE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.themeColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.themeColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: AppColors.themeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'নম্বর আনলক ও সাপোর্ট প্যাকেজ' : 'Number Unlock & Support Packages',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.themeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.unlockPromptHeader,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? Colors.grey[200] : const Color(0xFF203532),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanCard(BuildContext context, UserModel user, bool isDark, bool isBn, FreeTierPolicyModel policy) {
    final expiry = user.expiryDateTime;
    final diffDays = expiry != null ? (expiry.difference(DateTime.now()).inHours / 24).ceil() : 0;
    final activePlans = user.activePlans;

    String formatQuota(int remaining) {
      if (remaining >= 999) {
        return isBn ? 'আনলিমিটেড' : 'Unlimited';
      }
      return remaining.toString().toLocalizedDigits(isBn ? 'bn' : 'en');
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E332A) : const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade600, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_rounded, color: Colors.green, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activePlans.length > 1
                          ? (isBn
                              ? 'আপনার ${activePlans.length.toString().toLocalizedDigits("bn")}টি সাবস্ক্রিপশন প্যাকেজ সক্রিয়'
                              : 'You Have ${activePlans.length} Active Subscription Plans')
                          : (isBn ? 'আপনার সাবস্ক্রিপশন প্যাকেজ সক্রিয়' : 'Active Subscription Plan'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBn
                          ? 'সর্বোচ্চ মেয়াদ বাকি: ${diffDays.toString().toLocalizedDigits("bn")} দিন'
                          : 'Max remaining validity: $diffDays Days',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Multiple Active Plans Badges
          if (activePlans.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: activePlans.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final p = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade400, width: 1),
                  ),
                  child: Text(
                    isBn
                        ? 'প্ল্যান $idx: ${p.titleBn.isNotEmpty ? p.titleBn : p.titleEn} (${p.remainingDays.toString().toLocalizedDigits("bn")} দিন বাকি)'
                        : 'Plan $idx: ${p.titleEn.isNotEmpty ? p.titleEn : p.titleBn} (${p.remainingDays}d left)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.green.shade300 : Colors.green.shade900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.green),
          const SizedBox(height: 10),
          Text(
            isBn ? 'প্যাকেজের বর্তমান অবশিষ্ট সর্বমোট কোটাঃ' : 'Total Remaining Quotas (Across Active Plans):',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          _buildQuotaRow(
            isBn ? '📝 ডিমান্ড পোস্ট বাকি' : 'Rental Demands Remaining',
            formatQuota(user.remainingPostsForPolicy(policy: policy)),
            user.canCreatePostForPolicy(policy: policy),
          ),
          const SizedBox(height: 6),
          _buildQuotaRow(
            isBn ? '🔓 বাড়িওয়ালার নম্বর আনলক বাকি' : 'Landlord Contact Unlocks Remaining',
            formatQuota(user.remainingContactUnlocksForPolicy(policy: policy)),
            user.canUnlockContactForPolicy(policy: policy),
          ),
          const SizedBox(height: 6),
          _buildQuotaRow(
            isBn ? '📍 সাব-এরিয়া লোকেশন আনলক বাকি' : 'Sub-Area Unlocks Remaining',
            formatQuota(user.remainingTenantSubAreaUnlocks(policy: policy)),
            user.canUnlockSubAreaForTenant(policy: policy),
          ),
          const SizedBox(height: 6),
          _buildQuotaRow(
            isBn ? '🖼️ অতিরিক্ত ছবি দেখার সুবিধা' : 'Additional Photos Access',
            user.canViewAdditionalPhotos ? (isBn ? 'সক্রিয়' : 'Active') : (isBn ? 'লক' : 'Locked'),
            user.canViewAdditionalPhotos,
          ),
          const SizedBox(height: 6),
          _buildQuotaRow(
            isBn ? '📍 নিকটবর্তী সার্চ বাকি' : 'Nearby Searches Remaining',
            formatQuota(user.remainingNearbySearchesForPolicy(policy: policy)),
            user.canPerformNearbySearchForPolicy(policy: policy),
          ),
          const SizedBox(height: 6),
          _buildQuotaRow(
            isBn ? '🗺️ গুগল ম্যাপ দিকনির্দেশনা বাকি' : 'Map Directions Remaining',
            formatQuota(user.remainingMapDirectionsForPolicy(policy: policy)),
            user.canOpenMapDirectionsForPolicy(policy: policy),
          ),
          const SizedBox(height: 6),
          _buildQuotaRow(
            isBn ? '🤖 এআই সহকারী প্রশ্ন বাকি' : 'AI Assistant Queries Remaining',
            formatQuota(user.remainingAiQueriesForRole(policy: policy)),
            user.canUseAiAssistantForRole(policy: policy),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBn
                        ? '💡 কোটা শেষ হলে নিচে থেকে যেকোনো প্যাকেজ নিয়ে সাথে সাথে আপগ্রেড করতে পারবেন। সব প্ল্যানের কোটা একাউন্টে যুক্ত থাকবে।'
                        : '💡 If quota runs out, you can instantly purchase another plan below to upgrade. Quotas accumulate automatically.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.green),
              label: Text(
                isBn ? 'সকল প্ল্যানের বিস্তারিত ব্রেকডাউন দেখুন' : 'View Detailed Active Plans Breakdown',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
              ),
              onPressed: () => SubscriptionStatusDetailsModal.show(context, user),
            ),
          ),
        ],
      ),
    );
  }

  /// Dedicated Free Tier Baseline Quotas Card for Tenant (7 Facilities)
  Widget _buildFreeAccountCard(
    BuildContext context,
    UserModel user,
    bool isDark,
    bool isBn,
    FreeTierPolicyModel policy,
  ) {
    String formatLimit(int limit) {
      if (limit == -1) return isBn ? 'আনলিমিটেড' : 'Unlimited';
      if (limit <= 0) return isBn ? 'লক (০)' : 'Locked (0)';
      return '${limit.toString().toLocalizedDigits(isBn ? "bn" : "en")}${isBn ? "টি" : ""}';
    }

    String formatRemaining(int remaining, int limit) {
      if (limit == -1) return isBn ? 'আনলিমিটেড বাকি' : 'Unlimited left';
      if (limit <= 0) return isBn ? 'লক (বন্ধ)' : 'Locked';
      if (remaining <= 0) return isBn ? '০টি বাকি (শেষ)' : '0 left (Exhausted)';
      return '${remaining.toString().toLocalizedDigits(isBn ? "bn" : "en")}${isBn ? "টি বাকি" : " left"}';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132A26) : const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF0D9488), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isBn ? 'ভাড়াটিয়া ফ্রি পলিসি ও রিয়েল-টাইম কোটা' : 'Tenant Free Baseline Quotas',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0D9488), width: 0.8),
                          ),
                          child: Text(
                            isBn ? 'লাইভ আপডেট' : 'Live Sync',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBn
                          ? 'এডমিন কর্তৃক নির্ধারিত ফ্রি ব্যবহারের সীমা (৭টি সুবিধা):'
                          : 'Admin-configured baseline free limits (7 Facilities):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF0D9488)),
          const SizedBox(height: 10),

          // 1. Max Rental Demand Allowed Limit
          _buildPolicyFeatureRow(
            icon: Icons.post_add_rounded,
            title: isBn ? '১. ভাড়ার চাহিদা (Demand) পোস্ট লিমিট' : '1. Max Rental Demand Limit',
            limitText: formatLimit(policy.tenantMaxDemands),
            statusText: formatRemaining(user.remainingPostsForPolicy(policy: policy), policy.tenantMaxDemands),
            isAvailable: user.canCreatePostForPolicy(policy: policy),
            isDark: isDark,
            isBn: isBn,
          ),
          const SizedBox(height: 8),

          // 2. Landlord Contact Numbers Unlock Limit
          _buildPolicyFeatureRow(
            icon: Icons.phone_in_talk_rounded,
            title: isBn ? '২. বাড়িওয়ালার নম্বর আনলক লিমিট' : '2. Landlord Contacts Unlock Limit',
            limitText: formatLimit(policy.tenantUnlockNumbers),
            statusText: formatRemaining(user.remainingContactUnlocksForPolicy(policy: policy), policy.tenantUnlockNumbers),
            isAvailable: user.canUnlockContactForPolicy(policy: policy),
            isDark: isDark,
            isBn: isBn,
          ),
          const SizedBox(height: 8),

          // 3. Sub-Area Location Unlock Limit
          _buildPolicyFeatureRow(
            icon: Icons.location_city_rounded,
            title: isBn ? '৩. সাব-এরিয়া লোকেশন আনলক লিমিট' : '3. Sub-Area Location Unlock Limit',
            limitText: formatLimit(policy.tenantSubAreaUnlocks),
            statusText: formatRemaining(user.remainingTenantSubAreaUnlocks(policy: policy), policy.tenantSubAreaUnlocks),
            isAvailable: user.canUnlockSubAreaForTenant(policy: policy),
            isDark: isDark,
            isBn: isBn,
          ),
          const SizedBox(height: 8),

          // 4. Full Photo Gallery Access Limit
          _buildPolicyFeatureRow(
            icon: Icons.photo_library_rounded,
            title: isBn ? '৪. সম্পূর্ণ ফটো গ্যালারি এক্সেস লিমিট' : '4. Photo Gallery Access Limit',
            limitText: formatLimit(policy.tenantFullPhotoGallery),
            statusText: formatRemaining(user.remainingPhotoGalleryUnlocks(policy: policy), policy.tenantFullPhotoGallery),
            isAvailable: user.canUnlockPhotoGallery(policy: policy),
            isDark: isDark,
            isBn: isBn,
          ),
          const SizedBox(height: 8),

          // 5. Nearby / Radius Search Limit
          _buildPolicyFeatureRow(
            icon: Icons.radar_rounded,
            title: isBn ? '৫. কাছাকাছি (রেডিয়াস) সার্চ লিমিট' : '5. Nearby Radius Search Limit',
            limitText: formatLimit(policy.tenantNearbySearches),
            statusText: formatRemaining(user.remainingNearbySearchesForPolicy(policy: policy), policy.tenantNearbySearches),
            isAvailable: user.canPerformNearbySearchForPolicy(policy: policy),
            isDark: isDark,
            isBn: isBn,
          ),
          const SizedBox(height: 8),

          // 6. Google Map Directions Limit
          _buildPolicyFeatureRow(
            icon: Icons.directions_rounded,
            title: isBn ? '৬. গুগল ম্যাপস দিকনির্দেশনা লিমিট' : '6. Map Directions Limit',
            limitText: formatLimit(policy.tenantMapDirections),
            statusText: formatRemaining(user.remainingMapDirectionsForPolicy(policy: policy), policy.tenantMapDirections),
            isAvailable: user.canOpenMapDirectionsForPolicy(policy: policy),
            isDark: isDark,
            isBn: isBn,
          ),
          const SizedBox(height: 8),

          // 7. AI Assistant Search Limit
          _buildPolicyFeatureRow(
            icon: Icons.auto_awesome_rounded,
            title: isBn ? '৭. এআই সহকারী সার্চ লিমিট' : '7. AI Assistant Search Limit',
            limitText: formatLimit(policy.tenantAiAssistant),
            statusText: formatRemaining(user.remainingAiQueriesForRole(policy: policy), policy.tenantAiAssistant),
            isAvailable: user.canUseAiAssistantForRole(policy: policy),
            isDark: isDark,
            isBn: isBn,
          ),

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBn
                        ? '💡 যেকোনো ফ্রি কোটা শেষ হলে নিচে থেকে আপনার পছন্দের প্যাকেজ নির্বাচন করে এক-ক্লিকে সাবস্ক্রাইব করুন।'
                        : '💡 Once free quota is exhausted, choose from the packages below to unlock full unlimited features.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF115E59),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0D9488)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.analytics_outlined, size: 16, color: Color(0xFF0D9488)),
              label: Text(
                isBn ? 'সকল সুবিধার বিস্তারিত হিসাব দেখুন' : 'View Detailed Usage Breakdown',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488)),
              ),
              onPressed: () => SubscriptionStatusDetailsModal.show(context, user),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyFeatureRow({
    required IconData icon,
    required String title,
    required String limitText,
    required String statusText,
    required bool isAvailable,
    required bool isDark,
    required bool isBn,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132320) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.teal.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isAvailable ? const Color(0xFF0D9488) : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isBn ? "লিমিট" : "Limit"}: $limitText',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? Colors.green : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaRow(String label, String value, bool isAvailable) {
    return Row(
      children: [
        Icon(
          isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 15,
          color: isAvailable ? Colors.green : Colors.redAccent,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12.5)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isAvailable ? Colors.green.shade700 : Colors.redAccent,
          ),
        ),
      ],
    );
  }
}

class _TenantPackageCard extends StatelessWidget {
  const _TenantPackageCard({
    required this.plan,
    required this.user,
    required this.isDark,
    required this.l10n,
  });

  final SubscriptionPlanModel plan;
  final UserModel user;
  final bool isDark;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final effectivePrice = plan.effectivePrice;
    final hasOffer = plan.hasActiveOffer;
    final isPopular = plan.isPopular;

    final title = isBn
        ? (plan.titleBn.isNotEmpty ? plan.titleBn : plan.titleEn)
        : (plan.titleEn.isNotEmpty ? plan.titleEn : plan.titleBn);

    final description = isBn
        ? (plan.descriptionBn.isNotEmpty ? plan.descriptionBn : plan.descriptionEn)
        : (plan.descriptionEn.isNotEmpty ? plan.descriptionEn : plan.descriptionBn);

    final perks = isBn ? plan.perksBn : plan.perksEn;
    final rawPerks = perks.isNotEmpty ? perks : (isBn ? plan.perksEn : plan.perksBn);
    final displayPerks = rawPerks.where((p) {
      final lower = p.toLowerCase();
      return !lower.contains('ad-free') && !lower.contains('বিজ্ঞাপন মুক্ত');
    }).toList();

    final offerBadge = isBn
        ? (plan.offerBadgeTextBn.isNotEmpty ? plan.offerBadgeTextBn : plan.offerBadgeTextEn)
        : (plan.offerBadgeTextEn.isNotEmpty ? plan.offerBadgeTextEn : plan.offerBadgeTextBn);

    final formattedEffectivePrice = isBn
        ? '৳${effectivePrice.toInt().toString().toLocalizedDigits('bn')}'
        : '৳${effectivePrice.toInt()}';

    final formattedRegularPrice = isBn
        ? '৳${plan.regularPrice.toInt().toString().toLocalizedDigits('bn')}'
        : '৳${plan.regularPrice.toInt()}';

    final formattedDuration = isBn
        ? '/ ${plan.durationBn.isNotEmpty ? plan.durationBn : "${plan.durationDays.toString().toLocalizedDigits('bn')} দিন"}'
        : '/ ${plan.durationEn.isNotEmpty ? plan.durationEn : "${plan.durationDays} Days"}';

    final bool isSubscribed = user.isSubscribed;
    final bool isCurrentPlan = isSubscribed && user.subscriptionPlanId == plan.id;
    final expiry = user.expiryDateTime;
    final diffDays = expiry != null ? (expiry.difference(DateTime.now()).inHours / 24).ceil() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172220) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentPlan
              ? Colors.green.shade600
              : (isPopular
                  ? AppColors.themeColor
                  : (isDark ? const Color(0xFF263936) : const Color(0xFFE2EBE9))),
          width: isCurrentPlan ? 2.2 : (isPopular ? 2 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentPlan
                ? Colors.green.withValues(alpha: 0.15)
                : (isPopular
                    ? AppColors.themeColor.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04)),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Name and Duration
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: (isCurrentPlan || hasOffer || isPopular) ? 75 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pricing Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formattedEffectivePrice,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isCurrentPlan
                            ? Colors.green.shade600
                            : (isPopular ? AppColors.themeColor : AppColors.themeColor),
                      ),
                    ),
                    Text(
                      formattedDuration,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasOffer)
                      Text(
                        formattedRegularPrice,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Structured Quota Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _quotaBadge(
                      Icons.post_add_rounded,
                      isBn
                          ? 'পোস্ট: ${plan.maxPostsLimit == -1 ? "আনলিমিটেড" : plan.maxPostsLimit.toString().toLocalizedDigits("bn")}'
                          : 'Posts: ${plan.maxPostsLimit == -1 ? "Unlimited" : plan.maxPostsLimit}',
                      Colors.blue,
                    ),
                    _quotaBadge(
                      Icons.lock_open_rounded,
                      isBn
                          ? 'আনলক: ${plan.unlockNumbersLimit == -1 ? "আনলিমিটেড" : plan.unlockNumbersLimit.toString().toLocalizedDigits("bn")}'
                          : 'Unlocks: ${plan.unlockNumbersLimit == -1 ? "Unlimited" : plan.unlockNumbersLimit}',
                      Colors.orange,
                    ),
                    _quotaBadge(
                      Icons.photo_library_rounded,
                      isBn
                          ? (plan.canAccessAdditionalPhotos ? 'সকল ছবি' : 'টেমপ্লেট ছবি')
                          : (plan.canAccessAdditionalPhotos ? 'All Photos' : 'Template Photo'),
                      Colors.teal,
                    ),
                    _quotaBadge(
                      Icons.near_me_rounded,
                      isBn
                          ? 'সার্চ: ${plan.nearbySearchLimit == -1 ? "আনলিমিটেড" : plan.nearbySearchLimit.toString().toLocalizedDigits("bn")}'
                          : 'Search: ${plan.nearbySearchLimit == -1 ? "Unlimited" : plan.nearbySearchLimit}',
                      Colors.indigo,
                    ),
                    _quotaBadge(
                      Icons.directions_rounded,
                      isBn
                          ? 'ডিরেকশন: ${plan.mapDirectionsLimit == -1 ? "আনলিমিটেড" : plan.mapDirectionsLimit.toString().toLocalizedDigits("bn")}'
                          : 'Directions: ${plan.mapDirectionsLimit == -1 ? "Unlimited" : plan.mapDirectionsLimit}',
                      Colors.deepPurple,
                    ),
                    _quotaBadge(
                      Icons.auto_awesome_rounded,
                      isBn
                          ? 'এআই: ${plan.aiAssistantLimit == -1 ? "আনলিমিটেড" : plan.aiAssistantLimit.toString().toLocalizedDigits("bn")}'
                          : 'AI: ${plan.aiAssistantLimit == -1 ? "Unlimited" : plan.aiAssistantLimit}',
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Perks Header
                Text(
                  isBn ? 'প্যাকেজ অ্যাক্টিভ করলে যা যা পাবেনঃ' : 'Included Plan Perks:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCurrentPlan
                        ? Colors.green.shade600
                        : (isPopular ? AppColors.themeColor : AppColors.themeColor),
                  ),
                ),
                const SizedBox(height: 8),

                // Perks List
                Column(
                  children: displayPerks.map((perk) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: isCurrentPlan
                                ? Colors.green.shade600
                                : AppColors.themeColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              perk,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Choose Plan Button or Active Plan Indicator
                if (isCurrentPlan) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                      label: Text(
                        isBn ? 'বর্তমান সক্রিয় প্যাকেজ' : 'Currently Active Plan',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.green),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green, width: 1.5),
                        backgroundColor: Colors.green.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showActivePlanDialog(context, isBn, diffDays, title),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: Text(
                        '$formattedEffectivePrice • ${isBn ? "পুনরায় কিনুন / কোটা বৃদ্ধি" : "Renew / Add More Quota"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        PaymentMethodBottomSheet.show(
                          context: context,
                          plan: plan,
                          user: user,
                        );
                      },
                    ),
                  ),
                ] else if (isSubscribed)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.upgrade_rounded, size: 18),
                      label: Text(
                        '$formattedEffectivePrice • ${isBn ? "আপগ্রেড / প্যাকেজ যোগ করুন" : "Add / Upgrade Plan"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isPopular ? AppColors.themeColor : Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        PaymentMethodBottomSheet.show(
                          context: context,
                          plan: plan,
                          user: user,
                        );
                      },
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        PaymentMethodBottomSheet.show(
                          context: context,
                          plan: plan,
                          user: user,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isPopular ? AppColors.themeColor : null,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '$formattedEffectivePrice • ${l10n.choosePlan}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Offer / Active / Popular Tag Top Right
          if (isCurrentPlan)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      isBn ? 'বর্তমান প্যাকেজ' : 'ACTIVE PLAN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (hasOffer && offerBadge.isNotEmpty)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  offerBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            )
          else if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.themeColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  isBn ? 'জনপ্রিয়' : 'POPULAR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showActivePlanDialog(BuildContext context, bool isBn, int remainingDays, String planName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isBn ? 'প্যাকেজ সক্রিয় আছে' : 'Plan Already Active',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isBn
              ? 'আপনার "$planName" প্যাকেজটি বর্তমানে সক্রিয় রয়েছে।\n\nমেয়াদ বাকি: ${remainingDays.toString().toLocalizedDigits("bn")} দিন।\nমেয়াদ শেষ না হওয়া পর্যন্ত এটি পুনরায় কেনার প্রয়োজন নেই।'
              : 'Your "$planName" plan is currently active.\n\nRemaining: $remainingDays days.\nYou cannot repurchase it until it expires.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বুঝেছি' : 'OK'),
          ),
        ],
      ),
    );
  }

  Widget _quotaBadge(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
