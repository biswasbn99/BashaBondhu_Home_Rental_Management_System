import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../data/models/subscription_model.dart';
import '../../data/providers/subscription_provider.dart';
import 'subscription_history_screen.dart';
import '../widgets/payment_method_sheet.dart';

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
        title: Text(
          l10n.subscriptionPackages,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Active Plan Status (If Subscribed) ---
            if (user.isSubscribed) _buildActivePlanCard(context, user, isDark, isBn),

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

            const SizedBox(height: 20),

            // --- 5. Free Tier Status Summary Card ---
            _buildFreeTierStatusCard(context, user, isDark),
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

  Widget _buildActivePlanCard(BuildContext context, UserModel user, bool isDark, bool isBn) {
    final expiry = user.expiryDateTime;
    final diffDays = expiry != null ? expiry.difference(DateTime.now()).inDays : 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E332A) : const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade600, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.green, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'আপনার প্রিমিয়াম প্যাকেজ সক্রিয় আছে' : 'Your Premium Plan is Active',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBn
                      ? 'মেয়াদ বাকি: ${diffDays.toString().toLocalizedDigits("bn")} দিন (আনলিমিটেড নম্বর আনলক ও সার্চ সক্রিয়)'
                      : 'Remaining: $diffDays Days (Unlimited contact unlocks & search active)',
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
    );
  }

  Widget _buildFreeTierStatusCard(BuildContext context, UserModel user, bool isDark) {
    final int usedUnlocks = user.unlockedPropertyIds.length;
    final int usedRadius = user.radiusSearchCount;

    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = context.localizations;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.tenantQuotaOverviewTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildQuotaRow(
            l10n.propertyUnlocksQuotaLabel,
            l10n.quotaRemainingWithUsed(
              user.freePropertyUnlocksRemaining.toLocalizedDigits(languageCode),
              5.toLocalizedDigits(languageCode),
              usedUnlocks.toLocalizedDigits(languageCode),
            ),
            user.freePropertyUnlocksRemaining > 0,
          ),
          const SizedBox(height: 6),
          _buildQuotaRow(
            l10n.radiusSearchQuotaLabel,
            l10n.quotaRemainingWithUsed(
              user.freeRadiusSearchesRemaining.toLocalizedDigits(languageCode),
              3.toLocalizedDigits(languageCode),
              usedRadius.toLocalizedDigits(languageCode),
            ),
            user.freeRadiusSearchesRemaining > 0,
          ),
          const SizedBox(height: 6),
          _buildQuotaRow(
            l10n.demandPostQuotaLabel,
            l10n.maxTwoFree,
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaRow(String title, String count, bool hasLeft) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: hasLeft ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: hasLeft ? Colors.green : Colors.redAccent,
            ),
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
    final displayPerks = perks.isNotEmpty ? perks : (isBn ? plan.perksEn : plan.perksBn);

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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172220) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPopular
              ? AppColors.themeColor
              : (isDark ? const Color(0xFF263936) : const Color(0xFFE2EBE9)),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? AppColors.themeColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                        padding: EdgeInsets.only(right: (hasOffer || isPopular) ? 75 : 0),
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
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.themeColor,
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
                const SizedBox(height: 14),

                // Perks Header
                Text(
                  isBn ? 'প্যাকেজ অ্যাক্টিভ করলে যা যা পাবেনঃ' : 'Included Plan Perks:',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.themeColor),
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
                          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.themeColor),
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

                // Choose Plan Button
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

          // Offer / Popular Tag Top Right
          if (hasOffer && offerBadge.isNotEmpty)
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
}
