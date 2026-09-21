import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../home/data/models/property_model.dart';
import '../../../home/presentation/screens/property_details_screen.dart';
import '../../../house_owner/presentation/screens/edit_rent_post_screen.dart';
import '../../../shared/data/services/property_firestore_service.dart';
import '../../../shared/data/services/tenant_demand_firestore_service.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/app_network_image.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';
import '../../../subscription/data/models/subscription_model.dart';
import '../../../subscription/data/services/subscription_firestore_service.dart';
import '../../../subscription/presentation/screens/house_owner_subscription_screen.dart';
import '../../../subscription/presentation/screens/tenant_subscription_screen.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';
import '../../../tenant/presentation/screens/edit_demand_screen.dart';
import '../../../tenant/presentation/screens/show_demand_details_screen.dart';
import '../../../wishlist/data/providers/wishlist_provider.dart';

enum RecordSortOption {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  priceDesc,
  priceAsc,
}

class MyRecordScreen extends StatefulWidget {
  const MyRecordScreen({
    super.key,
    this.initialTab = 0,
    this.user,
  });

  final int initialTab;
  final UserModel? user;

  static const String name = '/my-records';

  @override
  State<MyRecordScreen> createState() => _MyRecordScreenState();
}

class _FilterChipItem {
  final String key;
  final String label;
  final int count;
  final Color? color;

  const _FilterChipItem({
    required this.key,
    required this.label,
    required this.count,
    this.color,
  });
}

