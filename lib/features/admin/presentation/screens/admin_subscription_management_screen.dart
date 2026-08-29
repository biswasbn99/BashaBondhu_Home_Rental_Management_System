import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../data/providers/admin_provider.dart';
import '../../../subscription/data/models/subscription_model.dart';
import '../../../subscription/data/providers/subscription_provider.dart';

class AdminSubscriptionManagementView extends StatefulWidget {
  const AdminSubscriptionManagementView({super.key});

  @override
  State<AdminSubscriptionManagementView> createState() => _AdminSubscriptionManagementViewState();
}

class _AdminSubscriptionManagementViewState extends State<AdminSubscriptionManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProv = context.watch<AdminProvider>();
    final isBn = adminProv.isBangla;
    final subProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Actions
            _buildTopHeader(context, isDark, isBn),
            const SizedBox(height: 20),

            // Top Metrics Overview Bar
            _buildMetricsOverview(context, subProvider, isDark, isBn),
            const SizedBox(height: 24),

            // Modern Tab Bar
            _buildModernTabBar(isDark, isBn),
            const SizedBox(height: 20),

            // Tab Content Container
            SizedBox(
              height: 750,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Tenant Plans
                  _buildPlansTab(
                    context,
                    subProvider.streamTenantPlans(),
                    isBn,
                    isDark,
                    SubscriptionTargetRole.tenant,
                  ),

                  // Tab 2: House Owner Plans
                  _buildPlansTab(
                    context,
                    subProvider.streamHouseOwnerPlans(),
                    isBn,
                    isDark,
                    SubscriptionTargetRole.houseOwner,
                  ),

                  // Tab 3: Transactions
                  _buildTransactionsTab(
                    context,
                    subProvider.streamAllTransactions(),
                    isBn,
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDark, bool isBn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'সাবস্ক্রিপশন ও প্যাকেজ স্টুডিও' : 'Subscription & Package Studio',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                ),
                const SizedBox(height: 3),
                Text(
                  isBn
                      ? 'ভাড়াটিয়া ও বাড়িওয়ালাদের প্যাকেজ, দ্বিভাষিক বিবরণ (BN & EN), বিশেষ অফার ও প্রাইসিং কন্ট্রোল'
                      : 'Manage tenant & house owner packages, bilingual details (BN & EN), deals & prices',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => _showGatewaySettingsDialog(context, isDark, isBn),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          icon: const Icon(Icons.settings_suggest_rounded, size: 20),
          label: Text(
            isBn ? 'SSLCOMMERZ গেটওয়ে' : 'SSLCOMMERZ Gateway',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsOverview(BuildContext context, SubscriptionProvider subProvider, bool isDark, bool isBn) {
    return StreamBuilder<List<SubscriptionPlanModel>>(
      stream: subProvider.streamAllPlans(),
      builder: (context, planSnapshot) {
        final plans = planSnapshot.data ?? [];
        final tenantCount = plans.where((p) => p.targetRole == SubscriptionTargetRole.tenant).length;
        final ownerCount = plans.where((p) => p.targetRole == SubscriptionTargetRole.houseOwner).length;
        final offerCount = plans.where((p) => p.hasActiveOffer).length;

        return StreamBuilder<List<SubscriptionTransactionModel>>(
          stream: subProvider.streamAllTransactions(),
          builder: (context, txSnapshot) {
            final txs = txSnapshot.data ?? [];
            final totalRevenue = txs.fold<double>(0.0, (acc, item) => acc + item.amountPaid);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _metricCard(
                      title: isBn ? 'ভাড়াটিয়া প্যাকেজ' : 'Tenant Plans',
                      value: isBn ? '${tenantCount.toString().toLocalizedDigits("bn")} টি' : '$tenantCount Plans',
                      subtitle: isBn ? 'সক্রিয় প্যাকেজ' : 'Active packages',
                      icon: Icons.person_pin_rounded,
                      color: const Color(0xFF0D9488),
                      isDark: isDark,
                      width: isWide ? (constraints.maxWidth - 42) / 4 : (constraints.maxWidth - 14) / 2,
                    ),
                    _metricCard(
                      title: isBn ? 'বাড়িওয়ালা প্যাকেজ' : 'Owner Plans',
                      value: isBn ? '${ownerCount.toString().toLocalizedDigits("bn")} টি' : '$ownerCount Plans',
                      subtitle: isBn ? 'সক্রিয় প্যাকেজ' : 'Active packages',
                      icon: Icons.home_work_rounded,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      width: isWide ? (constraints.maxWidth - 42) / 4 : (constraints.maxWidth - 14) / 2,
                    ),
                    _metricCard(
                      title: isBn ? 'চলমান বিশেষ ছাড়' : 'Special Offers',
                      value: isBn ? '${offerCount.toString().toLocalizedDigits("bn")} টি' : '$offerCount Deals',
                      subtitle: isBn ? 'ডিসকাউন্ট অফার' : 'Discount deals live',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFEF4444),
                      isDark: isDark,
                      width: isWide ? (constraints.maxWidth - 42) / 4 : (constraints.maxWidth - 14) / 2,
                    ),
                    _metricCard(
                      title: isBn ? 'মোট রেভিনিউ' : 'Total Revenue',
                      value: isBn ? '৳${totalRevenue.toInt().toString().toLocalizedDigits("bn")}' : '৳${totalRevenue.toInt()}',
                      subtitle: isBn ? '${txs.length.toString().toLocalizedDigits("bn")} টি লেনদেন' : '${txs.length} Transactions',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                      width: isWide ? (constraints.maxWidth - 42) / 4 : (constraints.maxWidth - 14) / 2,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16211F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar(bool isDark, bool isBn) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D1C) : const Color(0xFFE8F2F0),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.themeColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.themeColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[700],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        tabs: [
          Tab(
            icon: const Icon(Icons.person_pin_rounded, size: 18),
            text: isBn ? 'ভাড়াটিয়া প্যাকেজ (Tenant)' : 'Tenant Packages',
          ),
          Tab(
            icon: const Icon(Icons.home_work_rounded, size: 18),
            text: isBn ? 'বাড়িওয়ালা প্যাকেজ (Owner)' : 'House Owner Packages',
          ),
          Tab(
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            text: isBn ? 'গ্রাহক ও লেনদেন (Transactions)' : 'Subscribers & Transactions',
          ),
        ],
      ),
    );
  }

  Widget _buildPlansTab(
    BuildContext context,
    Stream<List<SubscriptionPlanModel>> stream,
    bool isBn,
    bool isDark,
    SubscriptionTargetRole targetRole,
  ) {
    final isTenant = targetRole == SubscriptionTargetRole.tenant;
    final themeColor = isTenant ? const Color(0xFF0D9488) : const Color(0xFFF59E0B);

    return Column(
      children: [
        // Action Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16211F) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF263936) : const Color(0xFFE2EBE9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isTenant
                        ? (isBn ? 'ভাড়াটিয়াদের প্যাকেজ তালিকা' : 'Tenant Packages Catalog')
                        : (isBn ? 'বাড়িওয়ালাদের প্যাকেজ তালিকা' : 'House Owner Packages Catalog'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _showPlanStudioDialog(context, targetRole: targetRole, existingPlan: null, isDark: isDark, isBn: isBn),
                style: FilledButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: isTenant ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  isBn ? '+ নতুন প্যাকেজ তৈরি করুন' : '+ Create New Package',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Plans Grid
        Expanded(
          child: StreamBuilder<List<SubscriptionPlanModel>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.themeColor));
              }

              final plans = snapshot.data ?? [];
              if (plans.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        isBn ? 'কোনো প্যাকেজ পাওয়া যায়নি' : 'No subscription plans found',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _showPlanStudioDialog(context, targetRole: targetRole, existingPlan: null, isDark: isDark, isBn: isBn),
                        style: FilledButton.styleFrom(backgroundColor: themeColor),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(isBn ? 'প্রথম প্যাকেজ তৈরি করুন' : 'Create First Plan'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: plans.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return _buildAdminPlanCard(context, plan, isBn, isDark, themeColor);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminPlanCard(
    BuildContext context,
    SubscriptionPlanModel plan,
    bool isBn,
    bool isDark,
    Color roleAccentColor,
  ) {
    final hasOffer = plan.hasActiveOffer;
    final isPopular = plan.isPopular;

    // Savings Calculation
    final discountPercent = hasOffer && plan.offerPrice != null && plan.regularPrice > 0
        ? (((plan.regularPrice - plan.offerPrice!) / plan.regularPrice) * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16211F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasOffer
              ? Colors.redAccent.withValues(alpha: 0.6)
              : (isPopular ? roleAccentColor : (isDark ? const Color(0xFF263936) : const Color(0xFFE2EBE9))),
          width: (hasOffer || isPopular) ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasOffer ? Colors.redAccent : roleAccentColor).withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: roleAccentColor.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: roleAccentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.workspace_premium_rounded, color: roleAccentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.titleBn.isNotEmpty ? plan.titleBn : plan.titleEn,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            if (plan.titleEn.isNotEmpty && plan.titleBn != plan.titleEn) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${plan.titleEn})',
                                style: TextStyle(fontSize: 13, color: Colors.grey[500], fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                        if (plan.descriptionBn.isNotEmpty || plan.descriptionEn.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            isBn ? (plan.descriptionBn.isNotEmpty ? plan.descriptionBn : plan.descriptionEn) : (plan.descriptionEn.isNotEmpty ? plan.descriptionEn : plan.descriptionBn),
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Action Toolbar
                Row(
                  children: [
                    if (isPopular) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star_rounded, size: 13, color: Colors.black),
                            SizedBox(width: 4),
                            Text(
                              'POPULAR',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: Text(isBn ? 'সম্পাদনা' : 'Edit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _showPlanStudioDialog(context, targetRole: plan.targetRole, existingPlan: plan, isDark: isDark, isBn: isBn),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      tooltip: isBn ? 'প্যাকেজ ডিলিট' : 'Delete Plan',
                      onPressed: () => _confirmDeletePlan(context, plan, isBn),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pricing Breakdown Strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          isBn ? '৳${plan.effectivePrice.toInt().toString().toLocalizedDigits("bn")}' : '৳${plan.effectivePrice.toInt()}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: hasOffer ? Colors.redAccent : roleAccentColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBn
                              ? '/ ${plan.durationBn.isNotEmpty ? plan.durationBn : "${plan.durationDays.toString().toLocalizedDigits('bn')} দিন"}'
                              : '/ ${plan.durationEn.isNotEmpty ? plan.durationEn : "${plan.durationDays} Days"}',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        if (hasOffer) ...[
                          const SizedBox(width: 10),
                          Text(
                            isBn ? '৳${plan.regularPrice.toInt().toString().toLocalizedDigits("bn")}' : '৳${plan.regularPrice.toInt()}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isBn ? '🔥 ${discountPercent.toString().toLocalizedDigits("bn")}% ছাড়' : '🔥 $discountPercent% OFF',
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (hasOffer && (plan.offerBadgeTextBn.isNotEmpty || plan.offerBadgeTextEn.isNotEmpty))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isBn ? plan.offerBadgeTextBn : (plan.offerBadgeTextEn.isNotEmpty ? plan.offerBadgeTextEn : plan.offerBadgeTextBn),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Bilingual Perks Bullet List
                Text(
                  isBn ? 'প্যাকেজের সুবিধাসমূহ (Perks):' : 'Included Perks (Bilingual BN & EN):',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: List.generate(plan.perksBn.length, (i) {
                    final bnPerk = plan.perksBn[i];
                    final enPerk = i < plan.perksEn.length ? plan.perksEn[i] : '';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: roleAccentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: roleAccentColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: roleAccentColor),
                          const SizedBox(width: 6),
                          Text(
                            isBn ? bnPerk : (enPerk.isNotEmpty ? enPerk : bnPerk),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          if (enPerk.isNotEmpty && enPerk != bnPerk && isBn) ...[
                            const SizedBox(width: 4),
                            Text(
                              '($enPerk)',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(
    BuildContext context,
    Stream<List<SubscriptionTransactionModel>> stream,
    bool isBn,
    bool isDark,
  ) {
    return StreamBuilder<List<SubscriptionTransactionModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.themeColor));
        }

        final txs = snapshot.data ?? [];
        if (txs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  isBn ? 'এখনও কোনো সাবস্ক্রিপশন লেনদেন হয়নি' : 'No subscription transactions yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: txs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final tx = txs[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16211F) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF263936) : const Color(0xFFE2EBE9)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2136E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFE2136E), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tx.planTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '৳${tx.amountPaid.toInt()}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.themeColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isBn ? "গ্রাহক:" : "User:"} ${tx.userEmail} • ${tx.senderPhone}',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'TrxID: ${tx.transactionId} • ${tx.status.toUpperCase()}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE2136E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeletePlan(BuildContext context, SubscriptionPlanModel plan, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isBn ? 'প্যাকেজ ডিলিট করতে চান?' : 'Delete Subscription Plan?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          isBn
              ? 'আপনি কি নিশ্চিত যে "${plan.titleBn}" (৳${plan.regularPrice.toInt()}) প্যাকেজটি ডিলিট করতে চান?'
              : 'Are you sure you want to delete "${plan.titleEn}" (৳${plan.regularPrice.toInt()}) package?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final subProvider = context.read<SubscriptionProvider>();
              await subProvider.deletePlan(plan.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn ? 'প্যাকেজটি সফলভাবে ডিলিট করা হয়েছে।' : 'Plan deleted successfully.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(isBn ? 'হ্যাঁ, ডিলিট করুন' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showPlanStudioDialog(
    BuildContext context, {
    required SubscriptionTargetRole targetRole,
    SubscriptionPlanModel? existingPlan,
    required bool isDark,
    required bool isBn,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BilingualPlanStudioModal(
        targetRole: targetRole,
        existingPlan: existingPlan,
        isDark: isDark,
        isBn: isBn,
      ),
    );
  }

  void _showGatewaySettingsDialog(BuildContext context, bool isDark, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payment_rounded, color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBn ? 'SSLCOMMERZ গেটওয়ে কনফিগারেশন' : 'SSLCOMMERZ Gateway Settings',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science_rounded, color: Colors.amber.shade700, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? 'বর্তমান মোড: Sandbox (টেস্টিং মোড)' : 'Current Mode: Sandbox (Test Mode)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            isBn
                                ? 'Store ID: testbox • Password: qwerty (ফ্রি টেস্টের জন্য সক্রিয়)'
                                : 'Store ID: testbox • Password: qwerty (Active for free testing)',
                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isBn ? 'সাপোর্টেড পেমেন্ট চ্যানেলসমূহঃ' : 'Supported Payment Channels:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _channelBadge('bKash'),
                  _channelBadge('Nagad'),
                  _channelBadge('Rocket'),
                  _channelBadge('Upay'),
                  _channelBadge('Visa / Mastercard'),
                  _channelBadge('DBBL Nexus'),
                  _channelBadge('Internet Banking'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2136E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2136E).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFE2136E), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isBn
                            ? 'ডাইরেক্ট বিকাশ মার্চেন্ট নম্বর: 01746300498'
                            : 'Direct bKash Receiver Number: 01746300498',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'ঠিক আছে' : 'OK'),
          ),
        ],
      ),
    );
  }

  Widget _channelBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.themeColor),
      ),
    );
  }
}

/// =========================================================================
/// 🎨 MODERN BILINGUAL PACKAGE STUDIO MODAL (ADD / EDIT)
/// =========================================================================
class _BilingualPlanStudioModal extends StatefulWidget {
  final SubscriptionTargetRole targetRole;
  final SubscriptionPlanModel? existingPlan;
  final bool isDark;
  final bool isBn;

  const _BilingualPlanStudioModal({
    required this.targetRole,
    this.existingPlan,
    required this.isDark,
    required this.isBn,
  });

  @override
  State<_BilingualPlanStudioModal> createState() => _BilingualPlanStudioModalState();
}

class _BilingualPlanStudioModalState extends State<_BilingualPlanStudioModal> {
  late final TextEditingController _titleBnController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _descBnController;
  late final TextEditingController _descEnController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationDaysController;
  late final TextEditingController _durationBnController;
  late final TextEditingController _durationEnController;
  late final TextEditingController _offerPriceController;
  late final TextEditingController _badgeBnController;
  late final TextEditingController _badgeEnController;

  late bool _isPopular;
  late bool _hasOffer;
  bool _previewInEnglish = false;
  final List<_PerkPairControllers> _perkPairs = [];
  late final List<_DurationPresetItem> _durationPresets;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPlan;

    _durationPresets = [
      const _DurationPresetItem(days: 7, value: 7, unit: 'day', label: '৭ দিন / 7d', bn: '৭ দিন', en: '7 Days'),
      const _DurationPresetItem(days: 15, value: 15, unit: 'day', label: '১৫ দিন / 15d', bn: '১৫ দিন', en: '15 Days'),
      const _DurationPresetItem(days: 30, value: 1, unit: 'month', label: '১ মাস / 30d', bn: '১ মাস', en: '1 Month'),
      const _DurationPresetItem(days: 60, value: 2, unit: 'month', label: '২ মাস / 60d', bn: '২ মাস', en: '2 Months'),
      const _DurationPresetItem(days: 90, value: 3, unit: 'month', label: '৩ মাস / 90d', bn: '৩ মাস', en: '3 Months'),
      const _DurationPresetItem(days: 180, value: 6, unit: 'month', label: '৬ মাস / 180d', bn: '৬ মাস', en: '6 Months'),
      const _DurationPresetItem(days: 365, value: 1, unit: 'year', label: '১ বছর / 1y', bn: '১ বছর', en: '1 Year'),
    ];

    if (p != null && !_durationPresets.any((item) => item.days == p.durationDays)) {
      _durationPresets.add(_DurationPresetItem(
        days: p.durationDays,
        value: p.durationValue > 0 ? p.durationValue : p.durationDays,
        unit: p.durationUnit,
        label: '${p.durationBn.isNotEmpty ? p.durationBn : "${p.durationDays} দিন"} / ${p.durationDays}d',
        bn: p.durationBn.isNotEmpty ? p.durationBn : '${p.durationDays} দিন',
        en: p.durationEn.isNotEmpty ? p.durationEn : '${p.durationDays} Days',
      ));
    }

    _titleBnController = TextEditingController(text: p?.titleBn ?? '');
    _titleEnController = TextEditingController(text: p?.titleEn ?? '');
    _descBnController = TextEditingController(text: p?.descriptionBn ?? '');
    _descEnController = TextEditingController(text: p?.descriptionEn ?? '');
    _priceController = TextEditingController(text: p != null ? p.regularPrice.toInt().toString() : '200');
    _durationDaysController = TextEditingController(text: p != null ? p.durationDays.toString() : '15');
    _durationBnController = TextEditingController(text: p?.durationBn.isNotEmpty == true ? p!.durationBn : (p != null ? '${p.durationDays} দিন' : '১৫ দিন'));
    _durationEnController = TextEditingController(text: p?.durationEn.isNotEmpty == true ? p!.durationEn : (p != null ? '${p.durationDays} Days' : '15 Days'));
    _offerPriceController = TextEditingController(text: p?.offerPrice != null ? p!.offerPrice!.toInt().toString() : '');
    _badgeBnController = TextEditingController(text: p?.offerBadgeTextBn ?? '');
    _badgeEnController = TextEditingController(text: p?.offerBadgeTextEn ?? '');

    _isPopular = p?.isPopular ?? false;
    _hasOffer = p?.hasActiveOffer ?? false;

    if (p != null) {
      final maxLen = p.perksBn.length > p.perksEn.length ? p.perksBn.length : p.perksEn.length;
      for (int i = 0; i < maxLen; i++) {
        final bn = i < p.perksBn.length ? p.perksBn[i] : '';
        final en = i < p.perksEn.length ? p.perksEn[i] : '';
        _perkPairs.add(_PerkPairControllers(
          bnController: TextEditingController(text: bn),
          enController: TextEditingController(text: en),
        ));
      }
    } else {
      // Initial defaults
      if (widget.targetRole == SubscriptionTargetRole.tenant) {
        _perkPairs.add(_PerkPairControllers(
          bnController: TextEditingController(text: 'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন'),
          enController: TextEditingController(text: 'Unlock unlimited contact numbers including this post'),
        ));
        _perkPairs.add(_PerkPairControllers(
          bnController: TextEditingController(text: '১০টি ভিন্ন চাহিদা জানাতে পারবেন'),
          enController: TextEditingController(text: 'Post up to 10 customized rental demands'),
        ));
        _perkPairs.add(_PerkPairControllers(
          bnController: TextEditingController(text: 'বিজ্ঞাপন দেখতে হবে না'),
          enController: TextEditingController(text: 'Ad-free experience'),
        ));
      } else {
        _perkPairs.add(_PerkPairControllers(
          bnController: TextEditingController(text: 'আনলিমিটেড ভাড়াটিয়াদের নম্বর আনলক করতে পারবেন'),
          enController: TextEditingController(text: 'Unlock unlimited tenant contact numbers'),
        ));
        _perkPairs.add(_PerkPairControllers(
          bnController: TextEditingController(text: '১০টি বাসাভাড়া বিজ্ঞাপন পোস্ট করতে পারবেন'),
          enController: TextEditingController(text: 'Post up to 10 rental listings'),
        ));
        _perkPairs.add(_PerkPairControllers(
          bnController: TextEditingController(text: 'বিজ্ঞাপন দেখতে হবে না'),
          enController: TextEditingController(text: 'Ad-free experience'),
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleBnController.dispose();
    _titleEnController.dispose();
    _descBnController.dispose();
    _descEnController.dispose();
    _priceController.dispose();
    _durationDaysController.dispose();
    _durationBnController.dispose();
    _durationEnController.dispose();
    _offerPriceController.dispose();
    _badgeBnController.dispose();
    _badgeEnController.dispose();
    for (final pair in _perkPairs) {
      pair.bnController.dispose();
      pair.enController.dispose();
    }
    super.dispose();
  }

  void _applyDurationPreset(int days, String labelBn, String labelEn) {
    setState(() {
      _durationDaysController.text = days.toString();
      _durationBnController.text = labelBn;
      _durationEnController.text = labelEn;
    });
  }

  void _addSuggestedPerk(String bn, String en) {
    setState(() {
      _perkPairs.add(_PerkPairControllers(
        bnController: TextEditingController(text: bn),
        enController: TextEditingController(text: en),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTenant = widget.targetRole == SubscriptionTargetRole.tenant;
    final roleAccentColor = isTenant ? const Color(0xFF0D9488) : const Color(0xFFF59E0B);
    final isEdit = widget.existingPlan != null;

    return Dialog(
      backgroundColor: widget.isDark ? const Color(0xFF16211F) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 880),
        child: Column(
          children: [
            // Modal Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isTenant
                      ? [const Color(0xFF0D9488), const Color(0xFF14B8A6)]
                      : [const Color(0xFFD97706), const Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isTenant ? Icons.person_pin_rounded : Icons.home_work_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? (widget.isBn ? 'প্যাকেজ সম্পাদনা ও কাস্টমাইজ' : 'Edit Subscription Plan')
                                : (widget.isBn ? 'নতুন সাবস্ক্রিপশন প্যাকেজ স্টুডিও' : 'Create New Subscription Plan'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                          Text(
                            isTenant
                                ? (widget.isBn ? 'ভাড়াটিয়াদের (Tenant) জন্য দ্বিভাষিক প্যাকেজ' : 'For Tenant Users (Bilingual BN & EN)')
                                : (widget.isBn ? 'বাড়িওয়ালাদের (House Owner) জন্য দ্বিভাষিক প্যাকেজ' : 'For House Owner Users (Bilingual BN & EN)'),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Modal Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Basic Bilingual Details
                    _sectionTitle('১. প্যাকেজের নাম ও বিবরণ (Bilingual Name & Description)', roleAccentColor),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _titleBnController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'প্যাকেজের নাম (বাংলা)*',
                              hintText: 'যেমন: ১৫ দিনের প্রিমিয়াম প্যাকেজ',
                              prefixIcon: Icon(Icons.language_rounded, size: 18),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _titleEnController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Package Name (English)*',
                              hintText: 'e.g. 15-Day Premium Plan',
                              prefixIcon: Icon(Icons.translate_rounded, size: 18),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _descBnController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'প্যাকেজ বিবরণ (বাংলা)',
                              hintText: 'যেমন: বাসা খোঁজার সেরা ১৫ দিনের প্যাকেজ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _descEnController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Package Description (English)',
                              hintText: 'e.g. Best plan for active house hunting',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Section 2: Pricing & Duration
                    _sectionTitle('২. মূল্য ও মেয়াদ (Pricing & Quick Duration)', roleAccentColor),
                    const SizedBox(height: 10),

                    // Quick Duration Chips with responsive Wrap and Add Button
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          widget.isBn ? 'কুইক মেয়াদ:' : 'Quick Duration:',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        ..._durationPresets.map((preset) => _durationChip(
                              preset.days,
                              preset.label,
                              preset.bn,
                              preset.en,
                            )),
                        // Add Duration Action Button
                        ActionChip(
                          avatar: Icon(Icons.add_circle_outline_rounded, size: 16, color: roleAccentColor),
                          label: Text(
                            widget.isBn ? '+ মেয়াদ যোগ করুন' : '+ Add Duration',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: roleAccentColor,
                            ),
                          ),
                          backgroundColor: roleAccentColor.withValues(alpha: 0.12),
                          side: BorderSide(color: roleAccentColor.withValues(alpha: 0.5), width: 1.2),
                          onPressed: () => _showAddCustomDurationDialog(roleAccentColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 1: Price and Duration Days
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.text,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'মূল্য (যেমন: 200 বা ২০০)*',
                              hintText: '200 বা ২০০',
                              prefixText: '৳ ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _durationDaysController,
                            keyboardType: TextInputType.text,
                            onChanged: (val) {
                              final d = int.tryParse(val.trim().toEnglishDigits()) ?? 0;
                              _durationBnController.text = '$d দিন';
                              _durationEnController.text = '$d Days';
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              labelText: widget.isBn ? 'মেয়াদ সংখ্যা (দিন হিসেবে - যেমন: 15 বা ১৫)*' : 'Duration Days (e.g. 15 or ১৫)*',
                              hintText: '15 বা ১৫',
                              suffixText: widget.isBn ? ' দিন' : ' Days',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Custom Bilingual Duration Names
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _durationBnController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'মেয়াদের নাম/লেবেল (বাংলা)*',
                              hintText: 'যেমন: ১৫ দিন, ১ মাস, ৩ মাস বা আজীবন',
                              prefixIcon: Icon(Icons.timer_outlined, size: 18),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _durationEnController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Duration Label (English)*',
                              hintText: 'e.g. 15 Days, 1 Month or Lifetime',
                              prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Live Dual-Language Pricing Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: roleAccentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: roleAccentColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.currency_exchange_rounded, color: roleAccentColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🇧🇩 বাংলায়: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    Text(
                                      '৳${(double.tryParse(_priceController.text.trim().toEnglishDigits()) ?? 0).toInt().toString().toLocalizedDigits("bn")} টাকা / ${_durationBnController.text.trim().isNotEmpty ? _durationBnController.text.trim() : "${(int.tryParse(_durationDaysController.text.trim().toEnglishDigits()) ?? 0).toString().toLocalizedDigits('bn')} দিন"}',
                                      style: TextStyle(fontWeight: FontWeight.w900, color: roleAccentColor, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🇺🇸 In English: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    Text(
                                      '৳${(double.tryParse(_priceController.text.trim().toEnglishDigits()) ?? 0).toInt()} BDT / ${_durationEnController.text.trim().isNotEmpty ? _durationEnController.text.trim() : "${int.tryParse(_durationDaysController.text.trim().toEnglishDigits()) ?? 0} Days"}',
                                      style: TextStyle(fontWeight: FontWeight.w900, color: roleAccentColor, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Popular & Offers
                    _sectionTitle('৩. অফার ও জনপ্রিয় ব্যাজ (Deals & Badges)', roleAccentColor),
                    const SizedBox(height: 6),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 580) {
                          return Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('জনপ্রিয় / সেরা ডিল (Popular Badge)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: const Text('প্যাকেজ কার্ডে হাইলাইট ও গোল্ডেন স্টার ব্যাজ দেখাবে', style: TextStyle(fontSize: 11)),
                                  value: _isPopular,
                                  activeThumbColor: roleAccentColor,
                                  onChanged: (v) => setState(() => _isPopular = v),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('বিশেষ ছাড় / অফার (Discount Deal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: const Text('কাটা দাগ দিয়ে অফার মূল্য সক্রিয় হবে', style: TextStyle(fontSize: 11)),
                                  value: _hasOffer,
                                  activeThumbColor: Colors.redAccent,
                                  onChanged: (v) => setState(() => _hasOffer = v),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('জনপ্রিয় / সেরা ডিল (Popular Badge)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: const Text('প্যাকেজ কার্ডে হাইলাইট ও গোল্ডেন স্টার ব্যাজ দেখাবে', style: TextStyle(fontSize: 11)),
                                value: _isPopular,
                                activeThumbColor: roleAccentColor,
                                onChanged: (v) => setState(() => _isPopular = v),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('বিশেষ ছাড় / অফার (Discount Deal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: const Text('কাটা দাগ দিয়ে অফার মূল্য সক্রিয় হবে', style: TextStyle(fontSize: 11)),
                                value: _hasOffer,
                                activeThumbColor: Colors.redAccent,
                                onChanged: (v) => setState(() => _hasOffer = v),
                              ),
                            ],
                          );
                        }
                      },
                    ),

                    if (_hasOffer) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 520) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: TextField(
                                          controller: _offerPriceController,
                                          keyboardType: TextInputType.text,
                                          onChanged: (_) => setState(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'অফার মূল্য (যেমন: 150 বা ১৫০)*',
                                            hintText: '150 বা ১৫০',
                                            prefixText: '৳ ',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 5,
                                        child: TextField(
                                          controller: _badgeBnController,
                                          onChanged: (_) => setState(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'অফার ব্যাজ (বাংলা)',
                                            hintText: 'যেমন: ২৫% ছাড়',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 5,
                                        child: TextField(
                                          controller: _badgeEnController,
                                          onChanged: (_) => setState(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'Offer Badge (English)',
                                            hintText: 'e.g. 25% OFF',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      TextField(
                                        controller: _offerPriceController,
                                        keyboardType: TextInputType.text,
                                        onChanged: (_) => setState(() {}),
                                        decoration: const InputDecoration(
                                          labelText: 'অফার মূল্য (যেমন: 150 বা ১৫০)*',
                                          hintText: '150 বা ১৫০',
                                          prefixText: '৳ ',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _badgeBnController,
                                              onChanged: (_) => setState(() {}),
                                              decoration: const InputDecoration(
                                                labelText: 'অফার ব্যাজ (বাংলা)',
                                                hintText: 'যেমন: ২৫% ছাড়',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextField(
                                              controller: _badgeEnController,
                                              onChanged: (_) => setState(() {}),
                                              decoration: const InputDecoration(
                                                labelText: 'Offer Badge (English)',
                                                hintText: 'e.g. 25% OFF',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            // Live Bilingual Offer Preview
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 16,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          '🇧🇩 অফার মূল্য: ৳${(double.tryParse(_offerPriceController.text.trim().toEnglishDigits()) ?? 0).toInt().toString().toLocalizedDigits("bn")} টাকা',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12),
                                        ),
                                        Text(
                                          '🇺🇸 Offer Price: ৳${(double.tryParse(_offerPriceController.text.trim().toEnglishDigits()) ?? 0).toInt()} BDT',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Section 4: Bilingual Perks Manager
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('৪. সুবিধাসমূহ (Bilingual Perks & Features)', roleAccentColor),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _perkPairs.add(_PerkPairControllers(
                                bnController: TextEditingController(),
                                enController: TextEditingController(),
                              ));
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: Text(widget.isBn ? '+ নতুন সুবিধা যোগ' : '+ Add Perk Pair'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Quick Perk Suggestions Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _quickPerkChip('+ আনলিমিটেড নম্বর আনলক', '+ Unlock unlimited contact numbers'),
                        _quickPerkChip('+ ১০টি চাহিদা প্রকাশ', '+ Post 10 customized demands'),
                        _quickPerkChip('+ ১০টি বাসা বিজ্ঞাপন পোস্ট', '+ Post 10 property listings'),
                        _quickPerkChip('+ বিজ্ঞাপন মুক্ত অভিজ্ঞতা', '+ 100% Ad-free experience'),
                        _quickPerkChip('+ অতিরিক্ত সকল ছবির এক্সেস', '+ Full photo gallery access'),
                        _quickPerkChip('+ গুগল ম্যাপস ডিরেকশন', '+ Full Google Maps navigation access'),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ..._perkPairs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pair = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF182422) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Perk Item Card Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: roleAccentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.stars_rounded, size: 14, color: roleAccentColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        'সুবিধা / Perk #${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: roleAccentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                                    padding: const EdgeInsets.all(6),
                                    minimumSize: const Size(32, 32),
                                  ),
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  tooltip: 'এই সুবিধাটি মুছে ফেলুন (Delete)',
                                  onPressed: () {
                                    setState(() {
                                      _perkPairs.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Dual Input Fields (Responsive Side-by-Side or Stacked)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 560) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: pair.bnController,
                                          onChanged: (_) => setState(() {}),
                                          decoration: InputDecoration(
                                            labelText: 'সুবিধা #${index + 1} (বাংলা ভাষায়)',
                                            hintText: 'যেমন: আনলিমিটেড নাম্বার আনলক',
                                            prefixIcon: Icon(Icons.check_circle_outline_rounded, color: roleAccentColor, size: 18),
                                            filled: true,
                                            fillColor: widget.isDark ? const Color(0xFF121C1A) : Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3F3C) : const Color(0xFFCBD5E1)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3F3C) : const Color(0xFFCBD5E1)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: TextField(
                                          controller: pair.enController,
                                          onChanged: (_) => setState(() {}),
                                          decoration: InputDecoration(
                                            labelText: 'Perk #${index + 1} (in English)',
                                            hintText: 'e.g. Unlock unlimited contact numbers',
                                            prefixIcon: const Icon(Icons.translate_rounded, color: Color(0xFF6366F1), size: 18),
                                            filled: true,
                                            fillColor: widget.isDark ? const Color(0xFF121C1A) : Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3F3C) : const Color(0xFFCBD5E1)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3F3C) : const Color(0xFFCBD5E1)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      TextField(
                                        controller: pair.bnController,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          labelText: 'সুবিধা #${index + 1} (বাংলা ভাষায়)',
                                          hintText: 'যেমন: আনলিমিটেড নাম্বার আনলক',
                                          prefixIcon: Icon(Icons.check_circle_outline_rounded, color: roleAccentColor, size: 18),
                                          filled: true,
                                          fillColor: widget.isDark ? const Color(0xFF121C1A) : Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3F3C) : const Color(0xFFCBD5E1)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3F3C) : const Color(0xFFCBD5E1)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: pair.enController,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          labelText: 'Perk #${index + 1} (in English)',
                                          hintText: 'e.g. Unlock unlimited contact numbers',
                                          prefixIcon: const Icon(Icons.translate_rounded, color: Color(0xFF6366F1), size: 18),
                                          filled: true,
                                          fillColor: widget.isDark ? const Color(0xFF121C1A) : Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3F3C) : const Color(0xFFCBD5E1)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3F3C) : const Color(0xFFCBD5E1)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Section 5: Live Interactive Mobile Preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('৫. লাইভ মোবাইল প্রিভিউ (Live Mobile Card Preview)', roleAccentColor),
                        Row(
                          children: [
                            Text(
                              _previewInEnglish ? '🇺🇸 English View' : '🇧🇩 বাংলা ভিউ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            Switch.adaptive(
                              value: _previewInEnglish,
                              activeTrackColor: roleAccentColor,
                              onChanged: (val) => setState(() => _previewInEnglish = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Live Rendered Card
                    _buildLivePreviewCard(roleAccentColor),
                  ],
                ),
              ),
            ),

            // Modal Bottom Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF131D1C) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: widget.isDark ? const Color(0xFF243432) : const Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isBn
                        ? 'সংরক্ষণ করলে সকল ইউজারদের ফোনে রিয়েলটাইমে আপডেট হবে'
                        : 'Saving will instantly reflect on all user devices in real-time',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(widget.isBn ? 'বাতিল' : 'Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: roleAccentColor,
                          foregroundColor: isTenant ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          isEdit
                              ? (widget.isBn ? 'প্যাকেজ আপডেট করুন' : 'Update Package')
                              : (widget.isBn ? 'প্যাকেজ তৈরি ও প্রকাশ করুন' : 'Create & Publish Plan'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        onPressed: _savePlan,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationChip(int days, String label, String bn, String en) {
    final isSelected = _durationDaysController.text == days.toString();
    return InputChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? (widget.targetRole == SubscriptionTargetRole.tenant ? const Color(0xFF0D9488) : const Color(0xFFF59E0B))
              : null,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: (widget.targetRole == SubscriptionTargetRole.tenant ? const Color(0xFF0D9488) : const Color(0xFFF59E0B)).withValues(alpha: 0.18),
      backgroundColor: widget.isDark ? const Color(0xFF1B2B28) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected
            ? (widget.targetRole == SubscriptionTargetRole.tenant ? const Color(0xFF0D9488) : const Color(0xFFF59E0B))
            : Colors.grey.withValues(alpha: 0.3),
        width: isSelected ? 1.4 : 1.0,
      ),
      onPressed: () => _applyDurationPreset(days, bn, en),
      deleteIcon: const Icon(Icons.close_rounded, size: 14),
      deleteIconColor: isSelected ? Colors.redAccent : Colors.grey[500],
      deleteButtonTooltipMessage: widget.isBn ? 'মেয়াদ মুছুন' : 'Delete duration',
      onDeleted: _durationPresets.length > 1
          ? () {
              setState(() {
                _durationPresets.removeWhere((p) => p.days == days);
                if (_durationDaysController.text == days.toString() && _durationPresets.isNotEmpty) {
                  final first = _durationPresets.first;
                  _durationDaysController.text = first.days.toString();
                  _durationBnController.text = first.bn;
                  _durationEnController.text = first.en;
                }
              });
            }
          : null,
    );
  }

  void _showAddCustomDurationDialog(Color roleAccentColor) {
    String selectedUnit = 'day'; // 'day', 'month', 'year'
    final valueCtrl = TextEditingController(text: '15');
    final bnCtrl = TextEditingController(text: '১৫ দিন');
    final enCtrl = TextEditingController(text: '15 Days');
    final chipLabelCtrl = TextEditingController(text: '১৫ দিন / 15d');

    void updateCalculations(StateSetter setDialogState) {
      final val = int.tryParse(valueCtrl.text.trim().toEnglishDigits()) ?? 0;
      if (val <= 0) return;

      int calcDays;
      String autoBn;
      String autoEn;
      String autoChip;

      if (selectedUnit == 'month') {
        calcDays = val * 30;
        autoBn = '$val মাস';
        autoEn = '$val ${val == 1 ? "Month" : "Months"}';
        autoChip = '${val.toString().toLocalizedDigits("bn")} মাস / ${calcDays}d';
      } else if (selectedUnit == 'year') {
        calcDays = val * 365;
        autoBn = '$val বছর';
        autoEn = '$val ${val == 1 ? "Year" : "Years"}';
        autoChip = '${val.toString().toLocalizedDigits("bn")} বছর / ${val}y';
      } else {
        calcDays = val;
        autoBn = '$val দিন';
        autoEn = '$val ${val == 1 ? "Day" : "Days"}';
        autoChip = '${val.toString().toLocalizedDigits("bn")} দিন / ${val}d';
      }

      bnCtrl.text = autoBn.toLocalizedDigits('bn');
      enCtrl.text = autoEn;
      chipLabelCtrl.text = autoChip;
      setDialogState(() {});
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final parsedVal = int.tryParse(valueCtrl.text.trim().toEnglishDigits()) ?? 1;
            final currentCalculatedDays = selectedUnit == 'month'
                ? parsedVal * 30
                : selectedUnit == 'year'
                    ? parsedVal * 365
                    : parsedVal;

            return Dialog(
              backgroundColor: widget.isDark ? const Color(0xFF16211F) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: roleAccentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.timer_rounded, color: roleAccentColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isBn ? 'নতুন মেয়াদ যোগ করুন' : 'Add Custom Duration',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                Text(
                                  widget.isBn
                                      ? 'দিন, মাস বা বছর সিলেক্ট করে কাস্টম মেয়াদ নির্ধারণ করুন'
                                      : 'Select Day, Month, or Year to set package validity',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1. Unit Selector (দিন / মাস / বছর)
                      Text(
                        widget.isBn ? '১. মেয়াদের একক নির্বাচন করুন (Unit):' : '1. Select Duration Unit:',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              avatar: const Icon(Icons.today_rounded, size: 16),
                              label: Text(widget.isBn ? '📅 দিন (Days)' : '📅 Days'),
                              selected: selectedUnit == 'day',
                              selectedColor: roleAccentColor.withValues(alpha: 0.2),
                              onSelected: (v) {
                                if (v) {
                                  selectedUnit = 'day';
                                  if (valueCtrl.text == '1' || valueCtrl.text == '১') {
                                    valueCtrl.text = '15';
                                  }
                                  updateCalculations(setDialogState);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              avatar: const Icon(Icons.date_range_rounded, size: 16),
                              label: Text(widget.isBn ? '🗓️ মাস (Months)' : '🗓️ Months'),
                              selected: selectedUnit == 'month',
                              selectedColor: roleAccentColor.withValues(alpha: 0.2),
                              onSelected: (v) {
                                if (v) {
                                  selectedUnit = 'month';
                                  if (valueCtrl.text == '15' || valueCtrl.text == '১৫') {
                                    valueCtrl.text = '1';
                                  }
                                  updateCalculations(setDialogState);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                              label: Text(widget.isBn ? '📆 বছর (Years)' : '📆 Years'),
                              selected: selectedUnit == 'year',
                              selectedColor: roleAccentColor.withValues(alpha: 0.2),
                              onSelected: (v) {
                                if (v) {
                                  selectedUnit = 'year';
                                  if (valueCtrl.text == '15' || valueCtrl.text == '১৫') {
                                    valueCtrl.text = '1';
                                  }
                                  updateCalculations(setDialogState);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Quick presets based on unit
                      Text(
                        widget.isBn ? 'কুইক অপশন:' : 'Quick Options:',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (selectedUnit == 'day')
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _quickUnitOptionChip(setDialogState, valueCtrl, '7', () => updateCalculations(setDialogState), '৭ দিন'),
                            _quickUnitOptionChip(setDialogState, valueCtrl, '15', () => updateCalculations(setDialogState), '১৫ দিন'),
                            _quickUnitOptionChip(setDialogState, valueCtrl, '45', () => updateCalculations(setDialogState), '৪৫ দিন'),
                            _quickUnitOptionChip(setDialogState, valueCtrl, '90', () => updateCalculations(setDialogState), '৯০ দিন'),
                          ],
                        )
                      else if (selectedUnit == 'month')
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _quickUnitOptionChip(setDialogState, valueCtrl, '1', () => updateCalculations(setDialogState), '১ মাস'),
                            _quickUnitOptionChip(setDialogState, valueCtrl, '2', () => updateCalculations(setDialogState), '২ মাস'),
                            _quickUnitOptionChip(setDialogState, valueCtrl, '3', () => updateCalculations(setDialogState), '৩ মাস'),
                            _quickUnitOptionChip(setDialogState, valueCtrl, '6', () => updateCalculations(setDialogState), '৬ মাস'),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _quickUnitOptionChip(setDialogState, valueCtrl, '1', () => updateCalculations(setDialogState), '১ বছর'),
                            _quickUnitOptionChip(setDialogState, valueCtrl, '2', () => updateCalculations(setDialogState), '২ বছর'),
                            _quickUnitOptionChip(setDialogState, valueCtrl, '3', () => updateCalculations(setDialogState), '৩ বছর'),
                            _quickUnitOptionChip(setDialogState, valueCtrl, '5', () => updateCalculations(setDialogState), '৫ বছর'),
                          ],
                        ),
                      const SizedBox(height: 14),

                      // Number input field
                      TextField(
                        controller: valueCtrl,
                        keyboardType: TextInputType.text,
                        onChanged: (val) {
                          updateCalculations(setDialogState);
                        },
                        decoration: InputDecoration(
                          labelText: selectedUnit == 'month'
                              ? (widget.isBn ? 'কত মাস? (যেমন: 1 বা ১, 6 বা ৬)*' : 'Number of Months (e.g. 1 or 6)*')
                              : selectedUnit == 'year'
                                  ? (widget.isBn ? 'কত বছর? (যেমন: 1 বা ১, 2 বা ২)*' : 'Number of Years (e.g. 1 or 2)*')
                                  : (widget.isBn ? 'কত দিন? (যেমন: 15 বা ১৫, 45 বা ৪৫)*' : 'Number of Days (e.g. 15 or 45)*'),
                          hintText: selectedUnit == 'month' ? '1 বা ৬' : selectedUnit == 'year' ? '1 বা ২' : '15 বা ৪৫',
                          prefixIcon: const Icon(Icons.edit_calendar_rounded, size: 18),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bnCtrl,
                              decoration: const InputDecoration(
                                labelText: 'বাংলায় মেয়াদের নাম*',
                                hintText: 'যেমন: ১৫ দিন বা ৬ মাস',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: enCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Duration in English*',
                                hintText: 'e.g. 15 Days or 6 Months',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: chipLabelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'চিপ ডিসপ্লে লেবেল (ঐচ্ছিক)',
                          hintText: 'যেমন: ৬ মাস / 180d',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Firebase calculation badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: roleAccentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: roleAccentColor.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_done_rounded, color: roleAccentColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Wrap(
                                spacing: 14,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    '🔥 ফায়ারবেস মেয়াদ: $currentCalculatedDays দিন ($currentCalculatedDays Days)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: roleAccentColor),
                                  ),
                                  Text(
                                    '🇧🇩 ${bnCtrl.text}  |  🇺🇸 ${enCtrl.text}',
                                    style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.grey[300] : Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text(widget.isBn ? 'বাতিল' : 'Cancel'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: roleAccentColor,
                              foregroundColor: widget.targetRole == SubscriptionTargetRole.tenant ? Colors.white : Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                              widget.isBn ? 'যুক্ত ও সিলেক্ট করুন' : 'Add & Select',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              final val = int.tryParse(valueCtrl.text.trim().toEnglishDigits());
                              if (val == null || val <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(widget.isBn ? 'দয়া করে সঠিক সংখ্যা লিখুন।' : 'Please enter valid number.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              final calculatedDays = selectedUnit == 'month'
                                  ? val * 30
                                  : selectedUnit == 'year'
                                      ? val * 365
                                      : val;

                              final bn = bnCtrl.text.trim().isNotEmpty
                                  ? bnCtrl.text.trim()
                                  : (selectedUnit == 'month' ? '$val মাস' : selectedUnit == 'year' ? '$val বছর' : '$val দিন');
                              final en = enCtrl.text.trim().isNotEmpty
                                  ? enCtrl.text.trim()
                                  : (selectedUnit == 'month' ? '$val ${val == 1 ? "Month" : "Months"}' : selectedUnit == 'year' ? '$val ${val == 1 ? "Year" : "Years"}' : '$val ${val == 1 ? "Day" : "Days"}');
                              final label = chipLabelCtrl.text.trim().isNotEmpty
                                  ? chipLabelCtrl.text.trim()
                                  : '$bn / ${calculatedDays}d';

                              setState(() {
                                final existingIdx = _durationPresets.indexWhere((p) => p.days == calculatedDays);
                                final newPreset = _DurationPresetItem(
                                  days: calculatedDays,
                                  value: val,
                                  unit: selectedUnit,
                                  label: label,
                                  bn: bn,
                                  en: en,
                                );
                                if (existingIdx >= 0) {
                                  _durationPresets[existingIdx] = newPreset;
                                } else {
                                  _durationPresets.add(newPreset);
                                }
                                _durationDaysController.text = calculatedDays.toString();
                                _durationBnController.text = bn;
                                _durationEnController.text = en;
                              });
                              Navigator.pop(dialogCtx);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickUnitOptionChip(
    StateSetter setDialogState,
    TextEditingController valueCtrl,
    String val,
    VoidCallback onUpdated,
    String label,
  ) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        valueCtrl.text = val;
        onUpdated();
      },
    );
  }

  Widget _quickPerkChip(String bn, String en) {
    return ActionChip(
      avatar: const Icon(Icons.add_rounded, size: 14),
      label: Text(bn, style: const TextStyle(fontSize: 11)),
      onPressed: () => _addSuggestedPerk(bn.replaceFirst('+ ', ''), en.replaceFirst('+ ', '')),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color),
    );
  }

  Widget _buildLivePreviewCard(Color roleAccentColor) {
    final title = _previewInEnglish
        ? (_titleEnController.text.trim().isNotEmpty ? _titleEnController.text.trim() : 'Plan Title (EN)')
        : (_titleBnController.text.trim().isNotEmpty ? _titleBnController.text.trim() : 'প্যাকেজের নাম (বাংলা)');

    final description = _previewInEnglish ? _descEnController.text.trim() : _descBnController.text.trim();
    final regularPrice = double.tryParse(_priceController.text.trim().toEnglishDigits()) ?? 200.0;
    final duration = int.tryParse(_durationDaysController.text.trim().toEnglishDigits()) ?? 15;
    final durationBnText = _durationBnController.text.trim().isNotEmpty
        ? _durationBnController.text.trim()
        : '${duration.toString().toLocalizedDigits("bn")} দিন';
    final durationEnText = _durationEnController.text.trim().isNotEmpty
        ? _durationEnController.text.trim()
        : '$duration Days';

    final offerPrice = _hasOffer ? double.tryParse(_offerPriceController.text.trim().toEnglishDigits()) : null;
    final effectivePrice = (_hasOffer && offerPrice != null) ? offerPrice : regularPrice;

    final badge = _previewInEnglish
        ? (_badgeEnController.text.trim().isNotEmpty ? _badgeEnController.text.trim() : '20% OFF')
        : (_badgeBnController.text.trim().isNotEmpty ? _badgeBnController.text.trim() : '২০% ছাড়');

    final perks = _perkPairs.map((p) => _previewInEnglish ? p.enController.text.trim() : p.bnController.text.trim()).where((t) => t.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF172220) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isPopular ? roleAccentColor : (widget.isDark ? const Color(0xFF263936) : const Color(0xFFE2EBE9)),
          width: _isPopular ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: roleAccentColor.withValues(alpha: widget.isDark ? 0.15 : 0.05),
            blurRadius: 12,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pricing Strip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _previewInEnglish
                          ? '৳${effectivePrice.toInt()}'
                          : '৳${effectivePrice.toInt().toString().toLocalizedDigits("bn")}',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: roleAccentColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _previewInEnglish
                          ? '/ $durationEnText'
                          : '/ $durationBnText',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    if (_hasOffer) ...[
                      const SizedBox(width: 10),
                      Text(
                        _previewInEnglish
                            ? '৳${regularPrice.toInt()}'
                            : '৳${regularPrice.toInt().toString().toLocalizedDigits("bn")}',
                        style: const TextStyle(fontSize: 15, color: Colors.grey, decoration: TextDecoration.lineThrough),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  _previewInEnglish ? 'Included Plan Perks:' : 'প্যাকেজ অ্যাক্টিভ করলে যা যা পাবেনঃ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: roleAccentColor),
                ),
                const SizedBox(height: 8),

                Column(
                  children: perks.map((perk) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: roleAccentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(perk, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: roleAccentColor,
                      foregroundColor: widget.targetRole == SubscriptionTargetRole.tenant ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _previewInEnglish
                          ? '৳${effectivePrice.toInt()} • Choose Plan'
                          : '৳${effectivePrice.toInt().toString().toLocalizedDigits("bn")} • প্যাকেজ নিন',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_hasOffer && badge.isNotEmpty)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(18), bottomLeft: Radius.circular(12)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            )
          else if (_isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(18), bottomLeft: Radius.circular(12)),
                ),
                child: Text(
                  _previewInEnglish ? 'POPULAR' : 'জনপ্রিয়',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _savePlan() async {
    final titleBn = _titleBnController.text.trim();
    final titleEn = _titleEnController.text.trim();
    final regular = double.tryParse(_priceController.text.trim().toEnglishDigits());
    final duration = int.tryParse(_durationDaysController.text.trim().toEnglishDigits());

    if (titleBn.isEmpty || regular == null || duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isBn ? 'দয়া করে প্যাকেজের নাম, মূল্য ও মেয়াদ সঠিকভাবে লিখুন।' : 'Please enter valid name, price, and duration.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final durationBn = _durationBnController.text.trim().isNotEmpty
        ? _durationBnController.text.trim()
        : '$duration দিন';
    final durationEn = _durationEnController.text.trim().isNotEmpty
        ? _durationEnController.text.trim()
        : '$duration Days';

    final offer = _hasOffer ? double.tryParse(_offerPriceController.text.trim().toEnglishDigits()) : null;
    final perksBn = _perkPairs.map((p) => p.bnController.text.trim()).where((t) => t.isNotEmpty).toList();
    final perksEn = _perkPairs.map((p) => p.enController.text.trim()).where((t) => t.isNotEmpty).toList();

    final isEdit = widget.existingPlan != null;
    final planId = isEdit
        ? widget.existingPlan!.id
        : '${widget.targetRole == SubscriptionTargetRole.tenant ? "tenant" : "owner"}_${DateTime.now().millisecondsSinceEpoch}';

    final matchedPreset = _durationPresets.cast<_DurationPresetItem?>().firstWhere(
      (p) => p?.days == duration,
      orElse: () => null,
    );
    final durationValue = matchedPreset?.value ?? duration;
    final durationUnit = matchedPreset?.unit ?? 'day';

    final finalPlan = SubscriptionPlanModel(
      id: planId,
      titleBn: titleBn,
      titleEn: titleEn.isNotEmpty ? titleEn : titleBn,
      descriptionBn: _descBnController.text.trim().isNotEmpty ? _descBnController.text.trim() : '$durationBn স্পেশাল প্যাকেজ',
      descriptionEn: _descEnController.text.trim().isNotEmpty ? _descEnController.text.trim() : '$durationEn special plan',
      regularPrice: regular,
      durationDays: duration,
      durationValue: durationValue,
      durationUnit: durationUnit,
      durationBn: durationBn,
      durationEn: durationEn,
      targetRole: widget.targetRole,
      hasActiveOffer: _hasOffer,
      offerPrice: offer,
      offerBadgeTextBn: _badgeBnController.text.trim(),
      offerBadgeTextEn: _badgeEnController.text.trim(),
      perksBn: perksBn,
      perksEn: perksEn.isNotEmpty ? perksEn : perksBn,
      isPopular: _isPopular,
      displayOrder: isEdit ? widget.existingPlan!.displayOrder : 99,
    );

    Navigator.pop(context);
    final subProvider = context.read<SubscriptionProvider>();

    if (isEdit) {
      await subProvider.updatePlanDetails(finalPlan);
    } else {
      await subProvider.createPlan(finalPlan);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? (widget.isBn ? 'প্যাকেজটি সফলভাবে আপডেট করা হয়েছে!' : 'Package updated successfully!')
                : (widget.isBn ? 'নতুন দ্বিভাষিক প্যাকেজ সফলভাবে তৈরি হয়েছে!' : 'New bilingual package published successfully!'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _PerkPairControllers {
  final TextEditingController bnController;
  final TextEditingController enController;

  _PerkPairControllers({
    required this.bnController,
    required this.enController,
  });
}

class _DurationPresetItem {
  final int days;
  final int value;
  final String unit; // 'day', 'month', 'year'
  final String label;
  final String bn;
  final String en;

  const _DurationPresetItem({
    required this.days,
    this.value = 0,
    this.unit = 'day',
    required this.label,
    required this.bn,
    required this.en,
  });
}
