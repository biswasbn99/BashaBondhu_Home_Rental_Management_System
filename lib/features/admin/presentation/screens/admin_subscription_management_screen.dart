import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../data/providers/admin_provider.dart';
import '../../../subscription/data/models/subscription_model.dart';
import '../../../subscription/data/models/free_tier_policy_model.dart';
import '../../../subscription/data/providers/subscription_provider.dart';
import '../../../subscription/data/services/subscription_firestore_service.dart';

class AdminSubscriptionManagementView extends StatefulWidget {
  const AdminSubscriptionManagementView({super.key});

  @override
  State<AdminSubscriptionManagementView> createState() => _AdminSubscriptionManagementViewState();
}

class _AdminSubscriptionManagementViewState extends State<AdminSubscriptionManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  late final SubscriptionFirestoreService _service;
  late final Stream<List<SubscriptionPlanModel>> _allPlansStream;
  late final Stream<List<SubscriptionTransactionModel>> _allTransactionsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_selectedTabIndex != _tabController.index) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _service = SubscriptionFirestoreService();
    _service.seedDefaultPlansIfEmpty(forceCheck: true);
    _allPlansStream = _service.streamAllPlans();
    _allTransactionsStream = _service.streamAllTransactions();
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
    final isBn = context.select<AdminProvider, bool>((p) => p.isBangla);

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
            _buildMetricsOverview(context, _allPlansStream, _allTransactionsStream, isDark, isBn),
            const SizedBox(height: 24),

            // Modern Tab Bar
            _buildModernTabBar(isDark, isBn),
            const SizedBox(height: 20),

            // Tab Content
            _buildActiveTabContent(isBn, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isBn, bool isDark) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildPlansTab(
          context,
          _service.streamAllPlans(),
          isBn,
          isDark,
          SubscriptionTargetRole.tenant,
        );
      case 1:
        return _buildPlansTab(
          context,
          _service.streamAllPlans(),
          isBn,
          isDark,
          SubscriptionTargetRole.houseOwner,
        );
      case 2:
        return _AdminTransactionsTab(
          isBn: isBn,
          isDark: isDark,
        );
      case 3:
      default:
        return _AdminFreeTierPolicyTab(
          isBn: isBn,
          isDark: isDark,
        );
    }
  }

  Widget _buildTopHeader(BuildContext context, bool isDark, bool isBn) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;
        final titleWidget = Row(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'সাবস্ক্রিপশন ও প্যাকেজ স্টুডিও' : 'Subscription & Package Studio',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isBn
                        ? 'ভাড়াটিয়া ও বাড়িওয়ালাদের প্যাকেজ, ফ্রি অ্যাকাউন্ট পলিসি ও প্রাইসিং কন্ট্রোল'
                        : 'Manage tenant & house owner packages, free tier policy & prices',
                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        );

        final buttonWidget = FilledButton.icon(
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 12),
              buttonWidget,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 16),
            buttonWidget,
          ],
        );
      },
    );
  }

  Widget _buildMetricsOverview(
    BuildContext context,
    Stream<List<SubscriptionPlanModel>> plansStream,
    Stream<List<SubscriptionTransactionModel>> txStream,
    bool isDark,
    bool isBn,
  ) {
    return StreamBuilder<List<SubscriptionPlanModel>>(
      stream: plansStream,
      builder: (context, planSnapshot) {
        final plans = planSnapshot.data ?? [];
        final tenantCount = plans.where((p) => p.targetRole == SubscriptionTargetRole.tenant).length;
        final ownerCount = plans.where((p) => p.targetRole == SubscriptionTargetRole.houseOwner).length;
        final offerCount = plans.where((p) => p.hasActiveOffer).length;

        return StreamBuilder<List<SubscriptionTransactionModel>>(
          stream: txStream,
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
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
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
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          Tab(
            icon: const Icon(Icons.tune_rounded, size: 18),
            text: isBn ? 'ফ্রি অ্যাকাউন্ট পলিসি (Free Tier)' : 'Free Tier Policy',
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final subProvider = context.read<SubscriptionProvider>();
                      final success = await subProvider.restoreDefaultPlans();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? (isBn ? 'ডিফল্ট প্যাকেজসমূহ রিস্টোর করা হয়েছে।' : 'Default plans restored successfully.')
                                : (isBn ? 'রিস্টোর করতে ব্যর্থ হয়েছে।' : 'Failed to restore default plans.')),
                            backgroundColor: success ? Colors.green : Colors.redAccent,
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeColor,
                      side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: Text(
                      isBn ? 'ডিফল্ট রিস্টোর' : 'Restore Defaults',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      isBn ? '+ নতুন প্যাকেজ তৈরি' : '+ Create New Plan',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Plans Grid
        StreamBuilder<List<SubscriptionPlanModel>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.themeColor)),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        isBn ? 'প্যাকেজ লোড করতে সমস্যা হয়েছে' : 'Error loading subscription plans',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(isBn ? 'পুনরায় চেষ্টা করুন' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allPlans = snapshot.data ?? [];
            final plans = allPlans.where((p) => p.targetRole == targetRole).toList();
            if (plans.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        isBn ? 'কোনো প্যাকেজ পাওয়া যায়নি' : 'No subscription plans found',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _showPlanStudioDialog(context, targetRole: targetRole, existingPlan: null, isDark: isDark, isBn: isBn),
                            style: FilledButton.styleFrom(backgroundColor: themeColor),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(isBn ? 'প্রথম প্যাকেজ তৈরি করুন' : 'Create First Plan'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final subProvider = context.read<SubscriptionProvider>();
                              final success = await subProvider.restoreDefaultPlans();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? (isBn ? 'ডিফল্ট প্যাকেজসমূহ রিস্টোর করা হয়েছে।' : 'Default plans restored successfully.')
                                        : (isBn ? 'রিস্টোর করতে ব্যর্থ হয়েছে।' : 'Failed to restore default plans.')),
                                    backgroundColor: success ? Colors.green : Colors.redAccent,
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: themeColor, side: BorderSide(color: themeColor)),
                            icon: const Icon(Icons.restore_rounded),
                            label: Text(isBn ? 'ডিফল্ট ৩টি প্যাকেজ রিস্টোর করুন' : 'Restore Default 3 Plans'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plans.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _buildAdminPlanCard(context, plan, isBn, isDark, themeColor);
              },
            );
          },
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
                const SizedBox(height: 10),

                // Quota & Facility Control Badges
                Text(
                  isBn ? 'সক্রিয় কোটা ও সু্যোগ-সুবিধা:' : 'Active Quotas & Facilities:',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _quotaBadge(
                      Icons.post_add_rounded,
                      isBn
                          ? (plan.maxPostsLimit == -1 ? 'পোস্ট: আনলিমিটেড' : 'পোস্ট: ${plan.maxPostsLimit.toString().toLocalizedDigits("bn")}টি')
                          : (plan.maxPostsLimit == -1 ? 'Posts: Unlimited' : 'Posts: ${plan.maxPostsLimit}'),
                      Colors.blue,
                      isDark,
                    ),
                    _quotaBadge(
                      Icons.lock_open_rounded,
                      isBn
                          ? (plan.unlockNumbersLimit == -1 ? 'নম্বর: আনলিমিটেড' : 'নম্বর: ${plan.unlockNumbersLimit.toString().toLocalizedDigits("bn")}টি')
                          : (plan.unlockNumbersLimit == -1 ? 'Unlocks: Unlimited' : 'Unlocks: ${plan.unlockNumbersLimit}'),
                      Colors.green,
                      isDark,
                    ),
                    _quotaBadge(
                      Icons.photo_library_rounded,
                      isBn
                          ? (plan.canAccessAdditionalPhotos ? 'সকল ছবি: উন্মুক্ত' : 'ছবি: সীমিত')
                          : (plan.canAccessAdditionalPhotos ? 'Photos: Full Access' : 'Photos: Template Only'),
                      Colors.purple,
                      isDark,
                    ),
                    _quotaBadge(
                      Icons.radar_rounded,
                      isBn
                          ? (plan.nearbySearchLimit == -1 ? 'কাছাকাছি সার্চ: আনলিমিটেড' : 'কাছাকাছি সার্চ: ${plan.nearbySearchLimit.toString().toLocalizedDigits("bn")}টি')
                          : (plan.nearbySearchLimit == -1 ? 'Nearby: Unlimited' : 'Nearby: ${plan.nearbySearchLimit}'),
                      Colors.teal,
                      isDark,
                    ),
                    _quotaBadge(
                      Icons.directions_rounded,
                      isBn
                          ? (plan.mapDirectionsLimit == -1 ? 'ম্যাপ ডিরেকশন: আনলিমিটেড' : 'ম্যাপ ডিরেকশন: ${plan.mapDirectionsLimit.toString().toLocalizedDigits("bn")}টি')
                          : (plan.mapDirectionsLimit == -1 ? 'Directions: Unlimited' : 'Directions: ${plan.mapDirectionsLimit}'),
                      Colors.amber.shade800,
                      isDark,
                    ),
                    _quotaBadge(
                      Icons.auto_awesome_rounded,
                      isBn
                          ? (plan.aiAssistantLimit == -1 ? 'AI সহকারী: আনলিমিটেড' : 'AI সহকারী: ${plan.aiAssistantLimit.toString().toLocalizedDigits("bn")}টি')
                          : (plan.aiAssistantLimit == -1 ? 'AI: Unlimited' : 'AI: ${plan.aiAssistantLimit}'),
                      Colors.indigo,
                      isDark,
                    ),
                  ],
                ),
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
              final success = await subProvider.deletePlan(plan.id);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBn ? 'প্যাকেজটি সফলভাবে ডিলিট করা হয়েছে।' : 'Plan deleted successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBn
                          ? 'প্যাকেজ ডিলিট করতে সমস্যা হয়েছে: ${subProvider.errorMessage ?? "অজানা ত্রুটি"}'
                          : 'Failed to delete plan: ${subProvider.errorMessage ?? "Unknown error"}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
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

  Widget _quotaBadge(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 📊 ADMIN TRANSACTIONS TAB (SUBSCRIBERS & TRANSACTIONS)
// ============================================================================
class _AdminTransactionsTab extends StatefulWidget {
  final bool isBn;
  final bool isDark;

  const _AdminTransactionsTab({
    required this.isBn,
    required this.isDark,
  });

  @override
  State<_AdminTransactionsTab> createState() => _AdminTransactionsTabState();
}

class _AdminTransactionsTabState extends State<_AdminTransactionsTab> {
  late Stream<List<SubscriptionTransactionModel>> _txStream;

  @override
  void initState() {
    super.initState();
    _txStream = SubscriptionFirestoreService().streamAllTransactions();
  }

  void _refresh() {
    setState(() {
      _txStream = SubscriptionFirestoreService().streamAllTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBn;
    final isDark = widget.isDark;

    return StreamBuilder<List<SubscriptionTransactionModel>>(
      stream: _txStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: AppColors.themeColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  isBn ? 'লেনদেন তালিকা লোড করতে ত্রুটি হয়েছে' : 'Error loading transactions',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(isBn ? 'পুনরায় চেষ্টা করুন' : 'Retry'),
                ),
              ],
            ),
          );
        }

        final txs = snapshot.data ?? [];
        if (txs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    isBn ? 'এখনও কোনো সাবস্ক্রিপশন লেনদেন হয়নি' : 'No subscription transactions yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(isBn ? 'রিফ্রেশ করুন' : 'Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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

  // Quota & Facility Controllers & Toggles
  // 1. Max Demands / Listings
  late bool _enableMaxPosts;
  late bool _isUnlimitedPosts;
  late final TextEditingController _maxPostsController;

  // 2. Unlock Numbers
  late bool _enableUnlockNumbers;
  late bool _isUnlimitedUnlocks;
  late final TextEditingController _unlockNumbersController;

  // 3. Sub-area Unlock
  late bool _enableSubArea;
  late bool _isUnlimitedSubArea;
  late final TextEditingController _subAreaController;

  // 4. Photo Gallery (Tenant only)
  late bool _enablePhotoGallery;
  late bool _isUnlimitedPhotoGallery;
  late final TextEditingController _photoGalleryController;

  // 5. Nearby Search (Tenant only)
  late bool _enableNearbySearch;
  late bool _isUnlimitedNearby;
  late final TextEditingController _nearbySearchController;

  // 6. Map Directions (Tenant only)
  late bool _enableMapDirections;
  late bool _isUnlimitedDirections;
  late final TextEditingController _mapDirectionsController;

  // 7. AI Assistant Search
  late bool _enableAiAssistant;
  late bool _isUnlimitedAi;
  late final TextEditingController _aiAssistantController;

  late bool _isPopular;
  late bool _hasOffer;
  bool _previewInEnglish = false;
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

    // 1. Max Demands / Listings
    final initialMaxPosts = p?.maxPostsLimit ?? (widget.targetRole == SubscriptionTargetRole.tenant ? 5 : 10);
    _enableMaxPosts = initialMaxPosts != 0;
    _isUnlimitedPosts = initialMaxPosts == -1;
    _maxPostsController = TextEditingController(
      text: (_isUnlimitedPosts || !_enableMaxPosts) ? (widget.targetRole == SubscriptionTargetRole.tenant ? '5' : '10') : initialMaxPosts.toString(),
    );

    // 2. Unlock Numbers
    final initialUnlocks = p?.unlockNumbersLimit ?? -1;
    _enableUnlockNumbers = initialUnlocks != 0;
    _isUnlimitedUnlocks = initialUnlocks == -1;
    _unlockNumbersController = TextEditingController(
      text: (_isUnlimitedUnlocks || !_enableUnlockNumbers) ? '10' : initialUnlocks.toString(),
    );

    // 3. Sub-area Unlock
    final initialSubArea = p?.subAreaUnlockLimit ?? -1;
    _enableSubArea = initialSubArea != 0;
    _isUnlimitedSubArea = initialSubArea == -1;
    _subAreaController = TextEditingController(
      text: (_isUnlimitedSubArea || !_enableSubArea) ? '5' : initialSubArea.toString(),
    );

    // 4. Photo Gallery (Tenant only)
    final initialPhotoGallery = p?.fullPhotoGalleryLimit ?? -1;
    _enablePhotoGallery = initialPhotoGallery != 0;
    _isUnlimitedPhotoGallery = initialPhotoGallery == -1;
    _photoGalleryController = TextEditingController(
      text: (_isUnlimitedPhotoGallery || !_enablePhotoGallery) ? '10' : initialPhotoGallery.toString(),
    );

    // 5. Nearby Search (Tenant only)
    final initialNearby = p?.nearbySearchLimit ?? 10;
    _enableNearbySearch = initialNearby != 0;
    _isUnlimitedNearby = initialNearby == -1;
    _nearbySearchController = TextEditingController(
      text: (_isUnlimitedNearby || !_enableNearbySearch) ? '10' : initialNearby.toString(),
    );

    // 6. Map Directions (Tenant only)
    final initialDirections = p?.mapDirectionsLimit ?? 10;
    _enableMapDirections = initialDirections != 0;
    _isUnlimitedDirections = initialDirections == -1;
    _mapDirectionsController = TextEditingController(
      text: (_isUnlimitedDirections || !_enableMapDirections) ? '10' : initialDirections.toString(),
    );

    // 7. AI Assistant Search
    final initialAi = p?.aiAssistantLimit ?? -1;
    _enableAiAssistant = initialAi != 0;
    _isUnlimitedAi = initialAi == -1;
    _aiAssistantController = TextEditingController(
      text: (_isUnlimitedAi || !_enableAiAssistant) ? '50' : initialAi.toString(),
    );

    _isPopular = p?.isPopular ?? false;
    _hasOffer = p?.hasActiveOffer ?? false;
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
    _maxPostsController.dispose();
    _unlockNumbersController.dispose();
    _subAreaController.dispose();
    _photoGalleryController.dispose();
    _nearbySearchController.dispose();
    _mapDirectionsController.dispose();
    _aiAssistantController.dispose();
    super.dispose();
  }

  int _getFacilityVal(bool enabled, bool isUnlimited, TextEditingController ctrl, int defaultVal) {
    if (!enabled) return 0;
    if (isUnlimited) return -1;
    final parsed = int.tryParse(ctrl.text.trim().toEnglishDigits());
    return (parsed != null && parsed > 0) ? parsed : defaultVal;
  }

  void _applyDurationPreset(int days, String labelBn, String labelEn) {
    setState(() {
      _durationDaysController.text = days.toString();
      _durationBnController.text = labelBn;
      _durationEnController.text = labelEn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTenant = widget.targetRole == SubscriptionTargetRole.tenant;
    final roleAccentColor = isTenant ? const Color(0xFF0D9488) : const Color(0xFFF59E0B);
    final isEdit = widget.existingPlan != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: widget.isDark ? const Color(0xFF16211F) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: screenWidth > 860 ? 820 : screenWidth * 0.95,
        constraints: BoxConstraints(maxHeight: screenHeight > 900 ? 880 : screenHeight * 0.92),
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
                                ? (widget.isBn ? 'ভাড়াটিয়াদের (Tenant) জন্য ৭টি অটোমেটেড সুবিধা প্যাকেজ' : 'For Tenant Users (7 Automated Facilities)')
                                : (widget.isBn ? 'বাড়িওয়ালাদের (House Owner) জন্য ৪টি অটোমেটেড সুবিধা প্যাকেজ' : 'For House Owner Users (4 Automated Facilities)'),
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
                    _sectionTitle('২. মূল্য ও মেয়াদ (Pricing & Duration Presets)', roleAccentColor),
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

                    // Section 4: Package Facility Quota & Control (ON/OFF + Set Number / Unlimited)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle(
                          isTenant
                              ? '৪. ভাড়াটিয়া সুবিধা নির্ধারণ (Tenant 7 Facilities Control)'
                              : '৪. বাড়িওয়ালা সুবিধা নির্ধারণ (Owner 4 Facilities Control)',
                          roleAccentColor,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleAccentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.isBn ? 'স্বয়ংক্রিয় ফিচারস ও পার্কস' : 'Auto Features & Perks',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleAccentColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isBn
                          ? 'প্রতিটি সুবিধার জন্য ক্লিকযোগ্য ON/OFF সুইচ রয়েছে। সুইচ OFF রাখলে সেই সুবিধাটি বন্ধ থাকবে (ইউজার ব্যবহার বা দেখতে পারবে না)। সুইচ ON থাকলে নির্দিষ্ট সংখ্যা বা আনলিমিটেড নির্বাচন করুন। এর ভিত্তিতে প্যাকেজের সুবিধাসমূহ বাংলায় ও ইংরেজিতে স্বয়ংক্রিয়ভাবে তৈরি হবে।'
                          : 'Each facility has a clickable ON/OFF switch. If OFF, the feature is disabled (0). If ON, select between Set Number or Unlimited. Perks in Bengali & English are auto-generated based on these settings.',
                      style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(height: 14),

                    // Renders 7 facilities for Tenant, 4 facilities for Owner
                    _buildQuotaControlSection(roleAccentColor),

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

  Widget _buildQuotaControlSection(Color roleAccentColor) {
    if (widget.targetRole == SubscriptionTargetRole.tenant) {
      // 7 Tenant Facilities
      return Column(
        children: [
          // 1. Max rental Demand allowed
          _buildFacilityControlItem(
            icon: Icons.post_add_rounded,
            iconColor: const Color(0xFF0D9488),
            titleBn: '১. ভাড়ার চাহিদা (Demand) পোস্ট লিমিট',
            titleEn: '1. Max Rental Demand Allowed',
            descBn: 'ভাড়াটিয়া সর্বোচ্চ কতটি বাসা খোঁজার চাহিদা পোস্ট করতে পারবে',
            descEn: 'Maximum number of rental demands tenant can post',
            isEnabled: _enableMaxPosts,
            onToggleEnabled: (val) => _enableMaxPosts = val,
            isUnlimited: _isUnlimitedPosts,
            onToggleUnlimited: (val) => _isUnlimitedPosts = val,
            controller: _maxPostsController,
            hintText: '5',
            roleAccentColor: roleAccentColor,
          ),

          // 2. Contact Numbers unlock limit
          _buildFacilityControlItem(
            icon: Icons.phone_in_talk_rounded,
            iconColor: const Color(0xFF2563EB),
            titleBn: '২. বাড়িওয়ালার কন্টাক্ট নম্বর আনলক লিমিট',
            titleEn: '2. Landlord Contact Numbers Unlock Limit',
            descBn: 'ভাড়াটিয়া সর্বোচ্চ কতজন বাড়িওয়ালার সরাসরি ফোন নম্বর আনলক করতে পারবে',
            descEn: 'Maximum landlord contact numbers tenant can unlock',
            isEnabled: _enableUnlockNumbers,
            onToggleEnabled: (val) => _enableUnlockNumbers = val,
            isUnlimited: _isUnlimitedUnlocks,
            onToggleUnlimited: (val) => _isUnlimitedUnlocks = val,
            controller: _unlockNumbersController,
            hintText: '10',
            roleAccentColor: roleAccentColor,
          ),

          // 3. Sub area unlock limit
          _buildFacilityControlItem(
            icon: Icons.location_city_rounded,
            iconColor: const Color(0xFF059669),
            titleBn: '৩. সাব-এরিয়া লোকেশন আনলক লিমিট',
            titleEn: '3. Sub-Area Location Unlock Limit',
            descBn: 'বাসার বিস্তারিত সাব-এরিয়া / এলাকা দেখার এক্সেস লিমিট',
            descEn: 'Access to specific sub-area addresses and locations',
            isEnabled: _enableSubArea,
            onToggleEnabled: (val) => _enableSubArea = val,
            isUnlimited: _isUnlimitedSubArea,
            onToggleUnlimited: (val) => _isUnlimitedSubArea = val,
            controller: _subAreaController,
            hintText: '5',
            roleAccentColor: roleAccentColor,
          ),

          // 4. Full photo Gallery Access limit
          _buildFacilityControlItem(
            icon: Icons.photo_library_rounded,
            iconColor: const Color(0xFF9333EA),
            titleBn: '৪. সকল অতিরিক্ত ছবি ও ফুল গ্যালারি এক্সেস লিমিট',
            titleEn: '4. Full Photo Gallery Access Limit',
            descBn: 'বাসার সকল রুম ও ওয়াশরুমের অতিরিক্ত ছবি দেখার লিমিট',
            descEn: 'Access full gallery of all owner photos beyond preview',
            isEnabled: _enablePhotoGallery,
            onToggleEnabled: (val) => _enablePhotoGallery = val,
            isUnlimited: _isUnlimitedPhotoGallery,
            onToggleUnlimited: (val) => _isUnlimitedPhotoGallery = val,
            controller: _photoGalleryController,
            hintText: '10',
            roleAccentColor: roleAccentColor,
          ),

          // 5. Nearby or Radius Search limit
          _buildFacilityControlItem(
            icon: Icons.radar_rounded,
            iconColor: const Color(0xFFEA580C),
            titleBn: '৫. কাছাকাছি (রেডিয়াস) সার্চ লিমিট',
            titleEn: '5. Nearby / Radius Search Limit',
            descBn: 'মানচিত্র ও জিপিএস দিয়ে আশেপাশের বাসা খোঁজার লিমিট',
            descEn: 'Radius search based on GPS & nearby landmarks',
            isEnabled: _enableNearbySearch,
            onToggleEnabled: (val) => _enableNearbySearch = val,
            isUnlimited: _isUnlimitedNearby,
            onToggleUnlimited: (val) => _isUnlimitedNearby = val,
            controller: _nearbySearchController,
            hintText: '10',
            roleAccentColor: roleAccentColor,
          ),

          // 6. Google Map Directions limit
          _buildFacilityControlItem(
            icon: Icons.directions_rounded,
            iconColor: const Color(0xFF0284C7),
            titleBn: '৬. গুগল ম্যাপস দিকনির্দেশনা (Directions) লিমিট',
            titleEn: '6. Google Map Directions Limit',
            descBn: 'গুগল ম্যাপে লাইভ রুট ও দিকনির্দেশনা ব্যবহারের লিমিট',
            descEn: 'Navigation and directions limit via Google Maps',
            isEnabled: _enableMapDirections,
            onToggleEnabled: (val) => _enableMapDirections = val,
            isUnlimited: _isUnlimitedDirections,
            onToggleUnlimited: (val) => _isUnlimitedDirections = val,
            controller: _mapDirectionsController,
            hintText: '10',
            roleAccentColor: roleAccentColor,
          ),

          // 7. AI Assistant Search limit
          _buildFacilityControlItem(
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFFD946EF),
            titleBn: '৭. এআই সহকারী (AI Assistant) সার্চ লিমিট',
            titleEn: '7. AI Assistant Search Limit',
            descBn: 'স্মার্ট এআই দিয়ে বাসা খোঁজার ও তথ্য পাওয়ার লিমিট',
            descEn: 'Smart AI-powered house hunting & matching searches',
            isEnabled: _enableAiAssistant,
            onToggleEnabled: (val) => _enableAiAssistant = val,
            isUnlimited: _isUnlimitedAi,
            onToggleUnlimited: (val) => _isUnlimitedAi = val,
            controller: _aiAssistantController,
            hintText: '50',
            roleAccentColor: roleAccentColor,
          ),
        ],
      );
    } else {
      // 4 House Owner Facilities
      return Column(
        children: [
          // 1. Max rental Listings allowed
          _buildFacilityControlItem(
            icon: Icons.home_work_rounded,
            iconColor: const Color(0xFFD97706),
            titleBn: '১. বাসাভাড়া বিজ্ঞাপন পোস্ট লিমিট',
            titleEn: '1. Max Rental Listings Allowed',
            descBn: 'বাড়িওয়ালা সর্বোচ্চ কতটি বাসাভাড়া বিজ্ঞাপন পোস্ট করতে পারবে',
            descEn: 'Maximum rental listings landlord can publish',
            isEnabled: _enableMaxPosts,
            onToggleEnabled: (val) => _enableMaxPosts = val,
            isUnlimited: _isUnlimitedPosts,
            onToggleUnlimited: (val) => _isUnlimitedPosts = val,
            controller: _maxPostsController,
            hintText: '10',
            roleAccentColor: roleAccentColor,
          ),

          // 2. Contact Numbers of tenant unlock limit
          _buildFacilityControlItem(
            icon: Icons.contact_phone_rounded,
            iconColor: const Color(0xFF2563EB),
            titleBn: '২. ভাড়াটিয়াদের নম্বর আনলক লিমিট',
            titleEn: '2. Tenant Contact Numbers Unlock Limit',
            descBn: 'চাহিদা প্রকাশকারী ভাড়াটিয়াদের সরাসরি ফোন নম্বর আনলক লিমিট',
            descEn: 'Direct unlock of tenant phone numbers from demands',
            isEnabled: _enableUnlockNumbers,
            onToggleEnabled: (val) => _enableUnlockNumbers = val,
            isUnlimited: _isUnlimitedUnlocks,
            onToggleUnlimited: (val) => _isUnlimitedUnlocks = val,
            controller: _unlockNumbersController,
            hintText: '10',
            roleAccentColor: roleAccentColor,
          ),

          // 3. Sub area unlock limit
          _buildFacilityControlItem(
            icon: Icons.map_rounded,
            iconColor: const Color(0xFF059669),
            titleBn: '৩. চাহিদার সাব-এরিয়া লোকেশন আনলক লিমিট',
            titleEn: '3. Demand Sub-Area Unlock Limit',
            descBn: 'ভাড়াটিয়াদের চাহিদার বিস্তারিত সাব-এরিয়া দেখার এক্সেস লিমিট',
            descEn: 'Access to tenant demand sub-area locations',
            isEnabled: _enableSubArea,
            onToggleEnabled: (val) => _enableSubArea = val,
            isUnlimited: _isUnlimitedSubArea,
            onToggleUnlimited: (val) => _isUnlimitedSubArea = val,
            controller: _subAreaController,
            hintText: '5',
            roleAccentColor: roleAccentColor,
          ),

          // 4. AI Assistant Search limit
          _buildFacilityControlItem(
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFFD946EF),
            titleBn: '৪. এআই সহকারী (AI Assistant) সার্চ লিমিট',
            titleEn: '4. AI Assistant Search Limit',
            descBn: 'উপযুক্ত ভাড়াটিয়া খোঁজা ও রেন্টাল পরামর্শের এআই লিমিট',
            descEn: 'Smart AI assistant search for finding prospective tenants',
            isEnabled: _enableAiAssistant,
            onToggleEnabled: (val) => _enableAiAssistant = val,
            isUnlimited: _isUnlimitedAi,
            onToggleUnlimited: (val) => _isUnlimitedAi = val,
            controller: _aiAssistantController,
            hintText: '50',
            roleAccentColor: roleAccentColor,
          ),
        ],
      );
    }
  }

  Widget _buildFacilityControlItem({
    required IconData icon,
    required Color iconColor,
    required String titleBn,
    required String titleEn,
    required String descBn,
    required String descEn,
    required bool isEnabled,
    required ValueChanged<bool> onToggleEnabled,
    required bool isUnlimited,
    required ValueChanged<bool> onToggleUnlimited,
    required TextEditingController controller,
    required String hintText,
    required Color roleAccentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF14201E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? roleAccentColor.withValues(alpha: 0.35)
              : (widget.isDark ? const Color(0xFF253734) : const Color(0xFFE2E8F0)),
          width: isEnabled ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Header with Icon, Bilingual Title & Clickable ON/OFF Switch
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? iconColor.withValues(alpha: 0.15)
                      : (widget.isDark ? Colors.grey[800] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? iconColor : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isBn ? titleBn : titleEn,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: isEnabled
                            ? (widget.isDark ? Colors.white : Colors.black87)
                            : (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isBn ? descBn : descEn,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Clickable ON / OFF Button / Switch
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch.adaptive(
                    value: isEnabled,
                    activeTrackColor: roleAccentColor,
                    activeThumbColor: Colors.white,
                    onChanged: (val) {
                      onToggleEnabled(val);
                      setState(() {});
                    },
                  ),
                  Text(
                    isEnabled
                        ? (widget.isBn ? 'সক্রিয় (ON)' : 'Active (ON)')
                        : (widget.isBn ? 'বন্ধ (OFF)' : 'Inactive (OFF)'),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? roleAccentColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Row 2: Limit Selector (Only visible if isEnabled == true)
          if (isEnabled) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: roleAccentColor.withValues(alpha: widget.isDark ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: roleAccentColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isBn ? 'সুবিধার মাত্রা নির্ধারণ করুন:' : 'Configure Limit Mode:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Choice 1: Set Number
                      ChoiceChip(
                        avatar: const Icon(Icons.pin_rounded, size: 15),
                        label: Text(widget.isBn ? 'নির্দিষ্ট সংখ্যা (Set Number)' : 'Set Number'),
                        selected: !isUnlimited,
                        selectedColor: roleAccentColor.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) {
                            onToggleUnlimited(false);
                            setState(() {});
                          }
                        },
                      ),
                      // Choice 2: Unlimited
                      ChoiceChip(
                        avatar: const Icon(Icons.all_inclusive_rounded, size: 15),
                        label: Text(widget.isBn ? 'আনলিমিটেড (Unlimited)' : 'Unlimited'),
                        selected: isUnlimited,
                        selectedColor: roleAccentColor.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) {
                            onToggleUnlimited(true);
                            setState(() {});
                          }
                        },
                      ),
                      // Numeric input field if !isUnlimited
                      if (!isUnlimited) ...[
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 130,
                          height: 38,
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: hintText,
                              suffixText: widget.isBn ? 'বার/টি' : 'Times',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.block_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.isBn
                        ? 'এই সুবিধাটি এই প্যাকেজে সম্পূর্ণ বন্ধ (Disabled). ইউজার এটি দেখতে বা ব্যবহার করতে পারবে না।'
                        : 'Disabled for this plan. Users will not have access to this facility.',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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

    // Auto-generate bilingual perks dynamically based on enabled facilities and limits
    final perksMap = SubscriptionPlanModel.generateBilingualPerks(
      targetRole: widget.targetRole,
      maxPostsLimit: _getFacilityVal(_enableMaxPosts, _isUnlimitedPosts, _maxPostsController, widget.targetRole == SubscriptionTargetRole.tenant ? 5 : 10),
      unlockNumbersLimit: _getFacilityVal(_enableUnlockNumbers, _isUnlimitedUnlocks, _unlockNumbersController, 10),
      subAreaUnlockLimit: _getFacilityVal(_enableSubArea, _isUnlimitedSubArea, _subAreaController, 5),
      fullPhotoGalleryLimit: widget.targetRole == SubscriptionTargetRole.tenant
          ? _getFacilityVal(_enablePhotoGallery, _isUnlimitedPhotoGallery, _photoGalleryController, 10)
          : 0,
      nearbySearchLimit: widget.targetRole == SubscriptionTargetRole.tenant
          ? _getFacilityVal(_enableNearbySearch, _isUnlimitedNearby, _nearbySearchController, 10)
          : 0,
      mapDirectionsLimit: widget.targetRole == SubscriptionTargetRole.tenant
          ? _getFacilityVal(_enableMapDirections, _isUnlimitedDirections, _mapDirectionsController, 10)
          : 0,
      aiAssistantLimit: _getFacilityVal(_enableAiAssistant, _isUnlimitedAi, _aiAssistantController, 50),
    );

    final perks = _previewInEnglish ? (perksMap['en'] ?? []) : (perksMap['bn'] ?? []);

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
                    Expanded(
                      child: Column(
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
                  _previewInEnglish ? 'Included Plan Perks (Auto-generated):' : 'প্যাকেজ অ্যাক্টিভ করলে যা যা পাবেন (অটো-জেনারেটেড):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: roleAccentColor),
                ),
                const SizedBox(height: 8),

                if (perks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      widget.isBn ? 'কোনো সুবিধা সক্রিয় করা হয়নি' : 'No facilities enabled yet',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                else
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

    // Calculate structured limits: 0 = disabled, -1 = unlimited, >0 = count
    final int maxPosts = _getFacilityVal(_enableMaxPosts, _isUnlimitedPosts, _maxPostsController, widget.targetRole == SubscriptionTargetRole.tenant ? 5 : 10);
    final int unlockNumbers = _getFacilityVal(_enableUnlockNumbers, _isUnlimitedUnlocks, _unlockNumbersController, 10);
    final int subAreaUnlocks = _getFacilityVal(_enableSubArea, _isUnlimitedSubArea, _subAreaController, 5);
    final int photoGallery = widget.targetRole == SubscriptionTargetRole.tenant
        ? _getFacilityVal(_enablePhotoGallery, _isUnlimitedPhotoGallery, _photoGalleryController, 10)
        : 0;
    final int nearbySearches = widget.targetRole == SubscriptionTargetRole.tenant
        ? _getFacilityVal(_enableNearbySearch, _isUnlimitedNearby, _nearbySearchController, 10)
        : 0;
    final int mapDirections = widget.targetRole == SubscriptionTargetRole.tenant
        ? _getFacilityVal(_enableMapDirections, _isUnlimitedDirections, _mapDirectionsController, 10)
        : 0;
    final int aiQueries = _getFacilityVal(_enableAiAssistant, _isUnlimitedAi, _aiAssistantController, 50);

    // Auto-generate bilingual perks
    final perksMap = SubscriptionPlanModel.generateBilingualPerks(
      targetRole: widget.targetRole,
      maxPostsLimit: maxPosts,
      unlockNumbersLimit: unlockNumbers,
      subAreaUnlockLimit: subAreaUnlocks,
      fullPhotoGalleryLimit: photoGallery,
      nearbySearchLimit: nearbySearches,
      mapDirectionsLimit: mapDirections,
      aiAssistantLimit: aiQueries,
    );

    final perksBn = perksMap['bn'] ?? [];
    final perksEn = perksMap['en'] ?? [];

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
      maxPostsLimit: maxPosts,
      unlockNumbersLimit: unlockNumbers,
      subAreaUnlockLimit: subAreaUnlocks,
      fullPhotoGalleryLimit: photoGallery,
      canAccessAdditionalPhotos: photoGallery != 0,
      nearbySearchLimit: nearbySearches,
      mapDirectionsLimit: mapDirections,
      aiAssistantLimit: aiQueries,
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

/// =========================================================================
/// 🛡️ ADMIN FREE TIER POLICY TAB (TAB 4)
/// =========================================================================
class _AdminFreeTierPolicyTab extends StatefulWidget {
  final bool isBn;
  final bool isDark;

  const _AdminFreeTierPolicyTab({
    required this.isBn,
    required this.isDark,
  });

  @override
  State<_AdminFreeTierPolicyTab> createState() => _AdminFreeTierPolicyTabState();
}

class _AdminFreeTierPolicyTabState extends State<_AdminFreeTierPolicyTab> {
  bool _isInitialized = false;
  bool _isSavingTenant = false;
  bool _isSavingOwner = false;
  late final Stream<FreeTierPolicyModel> _policyStream;

  @override
  void initState() {
    super.initState();
    _policyStream = SubscriptionFirestoreService().streamFreeTierPolicy();
  }

  // Tenant Free Quotas (7 Facilities)
  bool _tMaxDemandsEnabled = true;
  bool _tMaxDemandsUnlimited = false;
  final _tMaxDemandsCtrl = TextEditingController(text: '1');

  bool _tUnlockNumbersEnabled = true;
  bool _tUnlockNumbersUnlimited = false;
  final _tUnlockNumbersCtrl = TextEditingController(text: '5');

  bool _tSubAreaEnabled = false;
  bool _tSubAreaUnlimited = false;
  final _tSubAreaCtrl = TextEditingController(text: '0');

  bool _tPhotoGalleryEnabled = false;
  bool _tPhotoGalleryUnlimited = false;
  final _tPhotoGalleryCtrl = TextEditingController(text: '0');

  bool _tNearbyEnabled = true;
  bool _tNearbyUnlimited = false;
  final _tNearbyCtrl = TextEditingController(text: '3');

  bool _tMapDirectionsEnabled = true;
  bool _tMapDirectionsUnlimited = false;
  final _tMapDirectionsCtrl = TextEditingController(text: '2');

  bool _tAiAssistantEnabled = true;
  bool _tAiAssistantUnlimited = false;
  final _tAiAssistantCtrl = TextEditingController(text: '2');

  // House Owner Free Quotas (4 Facilities)
  bool _oMaxListingsEnabled = true;
  bool _oMaxListingsUnlimited = false;
  final _oMaxListingsCtrl = TextEditingController(text: '1');

  bool _oUnlockNumbersEnabled = true;
  bool _oUnlockNumbersUnlimited = false;
  final _oUnlockNumbersCtrl = TextEditingController(text: '2');

  bool _oSubAreaEnabled = false;
  bool _oSubAreaUnlimited = false;
  final _oSubAreaCtrl = TextEditingController(text: '0');

  bool _oAiAssistantEnabled = true;
  bool _oAiAssistantUnlimited = false;
  final _oAiAssistantCtrl = TextEditingController(text: '2');

  @override
  void dispose() {
    _tMaxDemandsCtrl.dispose();
    _tUnlockNumbersCtrl.dispose();
    _tSubAreaCtrl.dispose();
    _tPhotoGalleryCtrl.dispose();
    _tNearbyCtrl.dispose();
    _tMapDirectionsCtrl.dispose();
    _tAiAssistantCtrl.dispose();
    _oMaxListingsCtrl.dispose();
    _oUnlockNumbersCtrl.dispose();
    _oSubAreaCtrl.dispose();
    _oAiAssistantCtrl.dispose();
    super.dispose();
  }

  void _initFromPolicy(FreeTierPolicyModel p) {
    // Tenant
    _tMaxDemandsEnabled = p.tenantMaxDemands != 0;
    _tMaxDemandsUnlimited = p.tenantMaxDemands == -1;
    _tMaxDemandsCtrl.text = (_tMaxDemandsUnlimited || !_tMaxDemandsEnabled) ? '1' : p.tenantMaxDemands.toString();

    _tUnlockNumbersEnabled = p.tenantUnlockNumbers != 0;
    _tUnlockNumbersUnlimited = p.tenantUnlockNumbers == -1;
    _tUnlockNumbersCtrl.text = (_tUnlockNumbersUnlimited || !_tUnlockNumbersEnabled) ? '5' : p.tenantUnlockNumbers.toString();

    _tSubAreaEnabled = p.tenantSubAreaUnlocks != 0;
    _tSubAreaUnlimited = p.tenantSubAreaUnlocks == -1;
    _tSubAreaCtrl.text = (_tSubAreaUnlimited || !_tSubAreaEnabled) ? '2' : p.tenantSubAreaUnlocks.toString();

    _tPhotoGalleryEnabled = p.tenantFullPhotoGallery != 0;
    _tPhotoGalleryUnlimited = p.tenantFullPhotoGallery == -1;
    _tPhotoGalleryCtrl.text = (_tPhotoGalleryUnlimited || !_tPhotoGalleryEnabled) ? '2' : p.tenantFullPhotoGallery.toString();

    _tNearbyEnabled = p.tenantNearbySearches != 0;
    _tNearbyUnlimited = p.tenantNearbySearches == -1;
    _tNearbyCtrl.text = (_tNearbyUnlimited || !_tNearbyEnabled) ? '3' : p.tenantNearbySearches.toString();

    _tMapDirectionsEnabled = p.tenantMapDirections != 0;
    _tMapDirectionsUnlimited = p.tenantMapDirections == -1;
    _tMapDirectionsCtrl.text = (_tMapDirectionsUnlimited || !_tMapDirectionsEnabled) ? '2' : p.tenantMapDirections.toString();

    _tAiAssistantEnabled = p.tenantAiAssistant != 0;
    _tAiAssistantUnlimited = p.tenantAiAssistant == -1;
    _tAiAssistantCtrl.text = (_tAiAssistantUnlimited || !_tAiAssistantEnabled) ? '2' : p.tenantAiAssistant.toString();

    // Owner
    _oMaxListingsEnabled = p.ownerMaxListings != 0;
    _oMaxListingsUnlimited = p.ownerMaxListings == -1;
    _oMaxListingsCtrl.text = (_oMaxListingsUnlimited || !_oMaxListingsEnabled) ? '1' : p.ownerMaxListings.toString();

    _oUnlockNumbersEnabled = p.ownerUnlockNumbers != 0;
    _oUnlockNumbersUnlimited = p.ownerUnlockNumbers == -1;
    _oUnlockNumbersCtrl.text = (_oUnlockNumbersUnlimited || !_oUnlockNumbersEnabled) ? '2' : p.ownerUnlockNumbers.toString();

    _oSubAreaEnabled = p.ownerSubAreaUnlocks != 0;
    _oSubAreaUnlimited = p.ownerSubAreaUnlocks == -1;
    _oSubAreaCtrl.text = (_oSubAreaUnlimited || !_oSubAreaEnabled) ? '2' : p.ownerSubAreaUnlocks.toString();

    _oAiAssistantEnabled = p.ownerAiAssistant != 0;
    _oAiAssistantUnlimited = p.ownerAiAssistant == -1;
    _oAiAssistantCtrl.text = (_oAiAssistantUnlimited || !_oAiAssistantEnabled) ? '2' : p.ownerAiAssistant.toString();

    _isInitialized = true;
  }

  int _getFacilityVal(bool enabled, bool isUnlimited, TextEditingController ctrl, int defaultVal) {
    if (!enabled) return 0;
    if (isUnlimited) return -1;
    final parsed = int.tryParse(ctrl.text.trim().toEnglishDigits());
    return (parsed != null && parsed > 0) ? parsed : defaultVal;
  }

  Future<void> _saveTenantPolicy() async {
    setState(() => _isSavingTenant = true);
    final tenantData = {
      'tenantMaxDemands': _getFacilityVal(_tMaxDemandsEnabled, _tMaxDemandsUnlimited, _tMaxDemandsCtrl, 1),
      'tenantUnlockNumbers': _getFacilityVal(_tUnlockNumbersEnabled, _tUnlockNumbersUnlimited, _tUnlockNumbersCtrl, 5),
      'tenantSubAreaUnlocks': _getFacilityVal(_tSubAreaEnabled, _tSubAreaUnlimited, _tSubAreaCtrl, 0),
      'tenantFullPhotoGallery': _getFacilityVal(_tPhotoGalleryEnabled, _tPhotoGalleryUnlimited, _tPhotoGalleryCtrl, 0),
      'tenantNearbySearches': _getFacilityVal(_tNearbyEnabled, _tNearbyUnlimited, _tNearbyCtrl, 3),
      'tenantMapDirections': _getFacilityVal(_tMapDirectionsEnabled, _tMapDirectionsUnlimited, _tMapDirectionsCtrl, 2),
      'tenantAiAssistant': _getFacilityVal(_tAiAssistantEnabled, _tAiAssistantUnlimited, _tAiAssistantCtrl, 2),
    };

    try {
      await context.read<SubscriptionProvider>().saveTenantFreeTierPolicy(tenantData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isBn
                  ? 'ভাড়াটিয়া ফ্রি পলিসি সফলভাবে সংরক্ষিত ও কার্যকর হয়েছে!'
                  : 'Tenant free tier policy saved and updated successfully!',
            ),
            backgroundColor: const Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving tenant policy: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingTenant = false);
    }
  }

  Future<void> _saveOwnerPolicy() async {
    setState(() => _isSavingOwner = true);
    final ownerData = {
      'ownerMaxListings': _getFacilityVal(_oMaxListingsEnabled, _oMaxListingsUnlimited, _oMaxListingsCtrl, 1),
      'ownerUnlockNumbers': _getFacilityVal(_oUnlockNumbersEnabled, _oUnlockNumbersUnlimited, _oUnlockNumbersCtrl, 2),
      'ownerSubAreaUnlocks': _getFacilityVal(_oSubAreaEnabled, _oSubAreaUnlimited, _oSubAreaCtrl, 0),
      'ownerAiAssistant': _getFacilityVal(_oAiAssistantEnabled, _oAiAssistantUnlimited, _oAiAssistantCtrl, 2),
    };

    try {
      await context.read<SubscriptionProvider>().saveOwnerFreeTierPolicy(ownerData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isBn
                  ? 'বাড়িওয়ালা ফ্রি পলিসি সফলভাবে সংরক্ষিত ও কার্যকর হয়েছে!'
                  : 'House owner free tier policy saved and updated successfully!',
            ),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving owner policy: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingOwner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FreeTierPolicyModel>(
      stream: _policyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.themeColor)),
          );
        }

        if (snapshot.hasData && !_isInitialized) {
          _initFromPolicy(snapshot.data!);
        } else if (!_isInitialized) {
          _initFromPolicy(FreeTierPolicyModel.defaultPolicy());
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF6366F1), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isBn
                                ? 'ফ্রি অ্যাকাউন্ট পলিসি ও ডিফল্ট কোটা নিয়ন্ত্রণ'
                                : 'Free Tier Policy & Baseline Quotas',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isBn
                                ? 'কোনো পেইড সাবস্ক্রিপশন প্ল্যান গ্রহণ না করলেও ব্যবহারকারীরা ফ্রিতে যেসকল সুবিধা কতবার ব্যবহার করতে পারবেন তা এখান থেকে নিয়ন্ত্রণ করুন।'
                                : 'Configure the default free usage limits and feature toggles for users without an active subscription.',
                            style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: Text(widget.isBn ? 'ডিফল্ট রিসেট' : 'Reset Defaults'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                      ),
                      onPressed: () {
                        setState(() {
                          _initFromPolicy(FreeTierPolicyModel.defaultPolicy());
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 1: Tenant Free Policy (7 Facilities)
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isBn
                        ? 'ভাড়াটিয়া ফ্রি অ্যাকাউন্ট পলিসি (Tenant Free Facilities - 7 Features)'
                        : 'Tenant Free Account Policy (7 Features)',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0D9488)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildPolicyItem(
                icon: Icons.post_add_rounded,
                iconColor: const Color(0xFF0D9488),
                titleBn: '১. ভাড়ার চাহিদা (Demand) পোস্ট লিমিট',
                titleEn: '1. Max Rental Demand Allowed',
                descBn: 'ফ্রি ভাড়াটিয়া সর্বোচ্চ কতটি বাসা খোঁজার চাহিদা পোস্ট করতে পারবে',
                descEn: 'Maximum rental demands allowed for free tenants',
                isEnabled: _tMaxDemandsEnabled,
                onToggleEnabled: (v) => setState(() => _tMaxDemandsEnabled = v),
                isUnlimited: _tMaxDemandsUnlimited,
                onToggleUnlimited: (v) => setState(() => _tMaxDemandsUnlimited = v),
                controller: _tMaxDemandsCtrl,
                hintText: '1',
                accentColor: const Color(0xFF0D9488),
              ),

              _buildPolicyItem(
                icon: Icons.phone_in_talk_rounded,
                iconColor: const Color(0xFF2563EB),
                titleBn: '২. বাড়িওয়ালার কন্টাক্ট নম্বর আনলক লিমিট',
                titleEn: '2. Landlord Contact Numbers Unlock Limit',
                descBn: 'ফ্রি ভাড়াটিয়া সর্বোচ্চ কতজন বাড়িওয়ালার সরাসরি ফোন নম্বর দেখতে পারবে',
                descEn: 'Maximum landlord contacts free tenants can unlock',
                isEnabled: _tUnlockNumbersEnabled,
                onToggleEnabled: (v) => setState(() => _tUnlockNumbersEnabled = v),
                isUnlimited: _tUnlockNumbersUnlimited,
                onToggleUnlimited: (v) => setState(() => _tUnlockNumbersUnlimited = v),
                controller: _tUnlockNumbersCtrl,
                hintText: '5',
                accentColor: const Color(0xFF0D9488),
              ),

              _buildPolicyItem(
                icon: Icons.location_city_rounded,
                iconColor: const Color(0xFF059669),
                titleBn: '৩. সাব-এরিয়া লোকেশন আনলক লিমিট',
                titleEn: '3. Sub-Area Location Unlock Limit',
                descBn: 'বাসার বিস্তারিত সাব-এরিয়া বা পাড়া দেখার ফ্রি এক্সেস লিমিট',
                descEn: 'Access to detailed sub-area addresses for free tenants',
                isEnabled: _tSubAreaEnabled,
                onToggleEnabled: (v) => setState(() => _tSubAreaEnabled = v),
                isUnlimited: _tSubAreaUnlimited,
                onToggleUnlimited: (v) => setState(() => _tSubAreaUnlimited = v),
                controller: _tSubAreaCtrl,
                hintText: '0',
                accentColor: const Color(0xFF0D9488),
              ),

              _buildPolicyItem(
                icon: Icons.photo_library_rounded,
                iconColor: const Color(0xFF9333EA),
                titleBn: '৪. সকল অতিরিক্ত ছবি ও ফুল গ্যালারি এক্সেস লিমিট',
                titleEn: '4. Full Photo Gallery Access Limit',
                descBn: 'বাসার সকল রুম ও ওয়াশরুমের অতিরিক্ত ছবি দেখার ফ্রি লিমিট',
                descEn: 'Free access to full photo galleries of properties',
                isEnabled: _tPhotoGalleryEnabled,
                onToggleEnabled: (v) => setState(() => _tPhotoGalleryEnabled = v),
                isUnlimited: _tPhotoGalleryUnlimited,
                onToggleUnlimited: (v) => setState(() => _tPhotoGalleryUnlimited = v),
                controller: _tPhotoGalleryCtrl,
                hintText: '0',
                accentColor: const Color(0xFF0D9488),
              ),

              _buildPolicyItem(
                icon: Icons.radar_rounded,
                iconColor: const Color(0xFFEA580C),
                titleBn: '৫. কাছাকাছি (রেডিয়াস) সার্চ লিমিট',
                titleEn: '5. Nearby / Radius Search Limit',
                descBn: 'ম্যাপে জিপিএস দিয়ে আশেপাশের বাসা খোঁজার ফ্রি লিমিট',
                descEn: 'Free radius searches based on GPS location',
                isEnabled: _tNearbyEnabled,
                onToggleEnabled: (v) => setState(() => _tNearbyEnabled = v),
                isUnlimited: _tNearbyUnlimited,
                onToggleUnlimited: (v) => setState(() => _tNearbyUnlimited = v),
                controller: _tNearbyCtrl,
                hintText: '3',
                accentColor: const Color(0xFF0D9488),
              ),

              _buildPolicyItem(
                icon: Icons.directions_rounded,
                iconColor: const Color(0xFF0284C7),
                titleBn: '৬. গুগল ম্যাপস দিকনির্দেশনা (Directions) লিমিট',
                titleEn: '6. Google Map Directions Limit',
                descBn: 'গুগল ম্যাপে লাইভ রুট ও ডিরেকশন ব্যবহারের ফ্রি লিমিট',
                descEn: 'Free Google Maps directions and navigation access',
                isEnabled: _tMapDirectionsEnabled,
                onToggleEnabled: (v) => setState(() => _tMapDirectionsEnabled = v),
                isUnlimited: _tMapDirectionsUnlimited,
                onToggleUnlimited: (v) => setState(() => _tMapDirectionsUnlimited = v),
                controller: _tMapDirectionsCtrl,
                hintText: '2',
                accentColor: const Color(0xFF0D9488),
              ),

              _buildPolicyItem(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFFD946EF),
                titleBn: '৭. এআই সহকারী (AI Assistant) সার্চ লিমিট',
                titleEn: '7. AI Assistant Search Limit',
                descBn: 'স্মার্ট এআই দিয়ে বাসা খোঁজার ও তথ্য পাওয়ার ফ্রি লিমিট',
                descEn: 'Free AI assistant searches for rental queries',
                isEnabled: _tAiAssistantEnabled,
                onToggleEnabled: (v) => setState(() => _tAiAssistantEnabled = v),
                isUnlimited: _tAiAssistantUnlimited,
                onToggleUnlimited: (v) => setState(() => _tAiAssistantUnlimited = v),
                controller: _tAiAssistantCtrl,
                hintText: '2',
                accentColor: const Color(0xFF0D9488),
              ),

              // Tenant Policy Dedicated Save Action Bar
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF132A26) : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 650;
                    return Flex(
                      direction: isCompact ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: isCompact ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: isCompact ? 0 : 1,
                          child: Row(
                            children: [
                              const Icon(Icons.person_pin_rounded, color: Color(0xFF0D9488), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isBn ? 'ভাড়াটিয়া ফ্রি পলিসি সংরক্ষণ' : 'Save Tenant Free Policy',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    Text(
                                      widget.isBn
                                          ? 'উপরের ৭টি ফ্রি সুবিধার পরিবর্তন ভাড়াটিয়া অ্যাকাউন্টে অবিলম্বে কার্যকর হবে।'
                                          : 'Saves and updates the 7 tenant free tier baseline facilities immediately.',
                                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCompact) const SizedBox(height: 12) else const SizedBox(width: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isSavingTenant
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: Text(
                            widget.isBn ? 'ভাড়াটিয়া ফ্রি পলিসি সংরক্ষণ করুন' : 'Save Tenant Free Policy',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _isSavingTenant ? null : _saveTenantPolicy,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Section 2: House Owner Free Policy (4 Facilities)
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isBn
                        ? 'বাড়িওয়ালা ফ্রি অ্যাকাউন্ট পলিসি (House Owner Free Facilities - 4 Features)'
                        : 'House Owner Free Account Policy (4 Features)',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFFF59E0B)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildPolicyItem(
                icon: Icons.home_work_rounded,
                iconColor: const Color(0xFFD97706),
                titleBn: '১. বাসাভাড়া বিজ্ঞাপন পোস্ট লিমিট',
                titleEn: '1. Max Rental Listings Allowed',
                descBn: 'ফ্রি বাড়িওয়ালা সর্বোচ্চ কতটি বাসাভাড়া বিজ্ঞাপন পোস্ট করতে পারবে',
                descEn: 'Maximum rental listings allowed for free landlords',
                isEnabled: _oMaxListingsEnabled,
                onToggleEnabled: (v) => setState(() => _oMaxListingsEnabled = v),
                isUnlimited: _oMaxListingsUnlimited,
                onToggleUnlimited: (v) => setState(() => _oMaxListingsUnlimited = v),
                controller: _oMaxListingsCtrl,
                hintText: '1',
                accentColor: const Color(0xFFF59E0B),
              ),

              _buildPolicyItem(
                icon: Icons.contact_phone_rounded,
                iconColor: const Color(0xFF2563EB),
                titleBn: '২. ভাড়াটিয়াদের নম্বর আনলক লিমিট',
                titleEn: '2. Tenant Contact Numbers Unlock Limit',
                descBn: 'চাহিদা প্রকাশকারী ভাড়াটিয়াদের সরাসরি ফোন নম্বর আনলক করার ফ্রি লিমিট',
                descEn: 'Direct unlock of prospective tenant contacts for free landlords',
                isEnabled: _oUnlockNumbersEnabled,
                onToggleEnabled: (v) => setState(() => _oUnlockNumbersEnabled = v),
                isUnlimited: _oUnlockNumbersUnlimited,
                onToggleUnlimited: (v) => setState(() => _oUnlockNumbersUnlimited = v),
                controller: _oUnlockNumbersCtrl,
                hintText: '2',
                accentColor: const Color(0xFFF59E0B),
              ),

              _buildPolicyItem(
                icon: Icons.map_rounded,
                iconColor: const Color(0xFF059669),
                titleBn: '৩. চাহিদার সাব-এরিয়া লোকেশন আনলক লিমিট',
                titleEn: '3. Demand Sub-Area Unlock Limit',
                descBn: 'ভাড়াটিয়াদের চাহিদার বিস্তারিত সাব-এরিয়া লোকেশন দেখার ফ্রি লিমিট',
                descEn: 'Access to tenant demand sub-areas for free landlords',
                isEnabled: _oSubAreaEnabled,
                onToggleEnabled: (v) => setState(() => _oSubAreaEnabled = v),
                isUnlimited: _oSubAreaUnlimited,
                onToggleUnlimited: (v) => setState(() => _oSubAreaUnlimited = v),
                controller: _oSubAreaCtrl,
                hintText: '0',
                accentColor: const Color(0xFFF59E0B),
              ),

              _buildPolicyItem(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFFD946EF),
                titleBn: '৪. এআই সহকারী (AI Assistant) সার্চ লিমিট',
                titleEn: '4. AI Assistant Search Limit',
                descBn: 'উপযুক্ত ভাড়াটিয়া খোঁজা ও রেন্টাল পরামর্শের ফ্রি এআই লিমিট',
                descEn: 'Free AI assistant searches for finding prospective tenants',
                isEnabled: _oAiAssistantEnabled,
                onToggleEnabled: (v) => setState(() => _oAiAssistantEnabled = v),
                isUnlimited: _oAiAssistantUnlimited,
                onToggleUnlimited: (v) => setState(() => _oAiAssistantUnlimited = v),
                controller: _oAiAssistantCtrl,
                hintText: '2',
                accentColor: const Color(0xFFF59E0B),
              ),

              // House Owner Policy Dedicated Save Action Bar
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF2C2210) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 650;
                    return Flex(
                      direction: isCompact ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: isCompact ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: isCompact ? 0 : 1,
                          child: Row(
                            children: [
                              const Icon(Icons.home_work_rounded, color: Color(0xFFF59E0B), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isBn ? 'বাড়িওয়ালা ফ্রি পলিসি সংরক্ষণ' : 'Save House Owner Free Policy',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    Text(
                                      widget.isBn
                                          ? 'উপরের ৪টি ফ্রি সুবিধার পরিবর্তন বাড়িওয়ালা অ্যাকাউন্টে অবিলম্বে কার্যকর হবে।'
                                          : 'Saves and updates the 4 house owner free tier baseline facilities immediately.',
                                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCompact) const SizedBox(height: 12) else const SizedBox(width: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isSavingOwner
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: Text(
                            widget.isBn ? 'বাড়িওয়ালা ফ্রি পলিসি সংরক্ষণ করুন' : 'Save House Owner Free Policy',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _isSavingOwner ? null : _saveOwnerPolicy,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPolicyItem({
    required IconData icon,
    required Color iconColor,
    required String titleBn,
    required String titleEn,
    required String descBn,
    required String descEn,
    required bool isEnabled,
    required ValueChanged<bool> onToggleEnabled,
    required bool isUnlimited,
    required ValueChanged<bool> onToggleUnlimited,
    required TextEditingController controller,
    required String hintText,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF14201E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? accentColor.withValues(alpha: 0.3)
              : (widget.isDark ? const Color(0xFF253734) : const Color(0xFFE2E8F0)),
          width: isEnabled ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isEnabled ? iconColor.withValues(alpha: 0.15) : (widget.isDark ? Colors.grey[800] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isEnabled ? iconColor : Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isBn ? titleBn : titleEn,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isEnabled
                            ? (widget.isDark ? Colors.white : Colors.black87)
                            : (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isBn ? descBn : descEn,
                      style: TextStyle(fontSize: 11.5, color: widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch.adaptive(
                    value: isEnabled,
                    activeTrackColor: accentColor,
                    activeThumbColor: Colors.white,
                    onChanged: onToggleEnabled,
                  ),
                  Text(
                    isEnabled ? (widget.isBn ? 'সক্রিয় (ON)' : 'ON') : (widget.isBn ? 'বন্ধ (OFF)' : 'OFF'),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? accentColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (isEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: widget.isDark ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.pin_rounded, size: 15),
                    label: Text(widget.isBn ? 'নির্দিষ্ট সংখ্যা' : 'Set Limit'),
                    selected: !isUnlimited,
                    selectedColor: accentColor.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      if (selected) onToggleUnlimited(false);
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.all_inclusive_rounded, size: 15),
                    label: Text(widget.isBn ? 'আনলিমিটেড' : 'Unlimited'),
                    selected: isUnlimited,
                    selectedColor: accentColor.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      if (selected) onToggleUnlimited(true);
                    },
                  ),
                  if (!isUnlimited) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 120,
                      height: 38,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: hintText,
                          suffixText: widget.isBn ? 'বার/টি' : 'Times',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              widget.isBn
                  ? '⛔ ফ্রি অ্যাকাউন্টে এই সুবিধাটি বন্ধ (ইউজার দেখতে বা ব্যবহার করতে পারবে না)'
                  : 'Disabled for free users (Cannot view or access)',
              style: TextStyle(fontSize: 11, color: widget.isDark ? Colors.grey[500] : Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
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