class _MyRecordScreenState extends State<MyRecordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  RecordSortOption _sortOption = RecordSortOption.newest;

  final PropertyFirestoreService _propertyService = PropertyFirestoreService();
  final TenantDemandFirestoreService _demandService =
      TenantDemandFirestoreService();
  final SubscriptionFirestoreService _subscriptionService =
      SubscriptionFirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = widget.user ?? userProvider.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    if (user == null) {
      return Scaffold(
        appBar: MainAppBar(
          automaticallyImplyLeading: true,
          title: Text(
            isBn ? 'আমার রেকর্ডসমূহ' : 'My Records',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: const [LanguageActionButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  isBn
                      ? 'রেকর্ড দেখতে অনুগ্রহ করে সাইন ইন করুন'
                      : 'Please sign in to view your records',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isOwner = user.isHouseOwner;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          isBn ? 'আমার রেকর্ডসমূহ' : 'My Records',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          LanguageActionButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Overview KPI Metrics Bar
            _buildOverviewKpis(user, isOwner, isBn, isDark),

            // Search Bar & Sort Dropdown
            _buildSearchAndSortBar(isBn, isDark),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: AppColors.themeColor,
                unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[700],
                indicatorColor: AppColors.themeColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    icon: Icon(
                      isOwner
                          ? Icons.apartment_rounded
                          : Icons.post_add_rounded,
                      size: 18,
                    ),
                    text: isOwner
                        ? (isBn ? 'আমার বিজ্ঞাপন' : 'My Properties')
                        : (isBn ? 'আমার চাহিদা' : 'My Demands'),
                  ),
                  Tab(
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    text: isBn ? 'সাবস্ক্রিপশন ও বিল' : 'Subscriptions',
                  ),
                  Tab(
                    icon: Icon(
                      isOwner
                          ? Icons.person_search_rounded
                          : Icons.favorite_rounded,
                      size: 18,
                    ),
                    text: isOwner
                        ? (isBn ? 'চাহিদা ইনকোয়ারি' : 'Inquiries')
                        : (isBn ? 'সংরক্ষিত বাসা' : 'Saved Houses'),
                  ),
                ],
              ),
            ),

            // Tab View Contents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Demands (Tenant) or Properties (House Owner)
                  isOwner
                      ? _buildOwnerPropertiesTab(user, isBn, isDark)
                      : _buildTenantDemandsTab(user, isBn, isDark),

                  // Tab 2: Subscription History & Invoices
                  _buildSubscriptionsTab(user, isBn, isDark),

                  // Tab 3: Wishlist (Tenant) or Area Inquiries (House Owner)
                  isOwner
                      ? _buildOwnerInquiriesTab(user, isBn, isDark)
                      : _buildTenantWishlistTab(user, isBn, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  // 1. OVERVIEW KPI METRICS HEADER
  

  Widget _buildOverviewKpis(
      UserModel user, bool isOwner, bool isBn, bool isDark) {
    if (isOwner) {
      return StreamBuilder<List<PropertyModel>>(
        stream: _propertyService.streamOwnerProperties(user.uid,
            ownerEmail: user.email),
        builder: (context, propSnap) {
          final props = propSnap.data ?? [];
          final totalPosts = props.length;
          final availableCount = props.where((p) => p.isAvailable && !p.isRejected).length;
          final rentedCount = props.where((p) => p.isRentedOut).length;
          final rejectedCount = props.where((p) => p.isRejected).length;

          return StreamBuilder<List<SubscriptionTransactionModel>>(
            stream: _subscriptionService.streamUserTransactions(user.uid),
            builder: (context, subSnap) {
              final subs = subSnap.data ?? [];
              final totalSpent = subs.fold<double>(0.0, (sum, tx) => sum + tx.amountPaid).toInt();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildKpiCard(
                          icon: Icons.apartment_rounded,
                          color: AppColors.themeColor,
                          value: totalPosts.toString().toLocalizedDigits(isBn ? 'bn' : 'en'),
                          label: isBn ? 'মোট বিজ্ঞাপন' : 'Total Posts',
                          isDark: isDark,
                          isSelected: _statusFilter == 'all' && _tabController.index == 0,
                          onTap: () {
                            _tabController.animateTo(0);
                            setState(() => _statusFilter = 'all');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                          value: availableCount.toString().toLocalizedDigits(isBn ? 'bn' : 'en'),
                          label: isBn ? 'ফাঁকা বাসা' : 'Available',
                          isDark: isDark,
                          isSelected: _statusFilter == 'available' && _tabController.index == 0,
                          onTap: () {
                            _tabController.animateTo(0);
                            setState(() => _statusFilter = 'available');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          icon: Icons.visibility_off_rounded,
                          color: Colors.deepOrange,
                          value: rentedCount.toString().toLocalizedDigits(isBn ? 'bn' : 'en'),
                          label: isBn ? 'ভাড়া সম্পন্ন (হাইড)' : 'Rented Out (Hide)',
                          isDark: isDark,
                          isSelected: _statusFilter == 'rented' && _tabController.index == 0,
                          onTap: () {
                            _tabController.animateTo(0);
                            setState(() => _statusFilter = 'rented');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildKpiCard(
                          icon: Icons.cancel_rounded,
                          color: Colors.redAccent,
                          value: rejectedCount.toString().toLocalizedDigits(isBn ? 'bn' : 'en'),
                          label: isBn ? 'বাতিল বিজ্ঞাপন' : 'Rejected Posts',
                          isDark: isDark,
                          isSelected: _statusFilter == 'rejected' && _tabController.index == 0,
                          onTap: () {
                            _tabController.animateTo(0);
                            setState(() => _statusFilter = 'rejected');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFFE2136E),
                          value: '৳${totalSpent.toString().toLocalizedDigits(isBn ? 'bn' : 'en')}',
                          label: isBn ? 'মোট পেমেন্ট' : 'Total Spent',
                          isDark: isDark,
                          isSelected: _tabController.index == 1,
                          onTap: () {
                            _tabController.animateTo(1);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } else {
      // Tenant KPIs
      return StreamBuilder<List<TenantDemandModel>>(
        stream: _demandService.streamTenantDemands(user.uid,
            tenantEmail: user.email),
        builder: (context, demandSnap) {
          final demands = demandSnap.data ?? [];
          final totalDemands = demands.length;
          final activeDemands = demands.where((d) => !d.isFulfilled && !d.isRejected).length;
          final foundHomeCount = demands.where((d) => d.isFulfilled).length;
          final rejectedDemands = demands.where((d) => d.isRejected).length;
          final wishlistCount =
              context.watch<WishlistProvider>().wishlistProperties.length;

          return StreamBuilder<List<SubscriptionTransactionModel>>(
            stream: _subscriptionService.streamUserTransactions(user.uid),
            builder: (context, subSnap) {
              final subs = subSnap.data ?? [];
              final totalSpent = subs.fold<double>(0.0, (sum, tx) => sum + tx.amountPaid).toInt();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildKpiCard(
                          icon: Icons.post_add_rounded,
                          color: AppColors.themeColor,
                          value: totalDemands.toString().toLocalizedDigits(isBn ? 'bn' : 'en'),
                          label: isBn ? 'মোট চাহিদা' : 'Total Demands',
                          isDark: isDark,
                          isSelected: _statusFilter == 'all' && _tabController.index == 0,
                          onTap: () {
                            _tabController.animateTo(0);
                            setState(() => _statusFilter = 'all');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          icon: Icons.pending_actions_rounded,
                          color: const Color(0xFF10B981),
                          value: activeDemands.toString().toLocalizedDigits(isBn ? 'bn' : 'en'),
                          label: isBn ? 'চলমান চাহিদা' : 'Active',
                          isDark: isDark,
                          isSelected: _statusFilter == 'active' && _tabController.index == 0,
                          onTap: () {
                            _tabController.animateTo(0);
                            setState(() => _statusFilter = 'active');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          icon: Icons.check_circle_rounded,
                          color: Colors.teal,
                          value: foundHomeCount.toString().toLocalizedDigits(isBn ? 'bn' : 'en'),
                          label: isBn ? 'বাসা পাওয়া গেছে' : 'Found Home',
                          isDark: isDark,
                          isSelected: _statusFilter == 'fulfilled' && _tabController.index == 0,
                          onTap: () {
                            _tabController.animateTo(0);
                            setState(() => _statusFilter = 'fulfilled');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildKpiCard(
                          icon: Icons.cancel_rounded,
                          color: Colors.redAccent,
                          value: rejectedDemands.toString().toLocalizedDigits(isBn ? 'bn' : 'en'),
                          label: isBn ? 'বাতিল চাহিদা' : 'Rejected',
                          isDark: isDark,
                          isSelected: _statusFilter == 'rejected' && _tabController.index == 0,
                          onTap: () {
                            _tabController.animateTo(0);
                            setState(() => _statusFilter = 'rejected');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          icon: Icons.favorite_rounded,
                          color: Colors.pinkAccent,
                          value: wishlistCount.toString().toLocalizedDigits(isBn ? 'bn' : 'en'),
                          label: isBn ? 'সংরক্ষিত' : 'Saved',
                          isDark: isDark,
                          isSelected: _tabController.index == 2,
                          onTap: () {
                            _tabController.animateTo(2);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFFE2136E),
                          value: '৳${totalSpent.toString().toLocalizedDigits(isBn ? 'bn' : 'en')}',
                          label: isBn ? 'মোট পেমেন্ট' : 'Total Spent',
                          isDark: isDark,
                          isSelected: _tabController.index == 1,
                          onTap: () {
                            _tabController.animateTo(1);
                          },
                        ),
                      ],
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

  Widget _buildKpiCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required bool isDark,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: isDark ? 0.25 : 0.12)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? color
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: isSelected ? 6 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips({
    required List<_FilterChipItem> chips,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: chips.map((chip) {
          final isSelected = _statusFilter == chip.key;
          final color = chip.color ?? AppColors.themeColor;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: isSelected
                  ? const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white)
                  : null,
              label: Text(
                '${chip.label} (${chip.count.toString().toLocalizedDigits(Localizations.localeOf(context).languageCode == 'bn' ? 'bn' : 'en')})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
              ),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              selectedColor: color,
              side: BorderSide(
                color: isSelected
                    ? color
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) {
                setState(() => _statusFilter = chip.key);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  
  // 2. SEARCH AND SORT TOOLBAR
  

  Widget _buildSearchAndSortBar(bool isBn, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: isBn
                      ? 'রেকর্ড খুঁজুন (এলাকা, ভাড়া, বিবরণ, ট্রানজেকশন আইডি)...'
                      : 'Search records (area, rent, details, TrxID)...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  prefixIcon:
                      const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSortDropdownButton(isBn, isDark),
        ],
      ),
    );
  }

  Widget _buildSortDropdownButton(bool isBn, bool isDark) {
    return PopupMenuButton<RecordSortOption>(
      initialValue: _sortOption,
      onSelected: (option) => setState(() => _sortOption = option),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: RecordSortOption.newest,
          child: Row(
            children: [
              Icon(Icons.arrow_downward_rounded,
                  size: 16,
                  color: _sortOption == RecordSortOption.newest
                      ? AppColors.themeColor
                      : Colors.grey),
              const SizedBox(width: 8),
              Text(
                isBn ? 'সর্বশেষ আগে (Newest)' : 'Newest First',
                style: TextStyle(
                  fontWeight: _sortOption == RecordSortOption.newest
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _sortOption == RecordSortOption.newest
                      ? AppColors.themeColor
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: RecordSortOption.oldest,
          child: Row(
            children: [
              Icon(Icons.arrow_upward_rounded,
                  size: 16,
                  color: _sortOption == RecordSortOption.oldest
                      ? AppColors.themeColor
                      : Colors.grey),
              const SizedBox(width: 8),
              Text(
                isBn ? 'সবচেয়ে পুরনো (Oldest)' : 'Oldest First',
                style: TextStyle(
                  fontWeight: _sortOption == RecordSortOption.oldest
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _sortOption == RecordSortOption.oldest
                      ? AppColors.themeColor
                      : null,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: RecordSortOption.nameAsc,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha_rounded,
                  size: 16,
                  color: _sortOption == RecordSortOption.nameAsc
                      ? AppColors.themeColor
                      : Colors.grey),
              const SizedBox(width: 8),
              Text(
                isBn ? 'নাম: A to Z (ক থেকে ঁ)' : 'Title / Area: A to Z',
                style: TextStyle(
                  fontWeight: _sortOption == RecordSortOption.nameAsc
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _sortOption == RecordSortOption.nameAsc
                      ? AppColors.themeColor
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: RecordSortOption.nameDesc,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha_rounded,
                  size: 16,
                  color: _sortOption == RecordSortOption.nameDesc
                      ? AppColors.themeColor
                      : Colors.grey),
              const SizedBox(width: 8),
              Text(
                isBn ? 'নাম: Z to A' : 'Title / Area: Z to A',
                style: TextStyle(
                  fontWeight: _sortOption == RecordSortOption.nameDesc
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _sortOption == RecordSortOption.nameDesc
                      ? AppColors.themeColor
                      : null,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: RecordSortOption.priceDesc,
          child: Row(
            children: [
              Icon(Icons.attach_money_rounded,
                  size: 16,
                  color: _sortOption == RecordSortOption.priceDesc
                      ? AppColors.themeColor
                      : Colors.grey),
              const SizedBox(width: 8),
              Text(
                isBn ? 'ভাড়া/বাজেট: বেশি থেকে কম' : 'Price / Budget: High to Low',
                style: TextStyle(
                  fontWeight: _sortOption == RecordSortOption.priceDesc
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _sortOption == RecordSortOption.priceDesc
                      ? AppColors.themeColor
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: RecordSortOption.priceAsc,
          child: Row(
            children: [
              Icon(Icons.money_off_rounded,
                  size: 16,
                  color: _sortOption == RecordSortOption.priceAsc
                      ? AppColors.themeColor
                      : Colors.grey),
              const SizedBox(width: 8),
              Text(
                isBn ? 'ভাড়া/বাজেট: কম থেকে বেশি' : 'Price / Budget: Low to High',
                style: TextStyle(
                  fontWeight: _sortOption == RecordSortOption.priceAsc
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _sortOption == RecordSortOption.priceAsc
                      ? AppColors.themeColor
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 20, color: AppColors.themeColor),
            const SizedBox(width: 4),
            Text(
              isBn ? 'সর্ট' : 'Sort',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  
  // 3. TAB 1: HOUSE OWNER PROPERTIES TAB
  

  Widget _buildOwnerPropertiesTab(UserModel user, bool isBn, bool isDark) {
    return StreamBuilder<List<PropertyModel>>(
      stream: _propertyService.streamOwnerProperties(user.uid,
          ownerEmail: user.email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.themeColor));
        }

        final allProps = snapshot.data ?? [];
        final totalCount = allProps.length;
        final availableCount = allProps.where((p) => p.isAvailable && !p.isRejected).length;
        final rentedCount = allProps.where((p) => p.isRentedOut).length;
        final rejectedCount = allProps.where((p) => p.isRejected).length;

        var list = List<PropertyModel>.from(allProps);

        // Status Filter
        if (_statusFilter == 'available') {
          list = list.where((p) => p.isAvailable && !p.isRejected).toList();
        } else if (_statusFilter == 'rented') {
          list = list.where((p) => p.isRentedOut).toList();
        } else if (_statusFilter == 'rejected') {
          list = list.where((p) => p.isRejected).toList();
        }

        // Filter search
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          list = list.where((p) {
            final title = p.houseType.name.toLowerCase();
            final area = p.area.name.toLowerCase();
            final dist = p.district.name.toLowerCase();
            final addr = p.shortAddress.toLowerCase();
            final desc = p.detailedDescription.toLowerCase();
            final amt = p.amount.toLowerCase();
            return title.contains(q) ||
                area.contains(q) ||
                dist.contains(q) ||
                addr.contains(q) ||
                desc.contains(q) ||
                amt.contains(q);
          }).toList();
        }

        // Apply Sorting
        list.sort((a, b) {
          switch (_sortOption) {
            case RecordSortOption.newest:
              return b.postDate.compareTo(a.postDate);
            case RecordSortOption.oldest:
              return a.postDate.compareTo(b.postDate);
            case RecordSortOption.nameAsc:
              return a.area.name.compareTo(b.area.name);
            case RecordSortOption.nameDesc:
              return b.area.name.compareTo(a.area.name);
            case RecordSortOption.priceDesc:
              final int pA = int.tryParse(a.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final int pB = int.tryParse(b.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return pB.compareTo(pA);
            case RecordSortOption.priceAsc:
              final int pA = int.tryParse(a.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final int pB = int.tryParse(b.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return pA.compareTo(pB);
          }
        });

        return Column(
          children: [
            _buildFilterChips(
              chips: [
                _FilterChipItem(
                  key: 'all',
                  label: isBn ? 'সকল' : 'All',
                  count: totalCount,
                  color: AppColors.themeColor,
                ),
                _FilterChipItem(
                  key: 'available',
                  label: isBn ? 'ফাঁকা আছে' : 'Available',
                  count: availableCount,
                  color: const Color(0xFF10B981),
                ),
                _FilterChipItem(
                  key: 'rented',
                  label: isBn ? 'ভাড়া সম্পন্ন (হাইড)' : 'Rented Out (Hide)',
                  count: rentedCount,
                  color: Colors.deepOrange,
                ),
                _FilterChipItem(
                  key: 'rejected',
                  label: isBn ? 'বাতিল' : 'Rejected',
                  count: rejectedCount,
                  color: Colors.redAccent,
                ),
              ],
              isDark: isDark,
            ),
            Expanded(
              child: list.isEmpty
                  ? _buildEmptyTabState(
                      icon: Icons.apartment_rounded,
                      title: isBn ? 'কোনো বিজ্ঞাপন পাওয়া যায়নি' : 'No Properties Found',
                      subtitle: isBn
                          ? 'আপনার দেওয়া সার্চ বা ফিল্টারের সাথে মিলে এমন কোনো বিজ্ঞাপন পাওয়া যায়নি।'
                          : 'No property posts matching your query or filter.',
                      isBn: isBn,
                      isDark: isDark,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final property = list[index];
                        return _buildOwnerPropertyCard(property, isBn, isDark);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOwnerPropertyCard(PropertyModel property, bool isBn, bool isDark) {
    final l10n = context.localizations;
    final image = property.images.isNotEmpty ? property.images.first : '';
    final location = "${property.area.name}, ${property.district.name}";

    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;

    if (property.isRejected) {
      badgeBgColor = Colors.red.withValues(alpha: 0.15);
      badgeTextColor = Colors.red;
      badgeText = isBn ? 'বাতিল' : 'Rejected';
    } else if (property.isRentedOut) {
      badgeBgColor = Colors.deepOrange.withValues(alpha: 0.15);
      badgeTextColor = Colors.deepOrange;
      badgeText = isBn ? 'ভাড়া সম্পন্ন (হাইড)' : 'Rented Out (Hide)';
    } else if (property.isPendingApproval) {
      badgeBgColor = Colors.amber.withValues(alpha: 0.15);
      badgeTextColor = Colors.amber.shade800;
      badgeText = isBn ? 'অপেক্ষমাণ' : 'Pending';
    } else {
      badgeBgColor = Colors.green.withValues(alpha: 0.15);
      badgeTextColor = Colors.green;
      badgeText = isBn ? 'ফাঁকা আছে' : 'Available';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 75,
                    height: 75,
                    child: AppImageWidget(
                      imageSource: image.isNotEmpty ? image : null,
                      width: 75,
                      height: 75,
                      fit: BoxFit.cover,
                    ),
                  ),
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
                              property.houseType.getLocalizedLabel(l10n),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '৳${property.amount.toLocalizedDigits(isBn ? 'bn' : 'en')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.themeColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${property.postDate.day}/${property.postDate.month}/${property.postDate.year}'
                                .toLocalizedDigits(isBn ? 'bn' : 'en'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (property.isRejected &&
                          property.rejectionReason != null &&
                          property.rejectionReason!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isBn
                                      ? 'বাতিলের কারণ: ${property.rejectionReason}'
                                      : 'Reason: ${property.rejectionReason}',
                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action Buttons Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Quick Toggle Available / Rented
                InkWell(
                  onTap: () async {
                    await _propertyService.togglePropertyAvailability(
                        property.id, !property.isAvailable);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          property.isAvailable
                              ? Icons.toggle_on_rounded
                              : Icons.toggle_off_rounded,
                          size: 20,
                          color: property.isAvailable
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          property.isAvailable
                              ? (isBn ? 'ভাড়া হলে মার্ক করুন' : 'Mark Rented')
                              : (isBn ? 'পুনরায় ফাঁকা করুন' : 'Mark Available'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: property.isAvailable
                                ? Colors.green
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // View Details
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: isBn ? 'বিস্তারিত দেখুন' : 'View Details',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      PropertyDetailsScreen.name,
                      arguments: property,
                    );
                  },
                ),
                // Edit Post
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: isBn ? 'এডিট করুন' : 'Edit Post',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      EditRentPostScreen.name,
                      arguments: property,
                    );
                  },
                ),
                // Delete Post
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.redAccent),
                  tooltip: isBn ? 'মুছে ফেলুন' : 'Delete Post',
                  onPressed: () => _confirmDeleteProperty(property, isBn),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProperty(PropertyModel property, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'বিজ্ঞাপন ডিলিট নিশ্চিত করুন' : 'Confirm Delete'),
        content: Text(isBn
            ? 'আপনি কি নিশ্চিত যে এই বাসাভাড়ার বিজ্ঞাপনটি ডিলিট করতে চান?'
            : 'Are you sure you want to delete this property post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _propertyService.deleteProperty(property.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn
                        ? 'বিজ্ঞাপনটি ডিলিট করা হয়েছে।'
                        : 'Property deleted successfully.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(isBn ? 'ডিলিট' : 'Delete'),
          ),
        ],
      ),
    );
  }

  
  // 4. TAB 1 (TENANT): MY DEMANDS TAB
  

  Widget _buildTenantDemandsTab(UserModel user, bool isBn, bool isDark) {
    return StreamBuilder<List<TenantDemandModel>>(
      stream: _demandService.streamTenantDemands(user.uid,
          tenantEmail: user.email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor));
        }

        final allDemands = snapshot.data ?? [];
        final totalCount = allDemands.length;
        final activeCount = allDemands.where((d) => !d.isFulfilled && !d.isRejected).length;
        final fulfilledCount = allDemands.where((d) => d.isFulfilled).length;
        final rejectedCount = allDemands.where((d) => d.isRejected).length;

        var list = List<TenantDemandModel>.from(allDemands);

        // Status Filter
        if (_statusFilter == 'active') {
          list = list.where((d) => !d.isFulfilled && !d.isRejected).toList();
        } else if (_statusFilter == 'fulfilled') {
          list = list.where((d) => d.isFulfilled).toList();
        } else if (_statusFilter == 'rejected') {
          list = list.where((d) => d.isRejected).toList();
        }

        // Filter search
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          list = list.where((d) {
            final title = d.houseType.name.toLowerCase();
            final area = d.area.name.toLowerCase();
            final dist = d.district.name.toLowerCase();
            final addr = d.shortAddress.toLowerCase();
            final desc = d.detailedDescription.toLowerCase();
            final budget = (d.budgetRange ?? '').toLowerCase();
            final month = d.month.toLowerCase();
            return title.contains(q) ||
                area.contains(q) ||
                dist.contains(q) ||
                addr.contains(q) ||
                desc.contains(q) ||
                budget.contains(q) ||
                month.contains(q);
          }).toList();
        }

        // Sorting
        list.sort((a, b) {
          switch (_sortOption) {
            case RecordSortOption.newest:
              return b.postDate.compareTo(a.postDate);
            case RecordSortOption.oldest:
              return a.postDate.compareTo(b.postDate);
            case RecordSortOption.nameAsc:
              return a.area.name.compareTo(b.area.name);
            case RecordSortOption.nameDesc:
              return b.area.name.compareTo(a.area.name);
            case RecordSortOption.priceDesc:
              final int pA = int.tryParse(
                      (a.budgetRange ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              final int pB = int.tryParse(
                      (b.budgetRange ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              return pB.compareTo(pA);
            case RecordSortOption.priceAsc:
              final int pA = int.tryParse(
                      (a.budgetRange ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              final int pB = int.tryParse(
                      (b.budgetRange ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              return pA.compareTo(pB);
          }
        });

        return Column(
          children: [
            _buildFilterChips(
              chips: [
                _FilterChipItem(
                  key: 'all',
                  label: isBn ? 'সকল' : 'All',
                  count: totalCount,
                  color: AppColors.themeColor,
                ),
                _FilterChipItem(
                  key: 'active',
                  label: isBn ? 'চলমান চাহিদা' : 'Active',
                  count: activeCount,
                  color: const Color(0xFF10B981),
                ),
                _FilterChipItem(
                  key: 'fulfilled',
                  label: isBn ? 'বাসা পাওয়া গেছে' : 'Found Home',
                  count: fulfilledCount,
                  color: Colors.teal,
                ),
                _FilterChipItem(
                  key: 'rejected',
                  label: isBn ? 'বাতিল' : 'Rejected',
                  count: rejectedCount,
                  color: Colors.redAccent,
                ),
              ],
              isDark: isDark,
            ),
            Expanded(
              child: list.isEmpty
                  ? _buildEmptyTabState(
                      icon: Icons.assignment_late_outlined,
                      title: isBn ? 'কোনো চাহিদা পাওয়া যায়নি' : 'No Demands Found',
                      subtitle: isBn
                          ? 'আপনার কোনো চাহিদা পোস্ট এখনো জমা দেওয়া হয়নি বা সার্চে পাওয়া যায়নি।'
                          : 'No demand posts matching your query or filter.',
                      isBn: isBn,
                      isDark: isDark,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final demand = list[index];
                        return _buildTenantDemandCard(demand, isBn, isDark);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTenantDemandCard(
      TenantDemandModel demand, bool isBn, bool isDark) {
    final l10n = context.localizations;
    final location = "${demand.area.name}, ${demand.district.name}";

    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;

    if (demand.isRejected) {
      badgeBgColor = Colors.red.withValues(alpha: 0.15);
      badgeTextColor = Colors.red;
      badgeText = isBn ? 'বাতিল' : 'Rejected';
    } else if (demand.isFulfilled) {
      badgeBgColor = Colors.teal.withValues(alpha: 0.15);
      badgeTextColor = Colors.teal;
      badgeText = isBn ? 'বাসা পাওয়া গেছে' : 'Found Home';
    } else if (demand.isPendingApproval) {
      badgeBgColor = Colors.amber.withValues(alpha: 0.15);
      badgeTextColor = Colors.amber.shade800;
      badgeText = isBn ? 'অপেক্ষমাণ' : 'Pending';
    } else {
      badgeBgColor = Colors.green.withValues(alpha: 0.15);
      badgeTextColor = Colors.green;
      badgeText = isBn ? 'চলমান চাহিদা' : 'Active';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.post_add_rounded,
                      color: AppColors.themeColor, size: 26),
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
                              demand.houseType.getLocalizedLabel(l10n),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            demand.budgetRange != null &&
                                    demand.budgetRange!.isNotEmpty
                                ? 'বাজেট: ৳${demand.budgetRange!.toLocalizedDigits(isBn ? 'bn' : 'en')}'
                                : (isBn ? 'বাজেট: আলোচনা সাপেক্ষ' : 'Budget: Negotiable'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.themeColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${demand.postDate.day}/${demand.postDate.month}/${demand.postDate.year}'
                                .toLocalizedDigits(isBn ? 'bn' : 'en'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (demand.isRejected &&
                          demand.rejectionReason != null &&
                          demand.rejectionReason!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isBn
                                      ? 'বাতিলের কারণ: ${demand.rejectionReason}'
                                      : 'Reason: ${demand.rejectionReason}',
                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action Buttons Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Quick Toggle Fulfilled Status
                InkWell(
                  onTap: () async {
                    await _demandService.toggleDemandFulfilledStatus(
                        demand.id, !demand.isFulfilled);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          demand.isFulfilled
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 18,
                          color: demand.isFulfilled
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          demand.isFulfilled
                              ? (isBn ? 'বাসা পেয়েছি' : 'Fulfilled')
                              : (isBn ? 'বাসা খুঁজছি' : 'Still Looking'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: demand.isFulfilled
                                ? Colors.green
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // View Details
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: isBn ? 'বিস্তারিত দেখুন' : 'View Details',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      ShowDemandDetailsScreen.name,
                      arguments: demand,
                    );
                  },
                ),
                // Edit Post
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: isBn ? 'এডিট করুন' : 'Edit Demand',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      EditDemandScreen.name,
                      arguments: demand,
                    );
                  },
                ),
                // Delete Post
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.redAccent),
                  tooltip: isBn ? 'মুছে ফেলুন' : 'Delete Demand',
                  onPressed: () => _confirmDeleteDemand(demand, isBn),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDemand(TenantDemandModel demand, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'চাহিদা ডিলিট নিশ্চিত করুন' : 'Confirm Delete'),
        content: Text(isBn
            ? 'আপনি কি নিশ্চিত যে এই চাহিদা পোস্টটি ডিলিট করতে চান?'
            : 'Are you sure you want to delete this demand post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _demandService.deleteDemand(demand.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn
                        ? 'চাহিদা পোস্টটি ডিলিট করা হয়েছে।'
                        : 'Demand post deleted successfully.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(isBn ? 'ডিলিট' : 'Delete'),
          ),
        ],
      ),
    );
  }

  
  // 5. TAB 2: SUBSCRIPTIONS & RECEIPTS TAB
  

  Widget _buildSubscriptionsTab(UserModel user, bool isBn, bool isDark) {
    return StreamBuilder<List<SubscriptionTransactionModel>>(
      stream: _subscriptionService.streamUserTransactions(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor));
        }

        var list = snapshot.data ?? [];

        // Filter search
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          list = list.where((tx) {
            final plan = tx.planTitle.toLowerCase();
            final trx = tx.transactionId.toLowerCase();
            final sender = tx.senderPhone.toLowerCase();
            final amt = tx.amountPaid.toString();
            return plan.contains(q) ||
                trx.contains(q) ||
                sender.contains(q) ||
                amt.contains(q);
          }).toList();
        }

        // Sorting
        list.sort((a, b) {
          switch (_sortOption) {
            case RecordSortOption.newest:
              return b.purchasedAt.compareTo(a.purchasedAt);
            case RecordSortOption.oldest:
              return a.purchasedAt.compareTo(b.purchasedAt);
            case RecordSortOption.nameAsc:
              return a.planTitle.compareTo(b.planTitle);
            case RecordSortOption.nameDesc:
              return b.planTitle.compareTo(a.planTitle);
            case RecordSortOption.priceDesc:
              return b.amountPaid.compareTo(a.amountPaid);
            case RecordSortOption.priceAsc:
              return a.amountPaid.compareTo(b.amountPaid);
          }
        });

        if (list.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2136E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 46, color: Color(0xFFE2136E)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isBn ? 'কোনো সাবস্ক্রিপশন রেকর্ড নেই' : 'No Subscriptions Found',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'আপনার অ্যাকাউন্টে এখনো কোনো প্রিমিয়াম প্যাকেজ বা পেমেন্ট রেকর্ড নেই।'
                        : 'You have not purchased any subscription package yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE2136E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: Text(isBn ? 'প্যাকেজসমূহ দেখুন' : 'Explore Packages'),
                    onPressed: () {
                      if (user.isHouseOwner) {
                        Navigator.pushNamed(
                            context, HouseOwnerSubscriptionScreen.name);
                      } else {
                        Navigator.pushNamed(
                            context, TenantSubscriptionScreen.name);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = list[index];
            return _buildSubscriptionCard(tx, isBn, isDark);
          },
        );
      },
    );
  }

  Widget _buildSubscriptionCard(
      SubscriptionTransactionModel tx, bool isBn, bool isDark) {
    final bool isExpired = tx.expiresAt.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  color: const Color(0xFFE2136E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payment_rounded,
                    color: Color(0xFFE2136E), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.planTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TrxID: ${tx.transactionId}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳${tx.amountPaid.toInt().toString().toLocalizedDigits(isBn ? 'bn' : 'en')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFFE2136E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? Colors.grey.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isExpired
                          ? (isBn ? 'মেয়াদোত্তীর্ণ' : 'Expired')
                          : (isBn ? 'সক্রিয়' : 'Active'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isExpired ? Colors.grey : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${tx.purchasedAt.day}/${tx.purchasedAt.month}/${tx.purchasedAt.year}'
                    .toLocalizedDigits(isBn ? 'bn' : 'en'),
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.receipt_rounded,
                    size: 15, color: AppColors.themeColor),
                label: Text(
                  isBn ? 'ডিজিটাল রসিদ' : 'Digital Receipt',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.themeColor,
                  ),
                ),
                onPressed: () => _showReceiptModal(tx, isBn, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReceiptModal(
      SubscriptionTransactionModel tx, bool isBn, bool isDark) {
    final rawDateStr =
        '${tx.purchasedAt.day}/${tx.purchasedAt.month}/${tx.purchasedAt.year} • ${tx.purchasedAt.hour}:${tx.purchasedAt.minute.toString().padLeft(2, '0')}';
    final rawExpiryStr =
        '${tx.expiresAt.day}/${tx.expiresAt.month}/${tx.expiresAt.year}';
    final dateStr = isBn ? rawDateStr.toLocalizedDigits('bn') : rawDateStr;
    final expiryStr = isBn ? rawExpiryStr.toLocalizedDigits('bn') : rawExpiryStr;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.themeColor, size: 36),
                ),
              const SizedBox(height: 12),
              Text(
                isBn ? 'ডিজিটাল পেমেন্ট রসিদ' : 'Digital Payment Receipt',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              const Text(
                'BashaBondhu Payment Gateway',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),
              _buildReceiptRow(isBn ? 'প্যাকেজ' : 'Package Plan', tx.planTitle, isDark),
              _buildReceiptRow(
                  isBn ? 'পেমেন্ট মাধ্যম' : 'Payment Method',
                  tx.paymentMethod.isNotEmpty ? tx.paymentMethod : 'SSLCOMMERZ Gateway',
                  isDark),
              _buildReceiptRow(isBn ? 'প্রেরক নম্বর' : 'Sender Phone',
                  tx.senderPhone.isNotEmpty ? tx.senderPhone : '017XXXXXXXX', isDark),
              _buildReceiptRow(
                  isBn ? 'ট্রানজেকশন আইডি' : 'Transaction ID', tx.transactionId, isDark,
                  isBold: true, isHighlight: true),
              _buildReceiptRow(isBn ? 'ক্রয়ের তারিখ' : 'Purchase Date', dateStr, isDark),
              _buildReceiptRow(isBn ? 'মেয়াদ উত্তীর্ণ' : 'Valid Until', expiryStr, isDark),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBn ? 'মোট পরিশোধিত' : 'Total Paid',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '৳${tx.amountPaid.toInt().toString().toLocalizedDigits(isBn ? 'bn' : 'en')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFFE2136E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(isBn ? 'কপি TrxID' : 'Copy TrxID'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: tx.transactionId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isBn
                                ? 'ট্রানজেকশন আইডি কপি করা হয়েছে'
                                : 'Transaction ID copied to clipboard'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.themeColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(isBn ? 'ঠিক আছে' : 'Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildReceiptRow(String label, String value, bool isDark,
      {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: isHighlight
                    ? const Color(0xFFE2136E)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  // 6. TAB 3 (TENANT): SAVED HOUSES (WISHLIST)
  

  Widget _buildTenantWishlistTab(UserModel user, bool isBn, bool isDark) {
    final wishlist = context.watch<WishlistProvider>().wishlistProperties;

    var list = List<PropertyModel>.from(wishlist);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final title = p.houseType.name.toLowerCase();
        final area = p.area.name.toLowerCase();
        final dist = p.district.name.toLowerCase();
        final addr = p.shortAddress.toLowerCase();
        final amt = p.amount.toLowerCase();
        return title.contains(q) ||
            area.contains(q) ||
            dist.contains(q) ||
            addr.contains(q) ||
            amt.contains(q);
      }).toList();
    }

    // Sorting
    list.sort((a, b) {
      switch (_sortOption) {
        case RecordSortOption.newest:
          return b.postDate.compareTo(a.postDate);
        case RecordSortOption.oldest:
          return a.postDate.compareTo(b.postDate);
        case RecordSortOption.nameAsc:
          return a.area.name.compareTo(b.area.name);
        case RecordSortOption.nameDesc:
          return b.area.name.compareTo(a.area.name);
        case RecordSortOption.priceDesc:
          final int pA = int.tryParse(a.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final int pB = int.tryParse(b.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return pB.compareTo(pA);
        case RecordSortOption.priceAsc:
          final int pA = int.tryParse(a.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final int pB = int.tryParse(b.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return pA.compareTo(pB);
      }
    });

    if (list.isEmpty) {
      return _buildEmptyTabState(
        icon: Icons.favorite_border_rounded,
        title: isBn ? 'কোনো সংরক্ষিত বাসা নেই' : 'No Saved Houses',
        subtitle: isBn
            ? 'পছন্দের বাসাগুলো সংরক্ষণ করতে হোম স্ক্রিনে হার্ট আইকন চাপুন।'
            : 'Tap the heart icon on any property in Home screen to save it here.',
        isBn: isBn,
        isDark: isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final property = list[index];
        final image = property.images.isNotEmpty ? property.images.first : '';
        final location = "${property.area.name}, ${property.district.name}";

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: AppImageWidget(
                    imageSource: image.isNotEmpty ? image : null,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.houseType.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${property.amount.toLocalizedDigits(isBn ? 'bn' : 'en')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: AppColors.themeColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                onPressed: () {
                  context.read<WishlistProvider>().toggleFavorite(user.uid, property.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    PropertyDetailsScreen.name,
                    arguments: property,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  
  // 7. TAB 3 (HOUSE OWNER): DEMAND INQUIRIES
  

  Widget _buildOwnerInquiriesTab(UserModel user, bool isBn, bool isDark) {
    return StreamBuilder<List<TenantDemandModel>>(
      stream: _demandService.streamAllDemands(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor));
        }

        var list = snapshot.data ?? [];

        // Filter search
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          list = list.where((d) {
            final title = d.houseType.name.toLowerCase();
            final area = d.area.name.toLowerCase();
            final dist = d.district.name.toLowerCase();
            final budget = (d.budgetRange ?? '').toLowerCase();
            return title.contains(q) ||
                area.contains(q) ||
                dist.contains(q) ||
                budget.contains(q);
          }).toList();
        }

        // Sorting
        list.sort((a, b) {
          switch (_sortOption) {
            case RecordSortOption.newest:
              return b.postDate.compareTo(a.postDate);
            case RecordSortOption.oldest:
              return a.postDate.compareTo(b.postDate);
            case RecordSortOption.nameAsc:
              return a.area.name.compareTo(b.area.name);
            case RecordSortOption.nameDesc:
              return b.area.name.compareTo(a.area.name);
            case RecordSortOption.priceDesc:
              final int pA = int.tryParse(
                      (a.budgetRange ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              final int pB = int.tryParse(
                      (b.budgetRange ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              return pB.compareTo(pA);
            case RecordSortOption.priceAsc:
              final int pA = int.tryParse(
                      (a.budgetRange ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              final int pB = int.tryParse(
                      (b.budgetRange ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              return pA.compareTo(pB);
          }
        });

        if (list.isEmpty) {
          return _buildEmptyTabState(
            icon: Icons.person_search_rounded,
            title: isBn ? 'কোনো চাহিদা ইনকোয়ারি পাওয়া যায়নি' : 'No Inquiries Found',
            subtitle: isBn
                ? 'বর্তমানে আপনার এলাকায় কোনো সক্রিয় ভাড়াটিয়া চাহিদা পাওয়া যায়নি।'
                : 'No prospective tenant demand posts found at the moment.',
            isBn: isBn,
            isDark: isDark,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final demand = list[index];
            final location = "${demand.area.name}, ${demand.district.name}";

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_pin_circle_rounded,
                        color: Colors.blueAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          demand.houseType.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          demand.budgetRange != null && demand.budgetRange!.isNotEmpty
                              ? 'বাজেট: ৳${demand.budgetRange!.toLocalizedDigits(isBn ? 'bn' : 'en')}'
                              : (isBn ? 'বাজেট: আলোচনা সাপেক্ষ' : 'Budget: Negotiable'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppColors.themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        ShowDemandDetailsScreen.name,
                        arguments: demand,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  // 8. REUSABLE EMPTY TAB STATE
  

  Widget _buildEmptyTabState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isBn,
    required bool isDark,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 46, color: AppColors.themeColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

