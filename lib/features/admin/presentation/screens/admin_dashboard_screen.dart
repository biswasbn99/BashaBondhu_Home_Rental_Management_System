import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../home/data/models/property_model.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';
import '../../../shared/data/services/tenant_demand_firestore_service.dart';
import '../../../subscription/data/models/subscription_model.dart';
import '../../../subscription/data/services/subscription_firestore_service.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedActivityTab = 0; // 0: All, 1: House Owner, 2: Tenant

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;
    final adminService = AdminFirestoreService();
    final demandService = TenantDemandFirestoreService();
    final subscriptionService = SubscriptionFirestoreService();

    return StreamBuilder<List<UserModel>>(
      stream: adminService.streamAllUsers(),
      builder: (context, userSnapshot) {
        final users = userSnapshot.data ?? [];

        return StreamBuilder<List<PropertyModel>>(
          stream: adminService.streamAllProperties(),
          builder: (context, propSnapshot) {
            final properties = propSnapshot.data ?? [];

            return StreamBuilder<List<TenantDemandModel>>(
              stream: demandService.streamAllDemands(onlyActive: false),
              builder: (context, demandSnapshot) {
                final demands = demandSnapshot.data ?? [];

                return StreamBuilder<List<SubscriptionTransactionModel>>(
                  stream: subscriptionService.streamAllTransactions(),
                  builder: (context, transSnapshot) {
                    final transactions = transSnapshot.data ?? [];

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: adminService.streamReports(),
                      builder: (context, reportSnapshot) {
                        final reports = reportSnapshot.data ?? [];

                        // Real-time Metrics Calculation
                        final int totalUsers = users.length;
                        final int totalOwners = users.where((u) => u.userType == 'House Owner').length;
                        final int totalTenants = users.where((u) => u.userType == 'Tenant').length;
                        final int totalVerified = users.where((u) => u.nidFrontImageUrl.isNotEmpty).length;

                        final int totalProperties = properties.length;
                        final int pendingProperties = properties.where((p) => !p.isAvailable || p.month == 'Pending').length;
                        final int approvedProperties = properties.where((p) => p.isAvailable).length;

                        final int totalDemands = demands.length;
                        final int totalTransactions = transactions.length;
                        final double totalRevenue = transactions.fold(0.0, (sum, t) => sum + t.amountPaid);
                        final int totalReports = reports.length;

                        // Pending Verification Users
                        final pendingUsers = users.where((u) => u.nidFrontImageUrl.isNotEmpty).take(5).toList();
                        // Recent Properties (House Owner Activity)
                        final recentProperties = properties.take(5).toList();
                        // Recent Demands (Tenant Activity)
                        final recentDemands = demands.take(5).toList();
                        // Recent Transactions
                        final recentTransactions = transactions.take(5).toList();

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Executive Hero Welcome Banner (NO Language Button inside)
                              _buildHeroBanner(
                                context: context,
                                isBn: isBn,
                                isDark: isDark,
                                adminName: adminProvider.adminName ?? 'Super Admin',
                                totalProperties: totalProperties,
                                totalDemands: totalDemands,
                                pendingProperties: pendingProperties,
                              ),
                              const SizedBox(height: 22),

                              // 2. Comprehensive Real-time KPI Metric Cards (4 Cards Side by Side on Web)
                              _buildSectionHeader(
                                icon: Icons.insights_rounded,
                                title: isBn ? 'সিস্টেম অ্যানালিটিক্স ও রিয়েল-টাইম পরিসংখ্যান' : 'Platform Analytics & Live Metrics',
                                subtitle: isBn
                                    ? 'সম্পূর্ণ অ্যাপের বাড়িওয়ালা ও ভাড়াটিয়াদের লাইভ পারফরম্যান্স মেট্রিক্স'
                                    : 'Real-time overview of House Owners, Tenants, Listings, Demands & Revenue',
                                color: AppColors.themeColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  // 4 cards side by side on desktop and web screens
                                  final int crossAxisCount = constraints.maxWidth > 700
                                      ? 4
                                      : (constraints.maxWidth > 460 ? 2 : 1);
                                  final double aspectRatio = constraints.maxWidth > 700
                                      ? 2.45
                                      : (constraints.maxWidth > 460 ? 2.5 : 3.5);

                                  return GridView.count(
                                    crossAxisCount: crossAxisCount,
                                    shrinkWrap: true,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: aspectRatio,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [
                                      // Card 1: Total Users
                                      _StatCard(
                                        title: isBn ? 'মোট ইউজার' : 'Total Users',
                                        value: totalUsers.toString(),
                                        icon: Icons.people_alt_rounded,
                                        badgeText: isBn ? 'নিবন্ধিত' : 'Registered',
                                        color: AppColors.themeColor,
                                        isDark: isDark,
                                      ),
                                      // Card 2: Total House Owners
                                      _StatCard(
                                        title: isBn ? 'মোট বাড়িওয়ালা' : 'House Owners',
                                        value: totalOwners.toString(),
                                        icon: Icons.home_work_rounded,
                                        badgeText: isBn ? 'হোস্ট' : 'Owners',
                                        color: const Color(0xFF00897B),
                                        isDark: isDark,
                                      ),
                                      // Card 3: Total Tenants
                                      _StatCard(
                                        title: isBn ? 'মোট ভাড়াটিয়া' : 'Total Tenants',
                                        value: totalTenants.toString(),
                                        icon: Icons.person_pin_circle_rounded,
                                        badgeText: isBn ? 'ভাড়াটিয়া' : 'Tenants',
                                        color: const Color(0xFF0284C7),
                                        isDark: isDark,
                                      ),
                                      // Card 4: Verified NID Users
                                      _StatCard(
                                        title: isBn ? 'ভেরিফাইড ইউজার' : 'Verified Users',
                                        value: totalVerified.toString(),
                                        icon: Icons.verified_user_rounded,
                                        badgeText: isBn ? 'এনআইডি' : 'Verified',
                                        color: const Color(0xFF10B981),
                                        isDark: isDark,
                                      ),
                                      // Card 5: House Owner Listings
                                      _StatCard(
                                        title: isBn ? 'বাড়িওয়ালার বাসাভাড়া' : 'Owner Listings',
                                        value: totalProperties.toString(),
                                        icon: Icons.apartment_rounded,
                                        badgeText: isBn ? '$approvedProperties টি লাইভ' : '$approvedProperties Live',
                                        color: const Color(0xFF00A896),
                                        isDark: isDark,
                                      ),
                                      // Card 6: Tenant Demand Posts
                                      _StatCard(
                                        title: isBn ? 'ভাড়াটিয়ার চাহিদা' : 'Tenant Demands',
                                        value: totalDemands.toString(),
                                        icon: Icons.assignment_rounded,
                                        badgeText: isBn ? 'চাহিদা' : 'Demands',
                                        color: const Color(0xFF0EA5E9),
                                        isDark: isDark,
                                      ),
                                      // Card 7: Subscriptions & Revenue
                                      _StatCard(
                                        title: isBn ? 'সাবস্ক্রিপশন আয়' : 'Total Revenue',
                                        value: '৳ ${totalRevenue.toStringAsFixed(0)}',
                                        icon: Icons.account_balance_wallet_rounded,
                                        badgeText: isBn ? '$totalTransactions টি' : '$totalTransactions Plans',
                                        color: const Color(0xFF6366F1),
                                        isDark: isDark,
                                      ),
                                      // Card 8: Reports & Complaints
                                      _StatCard(
                                        title: isBn ? 'অভিযোগ ও রিপোর্ট' : 'Reports & Issues',
                                        value: totalReports.toString(),
                                        icon: Icons.report_problem_rounded,
                                        badgeText: isBn ? 'রিপোর্ট' : 'Reports',
                                        color: const Color(0xFFEF4444),
                                        isDark: isDark,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // 3. Subscription Pro Banner
                              _buildSubscriptionBanner(context, adminProvider, isBn, isDark),
                              const SizedBox(height: 24),

                              // 4. Real-Time Tenant & House Owner Activity Filter Tabs (Web-Optimized)
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  _buildSectionHeader(
                                    icon: Icons.stream_rounded,
                                    title: isBn
                                        ? 'লাইভ অ্যাক্টিভিটি ফিড (Tenant & House Owner)'
                                        : 'Live Real-Time Activity Center',
                                    subtitle: isBn
                                        ? 'বাড়িওয়ালাদের বাসা বিজ্ঞাপন ও ভাড়াটিয়াদের চাহিদার রিয়েল-টাইম ফিড'
                                        : 'Real-time property posts, tenant demands, NID reviews, and transactions',
                                    color: AppColors.themeColor,
                                    isDark: isDark,
                                  ),
                                  // Tab Switcher Pill
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF101F1C) : const Color(0xFFE6F4F1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.themeColor.withValues(alpha: isDark ? 0.3 : 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildFilterTab(0, isBn ? 'সকল অ্যাক্টিভিটি' : 'All Activities', isDark),
                                        _buildFilterTab(1, isBn ? '🏡 বাড়িওয়ালা' : '🏡 House Owner', isDark),
                                        _buildFilterTab(2, isBn ? '👤 ভাড়াটিয়া' : '👤 Tenant', isDark),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 5. Activity Cards Grid based on Tab
                              _buildActivityGrid(
                                context: context,
                                isBn: isBn,
                                isDark: isDark,
                                adminService: adminService,
                                recentProperties: recentProperties,
                                recentDemands: recentDemands,
                                pendingUsers: pendingUsers,
                                recentTransactions: recentTransactions,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterTab(int index, String label, bool isDark) {
    final isSelected = _selectedActivityTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedActivityTab = index),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // --- 1. Executive Hero Welcome Banner (NO Language Button) ---
  Widget _buildHeroBanner({
    required BuildContext context,
    required bool isBn,
    required bool isDark,
    required String adminName,
    required int totalProperties,
    required int totalDemands,
    required int pendingProperties,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF071C18), const Color(0xFF0B2B25), const Color(0xFF0E3831)]
              : [const Color(0xFF006D62), const Color(0xFF00897B), const Color(0xFF00A896)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2DD4BF).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.themeColor.withValues(alpha: isDark ? 0.35 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 16,
        children: [
          // Left: Admin Greetings & Status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2DD4BF), Color(0xFF00A896)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBn ? 'স্বাগতম, $adminName 👋' : 'Welcome, $adminName 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          isBn ? 'সুপার অ্যাডমিন' : 'SUPER ADMIN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'বাসাবন্ধু রিয়েল-টাইম অ্যাডমিন কন্ট্রোল সেন্টার • সিস্টেম ডেটা সিঙ্ক সক্রিয়'
                        : 'BashaBondhu Real-time Administrator Hub • Live Cloud Sync Active',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: System Quick KPI Badges
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isBn ? 'ক্লাউড সিঙ্ক: লাইভ' : 'Firestore: Live',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Text(
                  isBn
                      ? '🏠 $totalProperties প্রপার্টি ($pendingProperties পেন্ডিং) | 📝 $totalDemands চাহিদা'
                      : '🏠 $totalProperties Posts ($pendingProperties Pending) | 📝 $totalDemands Demands',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Section Title Header (Bounded, Never throws flex error in Wrap or Row) ---
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withValues(alpha: isDark ? 0.4 : 0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 3. Responsive Subscription Management Banner ---
  Widget _buildSubscriptionBanner(BuildContext context, AdminProvider adminProvider, bool isBn, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => adminProvider.changeModule(AdminModule.subscriptions),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0E221E), const Color(0xFF14332D), const Color(0xFF091714)]
                  : [const Color(0xFFE8F6F4), const Color(0xFFF0FDF4), const Color(0xFFFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.themeColor.withValues(alpha: isDark ? 0.45 : 0.3),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.themeColor.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              final iconWidget = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2DD4BF), AppColors.themeColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.themeColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 26),
              );

              final contentColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isBn ? '💳 সাবস্ক্রিপশন ও প্যাকেজ ম্যানেজমেন্ট' : '💳 Subscription & Package Management',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isBn ? 'পেমেন্ট গেটওয়ে' : 'PRO GATEWAY',
                          style: const TextStyle(
                            color: AppColors.themeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'ভাড়াটিয়া ও বাড়িওয়ালাদের প্যাকেজ তৈরি, মূল্য পরিবর্তন, অফার কনফিগারেশন এবং SSLCOMMERZ পেমেন্ট কন্ট্রোল'
                        : 'Manage plans, pricing, promotional discounts, and configure SSLCOMMERZ payment gateway',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                ],
              );

              final actionButton = FilledButton.icon(
                onPressed: () => adminProvider.changeModule(AdminModule.subscriptions),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  isBn ? 'প্যাকেজ ওপেন করুন' : 'Manage Plans',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              );

              if (isWide) {
                return Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 16),
                    Expanded(child: contentColumn),
                    const SizedBox(width: 14),
                    actionButton,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        iconWidget,
                        const SizedBox(width: 12),
                        Expanded(child: contentColumn),
                      ],
                    ),
                    const SizedBox(height: 12),
                    actionButton,
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  // --- 5. Activity Grid based on selected Tab ---
  Widget _buildActivityGrid({
    required BuildContext context,
    required bool isBn,
    required bool isDark,
    required AdminFirestoreService adminService,
    required List<PropertyModel> recentProperties,
    required List<TenantDemandModel> recentDemands,
    required List<UserModel> pendingUsers,
    required List<SubscriptionTransactionModel> recentTransactions,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 900;

        if (_selectedActivityTab == 1) {
          // House Owner View Only
          return _buildRecentPropertiesCard(context, recentProperties, isBn, isDark, adminService);
        } else if (_selectedActivityTab == 2) {
          // Tenant View Only
          return _buildRecentDemandsCard(context, recentDemands, isBn, isDark);
        }

        // All Activities (Side-by-side or stacked on web)
        if (isWide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildRecentPropertiesCard(context, recentProperties, isBn, isDark, adminService),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 6,
                    child: _buildRecentDemandsCard(context, recentDemands, isBn, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildPendingVerificationsCard(context, pendingUsers, isBn, isDark, adminService),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 6,
                    child: _buildRecentTransactionsCard(context, recentTransactions, isBn, isDark),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildRecentPropertiesCard(context, recentProperties, isBn, isDark, adminService),
              const SizedBox(height: 18),
              _buildRecentDemandsCard(context, recentDemands, isBn, isDark),
              const SizedBox(height: 18),
              _buildPendingVerificationsCard(context, pendingUsers, isBn, isDark, adminService),
              const SizedBox(height: 18),
              _buildRecentTransactionsCard(context, recentTransactions, isBn, isDark),
            ],
          );
        }
      },
    );
  }

  // --- House Owner Properties Card ---
  Widget _buildRecentPropertiesCard(
    BuildContext context,
    List<PropertyModel> properties,
    bool isBn,
    bool isDark,
    AdminFirestoreService adminService,
  ) {
    final cardBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final itemBg = isDark ? const Color(0xFF142925) : const Color(0xFFF0FDF4);
    final borderColor = isDark ? const Color(0xFF1E3A34) : const Color(0xFFD6EDE8);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.home_work_rounded, color: AppColors.themeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBn ? '🏡 বাড়িওয়ালাদের লাইভ বাসা বিজ্ঞাপন' : '🏡 House Owner Property Listings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => context.read<AdminProvider>().changeModule(AdminModule.properties),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF2DD4BF) : AppColors.themeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(
                  isBn ? 'সব দেখুন' : 'View All',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          if (properties.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text(
                  isBn ? 'কোনো বাসা বিজ্ঞাপন পাওয়া যায়নি' : 'No property listings found',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Column(
              children: properties.map((prop) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: prop.images.isNotEmpty
                              ? _buildImage(prop.images.first, 48, 48)
                              : Container(
                                  color: isDark ? const Color(0xFF223533) : const Color(0xFFE2E8F0),
                                  child: Icon(
                                    Icons.home_rounded,
                                    size: 22,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prop.shortAddress.isNotEmpty ? prop.shortAddress : prop.houseType.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    "${prop.amount} ৳",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF34D399) : AppColors.themeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    "${prop.area.name}, ${prop.district.name}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E).withValues(alpha: isDark ? 0.2 : 0.12),
                              padding: const EdgeInsets.all(6),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18),
                            tooltip: isBn ? 'অনুমোদন করুন' : 'Approve',
                            onPressed: () async {
                              await adminService.updatePropertyApproval(prop.id, 'approved');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isBn ? 'বিজ্ঞাপনটি অনুমোদিত হয়েছে!' : 'Property approved!'),
                                    backgroundColor: const Color(0xFF22C55E),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.12),
                              padding: const EdgeInsets.all(6),
                            ),
                            icon: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18),
                            tooltip: isBn ? 'বাতিল করুন' : 'Reject',
                            onPressed: () => _showRejectDialog(context, prop.id, adminService, isBn),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- Tenant Demands Card ---
  Widget _buildRecentDemandsCard(
    BuildContext context,
    List<TenantDemandModel> demands,
    bool isBn,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final itemBg = isDark ? const Color(0xFF142925) : const Color(0xFFF0FDF4);
    final borderColor = isDark ? const Color(0xFF1E3A34) : const Color(0xFFD6EDE8);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFF0284C7), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBn ? '👤 ভাড়াটিয়াদের লাইভ চাহিদা পোস্ট' : '👤 Tenant Live Rental Demands',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${demands.length} ${isBn ? "টি" : "Demands"}',
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          if (demands.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text(
                  isBn ? 'কোনো ভাড়াটিয়া চাহিদা পোস্ট পাওয়া যায়নি' : 'No tenant demand posts found',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Column(
              children: demands.map((demand) {
                final areaName = demand.area.name.isNotEmpty ? '${demand.area.name}, ${demand.district.name}' : '${demand.houseType.name} Demand';
                final budget = (demand.budgetRange != null && demand.budgetRange!.isNotEmpty) ? demand.budgetRange! : '৳ Negotiable';
                final name = demand.userName.isNotEmpty ? demand.userName : demand.tenantEmail;

                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.15),
                        child: const Icon(Icons.person_search_rounded, color: Color(0xFF0284C7), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              areaName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    budget,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.1),
                          padding: const EdgeInsets.all(6),
                        ),
                        icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                        tooltip: isBn ? 'বিস্তারিত দেখুন' : 'View Details',
                        onPressed: () => _showDemandDetailsDialog(context, demand, isBn),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- Pending NID Verifications Card ---
  Widget _buildPendingVerificationsCard(
    BuildContext context,
    List<UserModel> users,
    bool isBn,
    bool isDark,
    AdminFirestoreService adminService,
  ) {
    final cardBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final itemBg = isDark ? const Color(0xFF142925) : const Color(0xFFF0FDF4);
    final borderColor = isDark ? const Color(0xFF1E3A34) : const Color(0xFFD6EDE8);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBn ? 'এনআইডি ভেরিফিকেশন আবেদন' : 'Pending NID Verifications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => context.read<AdminProvider>().changeModule(AdminModule.users),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF2DD4BF) : AppColors.themeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(
                  isBn ? 'সব দেখুন' : 'View All',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text(
                  isBn ? 'কোনো পেন্ডিং ভেরিফিকেশন নেই' : 'No pending verifications found',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Column(
              children: users.map((user) {
                final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();
                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark
                            ? AppColors.themeColor.withValues(alpha: 0.3)
                            : AppColors.themeColor.withValues(alpha: 0.15),
                        child: Text(
                          user.initials,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF2DD4BF) : AppColors.themeColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? name : 'User',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: (user.userType == 'House Owner' ? Colors.teal : Colors.blue)
                                        .withValues(alpha: isDark ? 0.25 : 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    user.userType,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: user.userType == 'House Owner'
                                          ? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488))
                                          : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF0284C7)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    user.mobile.isNotEmpty ? user.mobile : user.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.verified_rounded, size: 14),
                        onPressed: () async {
                          await adminService.updateUserNidStatus(user.uid, 'verified');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isBn ? 'এনআইডি ভেরিফাইড সম্পন্ন হয়েছে!' : 'User NID Verified!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        label: Text(
                          isBn ? 'ভেরিফাই' : 'Verify',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- Real-time Subscription Transactions Card ---
  Widget _buildRecentTransactionsCard(
    BuildContext context,
    List<SubscriptionTransactionModel> transactions,
    bool isBn,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final itemBg = isDark ? const Color(0xFF142925) : const Color(0xFFF0FDF4);
    final borderColor = isDark ? const Color(0xFF1E3A34) : const Color(0xFFD6EDE8);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.payment_rounded, color: Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBn ? 'লাইভ সাবস্ক্রিপশন লেনদেন' : 'Subscription Transactions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => context.read<AdminProvider>().changeModule(AdminModule.subscriptions),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF2DD4BF) : AppColors.themeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(
                  isBn ? 'সব দেখুন' : 'View All',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text(
                  isBn ? 'কোনো লেনদেন রেকর্ড পাওয়া যায়নি' : 'No subscription transactions found',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Column(
              children: transactions.map((tx) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.15),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.planTitle.isNotEmpty ? tx.planTitle : 'Subscription Package',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${tx.userEmail.isNotEmpty ? tx.userEmail : tx.userMobile} • Trx: ${tx.transactionId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '৳ ${tx.amountPaid.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showDemandDetailsDialog(BuildContext context, TenantDemandModel demand, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.assignment_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 10),
            Expanded(child: Text(isBn ? 'ভাড়াটিয়া চাহিদার বিবরণ' : 'Tenant Demand Details', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(isBn ? 'ভাড়াটিয়ার নাম' : 'Tenant Name', demand.userName.isNotEmpty ? demand.userName : demand.tenantEmail),
              _buildDetailRow(isBn ? 'মোবাইল / যোগাযোগ' : 'Mobile / Contact', demand.userMobile.isNotEmpty ? demand.userMobile : demand.tenantEmail),
              _buildDetailRow(isBn ? 'বিভাগ' : 'Division', demand.division.name.isNotEmpty ? demand.division.name : 'N/A'),
              _buildDetailRow(isBn ? 'জেলা' : 'District', demand.district.name.isNotEmpty ? demand.district.name : 'N/A'),
              _buildDetailRow(isBn ? 'এলাকা' : 'Area', demand.area.name.isNotEmpty ? demand.area.name : 'N/A'),
              _buildDetailRow(isBn ? 'সাব-এরিয়া / ইউনিয়ন' : 'Sub-Area / Union', demand.subArea?.name ?? 'N/A'),
              _buildDetailRow(isBn ? 'বাজেট সীমা' : 'Budget Range', demand.budgetRange ?? 'N/A'),
              _buildDetailRow(isBn ? 'বাসার ধরণ' : 'House Type', demand.houseType.name),
              _buildDetailRow(isBn ? 'রুম / সিট' : 'Room / Seat', demand.roomOrSeat),
              if (demand.bathrooms != null)
                _buildDetailRow(isBn ? 'বাথরুম' : 'Bathrooms', demand.bathrooms.toString()),
              if (demand.detailedDescription.isNotEmpty)
                _buildDetailRow(isBn ? 'বিশেষ চাহিদা' : 'Special Notes', demand.detailedDescription),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            child: Text(isBn ? 'বন্ধ করুন' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String propertyId, AdminFirestoreService adminService, bool isBn) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'বিজ্ঞাপন প্রত্যাখ্যানের কারণ' : 'Reject Property Listing'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: isBn ? 'প্রত্যাখ্যানের কারণ লিখুন' : 'Enter rejection reason',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await adminService.updatePropertyApproval(propertyId, 'rejected', reason: reasonController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'বিজ্ঞাপনটি প্রত্যাখ্যান করা হয়েছে।' : 'Property rejected.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(isBn ? 'প্রত্যাখ্যান করুন' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String src, double width, double height) {
    if (src.isEmpty) {
      return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20));
    }
    if (src.startsWith('data:image') || src.startsWith('/9j/') || src.startsWith('iVBOR') || src.length > 255) {
      try {
        final base64Str = src.contains(',') ? src.split(',').last : src;
        return Image.memory(base64Decode(base64Str.trim()), width: width, height: height, fit: BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.broken_image, size: 20);
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(src, width: width, height: height, fit: BoxFit.cover);
    } else {
      try {
        if (!kIsWeb && File(src).existsSync()) {
          return Image.file(File(src), width: width, height: height, fit: BoxFit.cover);
        }
      } catch (_) {}
      return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20));
    }
  }
}

// --- Compact & Space-Efficient SaaS Micro KPI Card Widget ---
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.badgeText,
    required this.color,
    required this.isDark,
  });

  final String title;
  final String value;
  final IconData icon;
  final String badgeText;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final borderColor = isDark
        ? color.withValues(alpha: 0.3)
        : AppColors.themeColor.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (isDark ? color : AppColors.themeColor).withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [color.withValues(alpha: 0.3), color.withValues(alpha: 0.12)]
                    : [color.withValues(alpha: 0.16), color.withValues(alpha: 0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: isDark ? 0.45 : 0.25)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.22 : 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
