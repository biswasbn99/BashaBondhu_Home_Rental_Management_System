import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/free_tier_policy_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/providers/subscription_provider.dart';
import '../screens/house_owner_subscription_screen.dart';
import '../screens/tenant_subscription_screen.dart';

class SubscriptionStatusDetailsModal extends StatelessWidget {
  final UserModel user;

  const SubscriptionStatusDetailsModal({
    super.key,
    required this.user,
  });

  static Future<void> show(BuildContext context, UserModel user) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionStatusDetailsModal(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';
    final isSub = user.isSubscribed;
    final activePlans = user.activePlans;
    final subProvider = context.watch<SubscriptionProvider>();

    return StreamBuilder<FreeTierPolicyModel>(
      stream: subProvider.streamFreeTierPolicy(),
      builder: (context, snapshot) {
        final policy = snapshot.data ?? FreeTierPolicyModel.defaultPolicy();

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16211F) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isSub ? const Color(0xFF10B981) : Colors.amber.shade800)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSub ? Icons.workspace_premium_rounded : Icons.card_giftcard_rounded,
                        color: isSub ? const Color(0xFF10B981) : Colors.amber.shade800,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSub
                                ? (isBn ? 'আপনার সাবস্ক্রিপশন প্ল্যানসমূহ' : 'Active Subscription Plans')
                                : (isBn ? 'ফ্রি অ্যাকাউন্ট সুবিধা ও ব্যবহার' : 'Free Account Facilities & Usage'),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          Text(
                            isSub
                                ? (isBn
                                    ? '${activePlans.length.toString().toLocalizedDigits("bn")}টি সক্রিয় প্ল্যান চালু আছে'
                                    : '${activePlans.length} active subscription plan(s)')
                                : (isBn
                                    ? 'ফ্রি অ্যাকাউন্টে ব্যবহৃত ও অবশিষ্ট কোটা'
                                    : 'Current free tier usage and remaining limits'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: isSub
                      ? _buildActivePlansList(context, activePlans, policy, isDark, isBn, languageCode)
                      : _buildFreeTierUsageBreakdown(context, policy, isDark, isBn, languageCode),
                ),
              ),

              // Modal Footer Action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111A18) : const Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF22302D) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: !isSub
                              ? Colors.deepOrange
                              : (user.canUpgradeOrAddPlan(policy: policy)
                                  ? const Color(0xFF0D9488)
                                  : (isDark ? Colors.grey[800] : Colors.grey[400])),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: Icon(
                          !isSub
                              ? Icons.rocket_launch_rounded
                              : (user.canUpgradeOrAddPlan(policy: policy)
                                  ? Icons.add_circle_outline_rounded
                                  : Icons.lock_outline_rounded),
                          size: 18,
                        ),
                        label: Text(
                          isSub
                              ? (user.canUpgradeOrAddPlan(policy: policy)
                                  ? (isBn ? '+ নতুন প্ল্যান নিন / আপগ্রেড করুন' : '+ Upgrade / Add New Plan')
                                  : (isBn ? 'কোটা অবশিষ্ট রয়েছে (লক)' : 'Quotas Remaining (Locked)'))
                              : (isBn ? '🚀 প্রিমিয়াম প্ল্যানে আপগ্রেড করুন' : '🚀 Upgrade to Premium Plan'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () {
                          if (isSub && !user.canUpgradeOrAddPlan(policy: policy)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isBn
                                      ? 'আপনার বর্তমান সক্রিয় প্যাকেজের সকল কোটা এখনও অবশিষ্ট রয়েছে। যেকোন একটি কোটা শেষ হলে আপনি নতুন প্ল্যান যোগ বা আপগ্রেড করতে পারবেন।'
                                      : 'All quotas in your current active plan(s) are still available. You can add or upgrade a plan once any quota is exhausted.',
                                ),
                                backgroundColor: Colors.orange.shade800,
                                duration: const Duration(seconds: 4),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          if (user.isHouseOwner) {
                            Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
                          } else {
                            Navigator.pushNamed(context, TenantSubscriptionScreen.name);
                          }
                        },
                      ),
                    ),
                    if (isSub && !user.canUpgradeOrAddPlan(policy: policy))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          isBn
                              ? 'ℹ️ যেকোনো একটি কোটা ০ হলে পরবর্তী প্ল্যান কেনার সুযোগ উন্মুক্ত হবে।'
                              : 'ℹ️ You can purchase another plan as soon as any quota reaches 0.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // FREE TIER USAGE BREAKDOWN (FOR FREE ACCOUNTS)
  // ==========================================================================

  Widget _buildFreeTierUsageBreakdown(
    BuildContext context,
    FreeTierPolicyModel policy,
    bool isDark,
    bool isBn,
    String languageCode,
  ) {
    final isTenant = user.isTenant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Free Notice Info Strip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade800.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.shade800.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBn
                      ? 'আপনার অ্যাকাউন্ট বর্তমানে ফ্রি প্ল্যানে রয়েছে। ফ্রি কোটা শেষ হয়ে গেলে আপনি যেকোনো সময় আকর্ষণীয় সাপোর্ট প্যাকেজে আপগ্রেড করতে পারবেন।'
                      : 'You are on the Free tier. When your free quotas are exhausted, upgrade to a support package to unlock full features.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          isBn ? 'ফ্রি সুবিধার বিস্তারিত হিসাব:' : 'Free Tier Facilities Breakdown:',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 12),

        if (isTenant) ...[
          // Tenant 7 Facilities
          _facilityUsageCard(
            icon: Icons.post_add_rounded,
            title: isBn ? 'ভাড়ার চাহিদা (Demand) পোস্ট' : 'Rental Demands Posted',
            used: user.subscriptionPostsCount,
            limit: policy.tenantMaxDemands,
            isBn: isBn,
            isDark: isDark,
          ),
          _facilityUsageCard(
            icon: Icons.lock_open_rounded,
            title: isBn ? 'বাড়িওয়ালার ফোন ও হোয়াটসঅ্যাপ নম্বর আনলক' : 'Landlord Contact Numbers Unlocked',
            used: user.unlockedPropertyIds.length,
            limit: policy.tenantUnlockNumbers,
            isBn: isBn,
            isDark: isDark,
          ),
          _facilityUsageCard(
            icon: Icons.pin_drop_rounded,
            title: isBn ? 'বাসার সঠিক সাব-এরিয়া লোকেশন' : 'Sub-area Exact Locations',
            used: user.unlockedPropertySubAreaIds.length,
            limit: policy.tenantSubAreaUnlocks,
            isBn: isBn,
            isDark: isDark,
          ),
          _facilityUsageCard(
            icon: Icons.photo_library_rounded,
            title: isBn ? 'বাড়ির সম্পূর্ণ ফটো গ্যালারি এক্সেস' : 'Full Photo Gallery Access',
            used: user.unlockedPhotoPropertyIds.length,
            limit: policy.tenantFullPhotoGallery,
            isBn: isBn,
            isDark: isDark,
          ),
          _facilityUsageCard(
            icon: Icons.radar_rounded,
            title: isBn ? 'কাছাকাছি (রেডিয়াস) সার্চ' : 'Nearby Radius Searches',
            used: user.radiusSearchCount,
            limit: policy.tenantNearbySearches,
            isBn: isBn,
            isDark: isDark,
          ),
          _facilityUsageCard(
            icon: Icons.directions_rounded,
            title: isBn ? 'গুগল ম্যাপস নেভিগেশন ও ডিরেকশন' : 'Google Maps Directions',
            used: user.subscriptionMapDirectionsCount,
            limit: policy.tenantMapDirections,
            isBn: isBn,
            isDark: isDark,
          ),
          _facilityUsageCard(
            icon: Icons.auto_awesome_rounded,
            title: isBn ? 'বাসাবন্ধু এআই সহকারী প্রশ্ন ও সার্চ' : 'AI Assistant Queries',
            used: user.aiAssistantQueryCount,
            limit: policy.tenantAiAssistant,
            isBn: isBn,
            isDark: isDark,
          ),
        ] else ...[
          // House Owner 4 Facilities
          _facilityUsageCard(
            icon: Icons.home_work_rounded,
            title: isBn ? 'বাসাভাড়া বিজ্ঞাপন পোস্ট' : 'Rental Listings Published',
            used: user.subscriptionPostsCount,
            limit: policy.ownerMaxListings,
            isBn: isBn,
            isDark: isDark,
          ),
          _facilityUsageCard(
            icon: Icons.phone_iphone_rounded,
            title: isBn ? 'ভাড়াটিয়াদের ফোন নম্বর আনলক' : 'Tenant Contact Numbers Unlocked',
            used: user.unlockedDemandIds.length,
            limit: policy.ownerUnlockNumbers,
            isBn: isBn,
            isDark: isDark,
          ),
          _facilityUsageCard(
            icon: Icons.pin_drop_rounded,
            title: isBn ? 'ভাড়াটিয়ার চাহিদার সাব-এরিয়া লোকেশন' : 'Demand Sub-area Locations',
            used: user.unlockedDemandSubAreaIds.length,
            limit: policy.ownerSubAreaUnlocks,
            isBn: isBn,
            isDark: isDark,
          ),
          _facilityUsageCard(
            icon: Icons.auto_awesome_rounded,
            title: isBn ? 'বাসাবন্ধু এআই সহকারী প্রশ্ন ও সার্চ' : 'AI Assistant Queries',
            used: user.aiAssistantQueryCount,
            limit: policy.ownerAiAssistant,
            isBn: isBn,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _facilityUsageCard({
    required IconData icon,
    required String title,
    required int used,
    required int limit,
    required bool isBn,
    required bool isDark,
  }) {
    final bool isDisabled = limit == 0;
    final bool isUnlimited = limit == -1;
    final int effectiveUsed = limit > 0 ? used.clamp(0, limit) : used;
    final int remaining = isUnlimited ? 999 : (limit - used).clamp(0, limit > 0 ? limit : 0);
    final double progress = (isUnlimited || isDisabled || limit <= 0)
        ? 0.0
        : (effectiveUsed / limit).clamp(0.0, 1.0);

    Color badgeColor;
    String badgeText;

    if (isDisabled) {
      badgeColor = Colors.grey;
      badgeText = isBn ? '🔒 লক (সাবস্ক্রিপশন প্রয়োজন)' : '🔒 Locked';
    } else if (isUnlimited) {
      badgeColor = Colors.green;
      badgeText = isBn ? 'আনলিমিটেড' : 'Unlimited';
    } else if (remaining <= 0) {
      badgeColor = Colors.redAccent;
      badgeText = isBn ? '❌ সীমা শেষ' : 'Exhausted';
    } else {
      badgeColor = const Color(0xFF0D9488);
      badgeText = isBn
          ? '${remaining.toString().toLocalizedDigits("bn")}টি বাকি'
          : '$remaining Left';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2825) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3D39) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: badgeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          if (!isDisabled && !isUnlimited && limit > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  remaining > 0 ? const Color(0xFF0D9488) : Colors.redAccent,
                ),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBn
                      ? 'ব্যবহৃত: ${effectiveUsed.toString().toLocalizedDigits("bn")}'
                      : 'Used: $effectiveUsed',
                  style: TextStyle(fontSize: 10.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                Text(
                  isBn
                      ? 'সর্বোচ্চ সীমা: ${limit.toString().toLocalizedDigits("bn")}'
                      : 'Max limit: $limit',
                  style: TextStyle(fontSize: 10.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // ACTIVE PLANS LIST (FOR SUBSCRIBED USERS WITH PLAN 1, PLAN 2, ETC.)
  // ==========================================================================

  Widget _buildActivePlansList(
    BuildContext context,
    List<UserSubscriptionPlan> plans,
    FreeTierPolicyModel policy,
    bool isDark,
    bool isBn,
    String languageCode,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Remaining Quotas Card (Across Active Plans)
        _buildTotalRemainingQuotasCard(context, policy, isDark, isBn, languageCode),

        Text(
          isBn ? 'সক্রিয় প্ল্যানসমূহের তালিকা ও কোটা:' : 'Active Plans & Quotas:',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 12),

        ...plans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF192523) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Ribbon Header (Overflow safe)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isBn
                                    ? 'প্ল্যান ${(index + 1).toString().toLocalizedDigits("bn")}'
                                    : 'Plan #${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                plan.localizedTitle(isBn),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isBn
                              ? 'মেয়াদ: ${plan.remainingDays.toString().toLocalizedDigits("bn")} দিন বাকি'
                              : 'Valid: ${plan.remainingDays}d left',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expiry Date Strip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        isBn
                            ? 'মেয়াদ শেষ: ${dateFormat.format(plan.expiresAt)}'
                            : 'Expires: ${dateFormat.format(plan.expiresAt)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 12),
                ),

                // Plan Specific Quotas (Filtered by Role)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    children: [
                      if (user.isHouseOwner) ...[
                        _planQuotaRow(
                          Icons.post_add_rounded,
                          isBn ? 'বাসাভাড়া বিজ্ঞাপন পোস্ট' : 'Rental Listings Quota',
                          plan.postsUsed,
                          plan.maxPostsLimit,
                          isBn,
                        ),
                        _planQuotaRow(
                          Icons.lock_open_rounded,
                          isBn ? 'ভাড়াটিয়া নম্বর আনলক' : 'Tenant Contact Unlocks',
                          plan.unlocksUsed,
                          plan.unlockNumbersLimit,
                          isBn,
                        ),
                        _planQuotaRow(
                          Icons.pin_drop_rounded,
                          isBn ? 'চাহিদা সাব-এরিয়া আনলক' : 'Demand Sub-area Access',
                          plan.subAreaUnlocksUsed,
                          plan.subAreaUnlockLimit,
                          isBn,
                        ),
                        _planQuotaRow(
                          Icons.auto_awesome_rounded,
                          isBn ? 'এআই সহকারী সার্চ' : 'AI Assistant Queries',
                          plan.aiAssistantUsed,
                          plan.aiAssistantLimit,
                          isBn,
                        ),
                      ] else ...[
                        _planQuotaRow(
                          Icons.post_add_rounded,
                          isBn ? 'ভাড়ার চাহিদা পোস্ট' : 'Rental Demands Quota',
                          plan.postsUsed,
                          plan.maxPostsLimit,
                          isBn,
                        ),
                        _planQuotaRow(
                          Icons.lock_open_rounded,
                          isBn ? 'বাড়িওয়ালার নম্বর আনলক' : 'Landlord Contact Unlocks',
                          plan.unlocksUsed,
                          plan.unlockNumbersLimit,
                          isBn,
                        ),
                        _planQuotaRow(
                          Icons.pin_drop_rounded,
                          isBn ? 'বাসার সাব-এরিয়া এক্সেস' : 'Property Sub-area Access',
                          plan.subAreaUnlocksUsed,
                          plan.subAreaUnlockLimit,
                          isBn,
                        ),
                        _planQuotaRow(
                          Icons.photo_library_rounded,
                          isBn ? 'ফটো গ্যালারি এক্সেস' : 'Photo Gallery Access',
                          plan.photoGalleryUsed,
                          plan.fullPhotoGalleryLimit,
                          isBn,
                        ),
                        _planQuotaRow(
                          Icons.radar_rounded,
                          isBn ? 'নিকটবর্তী সার্চ' : 'Nearby Searches',
                          plan.nearbySearchUsed,
                          plan.nearbySearchLimit,
                          isBn,
                        ),
                        _planQuotaRow(
                          Icons.directions_rounded,
                          isBn ? 'গুগল ম্যাপস ডিরেকশন' : 'Map Directions',
                          plan.mapDirectionsUsed,
                          plan.mapDirectionsLimit,
                          isBn,
                        ),
                        _planQuotaRow(
                          Icons.auto_awesome_rounded,
                          isBn ? 'এআই সহকারী সার্চ' : 'AI Assistant Queries',
                          plan.aiAssistantUsed,
                          plan.aiAssistantLimit,
                          isBn,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Summary Card of All Quotas combined across active plans
  Widget _buildTotalRemainingQuotasCard(
    BuildContext context,
    FreeTierPolicyModel policy,
    bool isDark,
    bool isBn,
    String languageCode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132220) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stacked_line_chart_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBn ? 'মোট অবশিষ্ট কোটা (সকল সক্রিয় প্ল্যান মিলে):' : 'Total Remaining Quotas (Across Active Plans):',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (user.isHouseOwner) ...[
            _summaryQuotaRow(
              Icons.post_add_rounded,
              isBn ? 'বাসাভাড়া বিজ্ঞাপন পোস্ট' : 'Rental Listings Quota',
              user.remainingPostsForPolicy(policy: policy),
              isBn,
              languageCode,
            ),
            _summaryQuotaRow(
              Icons.lock_open_rounded,
              isBn ? 'ভাড়াটিয়া নম্বর আনলক' : 'Tenant Contact Unlocks',
              user.remainingContactUnlocksForPolicy(policy: policy),
              isBn,
              languageCode,
            ),
            _summaryQuotaRow(
              Icons.pin_drop_rounded,
              isBn ? 'চাহিদা সাব-এরিয়া আনলক' : 'Demand Sub-area Access',
              user.remainingOwnerSubAreaUnlocks(policy: policy),
              isBn,
              languageCode,
            ),
            _summaryQuotaRow(
              Icons.auto_awesome_rounded,
              isBn ? 'এআই সহকারী সার্চ' : 'AI Assistant Queries',
              user.remainingAiQueriesForRole(policy: policy),
              isBn,
              languageCode,
            ),
          ] else ...[
            _summaryQuotaRow(
              Icons.post_add_rounded,
              isBn ? 'ভাড়ার চাহিদা পোস্ট' : 'Rental Demands Quota',
              user.remainingPostsForPolicy(policy: policy),
              isBn,
              languageCode,
            ),
            _summaryQuotaRow(
              Icons.lock_open_rounded,
              isBn ? 'বাড়িওয়ালার নম্বর আনলক' : 'Landlord Contact Unlocks',
              user.remainingContactUnlocksForPolicy(policy: policy),
              isBn,
              languageCode,
            ),
            _summaryQuotaRow(
              Icons.pin_drop_rounded,
              isBn ? 'বাসার সাব-এরিয়া এক্সেস' : 'Property Sub-area Access',
              user.remainingTenantSubAreaUnlocks(policy: policy),
              isBn,
              languageCode,
            ),
            _summaryQuotaRow(
              Icons.photo_library_rounded,
              isBn ? 'ফটো গ্যালারি এক্সেস' : 'Photo Gallery Access',
              user.remainingPhotoGalleryUnlocks(policy: policy),
              isBn,
              languageCode,
            ),
            _summaryQuotaRow(
              Icons.radar_rounded,
              isBn ? 'নিকটবর্তী সার্চ' : 'Nearby Searches',
              user.remainingNearbySearchesForPolicy(policy: policy),
              isBn,
              languageCode,
            ),
            _summaryQuotaRow(
              Icons.directions_rounded,
              isBn ? 'গুগল ম্যাপস ডিরেকশন' : 'Map Directions',
              user.remainingMapDirectionsForPolicy(policy: policy),
              isBn,
              languageCode,
            ),
            _summaryQuotaRow(
              Icons.auto_awesome_rounded,
              isBn ? 'এআই সহকারী সার্চ' : 'AI Assistant Queries',
              user.remainingAiQueriesForRole(policy: policy),
              isBn,
              languageCode,
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryQuotaRow(
    IconData icon,
    String label,
    int remaining,
    bool isBn,
    String languageCode,
  ) {
    final isUnlimited = remaining >= 999;
    final isZero = !isUnlimited && remaining <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isZero ? Colors.redAccent : const Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Text(
            isUnlimited
                ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
                : (isZero
                    ? (isBn ? '❌ শেষ (০টি অবশিষ্ট)' : 'Exhausted (0 Left)')
                    : (isBn
                        ? '${remaining.toString().toLocalizedDigits("bn")}টি বাকি'
                        : '$remaining Left')),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isZero ? Colors.redAccent : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planQuotaRow(
    IconData icon,
    String label,
    int used,
    int limit,
    bool isBn,
  ) {
    if (limit == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            ),
            Text(
              isBn ? 'নিষ্ক্রিয় (Disabled)' : 'Disabled',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final bool isUnlimited = limit == -1;
    final int remaining = isUnlimited ? 999 : (limit - used).clamp(0, limit);
    final isExhausted = !isUnlimited && remaining <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isExhausted ? Colors.redAccent : const Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 11.5)),
          ),
          Text(
            isUnlimited
                ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
                : (isExhausted
                    ? (isBn ? '❌ শেষ ($used/$limit)' : 'Exhausted ($used/$limit)')
                    : (isBn
                        ? '${remaining.toString().toLocalizedDigits("bn")}টি বাকি (${used.toString().toLocalizedDigits("bn")}/${limit.toString().toLocalizedDigits("bn")})'
                        : '$remaining Left ($used/$limit)')),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isExhausted ? Colors.redAccent : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

