import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/models/user_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/presentation/screens/property_details_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/services/tenant_demand_firestore_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/my_profile_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/edit_demand_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/my_demand_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/show_demand_details_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/wishlist/data/providers/wishlist_provider.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';

class TenantDashboardScreen extends StatefulWidget {
  static const String name = '/tenant-dashboard';

  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  static const Color _grey = Color(0xFF7A8A88);
  static final Map<String, Uint8List> _base64Cache = {};

  final TenantDemandFirestoreService _demandService = TenantDemandFirestoreService();

  Stream<List<TenantDemandModel>>? _demandsStream;
  String? _initializedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null && user.uid != _initializedUserId) {
      _initializedUserId = user.uid;
      _demandsStream = _demandService.streamTenantDemands(user.uid, tenantEmail: user.email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final UserModel? user = userProvider.user;
    final wishlistProvider = context.watch<WishlistProvider>();
    final navProvider = context.read<MainNavHolderProvider>();

    if (user == null) {
      return Scaffold(
        appBar: MainAppBar(
          title: Text(l10n.myDashboard),
          automaticallyImplyLeading: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: MainAppBar(
        title: Text(l10n.myDashboard),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<TenantDemandModel>>(
          stream: _demandsStream,
          builder: (context, demandSnapshot) {
            final demands = demandSnapshot.data ?? [];
            final int demandCount = demands.length;
            final int wishlistCount = wishlistProvider.wishlistProperties.length;
            final int completion = user.profileCompletionPercentage;
            final bool isVerified = user.nidFrontImageUrl.isNotEmpty;

            return RefreshIndicator(
              color: AppColors.themeColor,
              onRefresh: () async {
                await userProvider.fetchUserData(user.uid);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Tenant Profile Overview Header
                    _buildProfileHeader(context, user, theme, isDark, l10n, completion, isVerified),
                    const SizedBox(height: 18),

                    // 2. Key Metrics Analytics Grid (4 Cards)
                    _buildMetricsGrid(
                      context,
                      demandCount: demandCount,
                      wishlistCount: wishlistCount,
                      completion: completion,
                      isVerified: isVerified,
                      isDark: isDark,
                      l10n: l10n,
                      navProvider: navProvider,
                    ),
                    const SizedBox(height: 24),

                    // 3. Quick Actions Hub
                    DecoratedSectionHeader(title: l10n.quickShortcuts),
                    const SizedBox(height: 12),
                    _buildQuickActionsRow(context, navProvider, l10n),
                    const SizedBox(height: 24),

                    // 4. My Rental Demands Section
                    _buildSectionHeaderWithAction(
                      title: l10n.recentDemands,
                      actionLabel: l10n.viewAll,
                      onAction: () => Navigator.pushNamed(context, MyDemandScreen.name),
                    ),
                    const SizedBox(height: 12),
                    _buildDemandsList(context, demands, isDark, l10n, _demandService),
                    const SizedBox(height: 24),

                    // 5. Saved Properties / Wishlist Preview
                    _buildSectionHeaderWithAction(
                      title: l10n.savedProperties,
                      actionLabel: l10n.viewAll,
                      onAction: () {
                        Navigator.pop(context);
                        navProvider.changeIndex(3);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildWishlistPreview(context, wishlistProvider, isDark, l10n, user.uid),
                    const SizedBox(height: 24),

                    // 6. Tenant Activity & History Timeline
                    DecoratedSectionHeader(title: l10n.activityHistory),
                    const SizedBox(height: 12),
                    _buildTenantActivityTimeline(
                      user,
                      demandCount,
                      wishlistCount,
                      isVerified,
                      isDark,
                      l10n,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // WIDGET BUILDERS
  // ==========================================================================

  Widget _buildProfileHeader(
    BuildContext context,
    UserModel user,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    int completion,
    bool isVerified,
  ) {
    final String name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();
    final String initials = user.initials;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.themeColor.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: user.profileImageUrl.isEmpty
                  ? const LinearGradient(
                      colors: [Color(0xFF028090), Color(0xFF00A896)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.themeColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: user.profileImageUrl.isNotEmpty
                  ? _buildImage(user.profileImageUrl, 68, 68)
                  : Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_pin_circle_rounded, size: 12, color: AppColors.themeColor),
                          SizedBox(width: 4),
                          Text(
                            'TENANT',
                            style: TextStyle(
                              color: AppColors.themeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isVerified ? Colors.green : Colors.amber.shade800).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isVerified ? 'NID Verified' : 'NID Pending',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isVerified ? Colors.green : Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  name.isNotEmpty ? name : 'Tenant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  user.mobile.isNotEmpty ? user.mobile : user.email,
                  style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[400] : _grey),
                ),
              ],
            ),
          ),

          // Edit Profile Action Button
          IconButton(
            onPressed: () => Navigator.pushNamed(context, MyProfileScreen.name),
            icon: const Icon(Icons.edit_outlined, color: AppColors.themeColor, size: 22),
            tooltip: l10n.myProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context, {
    required int demandCount,
    required int wishlistCount,
    required int completion,
    required bool isVerified,
    required bool isDark,
    required AppLocalizations l10n,
    required MainNavHolderProvider navProvider,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          icon: Icons.assignment_rounded,
          iconColor: Colors.orange,
          count: demandCount.toString(),
          label: l10n.myDemands,
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, MyDemandScreen.name),
        ),
        _buildMetricCard(
          icon: Icons.favorite_rounded,
          iconColor: Colors.redAccent,
          count: wishlistCount.toString(),
          label: l10n.savedProperties,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            navProvider.changeIndex(3);
          },
        ),
        _buildMetricCard(
          icon: Icons.donut_large_rounded,
          iconColor: Colors.blueAccent,
          count: '$completion%',
          label: l10n.profileCompletion,
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, MyProfileScreen.name),
        ),
        _buildMetricCard(
          icon: isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
          iconColor: isVerified ? Colors.teal : Colors.amber.shade800,
          count: isVerified ? '✓ Verified' : 'Pending',
          label: 'ভেরিফিকেশন স্ট্যাটাস',
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, MyProfileScreen.name),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2625) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF142321),
                  ),
                ),
              ],
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(
    BuildContext context,
    MainNavHolderProvider navProvider,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            icon: Icons.search_rounded,
            title: l10n.findHome,
            color: AppColors.themeColor,
            onTap: () {
              Navigator.pop(context);
              navProvider.changeIndex(1);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            icon: Icons.post_add_rounded,
            title: l10n.demand,
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              navProvider.changeIndex(2);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            icon: Icons.favorite_rounded,
            title: l10n.wishlist,
            color: Colors.redAccent,
            onTap: () {
              Navigator.pop(context);
              navProvider.changeIndex(3);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeaderWithAction({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DecoratedSectionHeader(title: title),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemandsList(
    BuildContext context,
    List<TenantDemandModel> demands,
    bool isDark,
    AppLocalizations l10n,
    TenantDemandFirestoreService demandService,
  ) {
    if (demands.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2625) : const Color(0xFFF9FBFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: Column(
          children: [
            const Icon(Icons.assignment_outlined, size: 48, color: _grey),
            const SizedBox(height: 10),
            Text(
              l10n.noDemandsYet,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'আপনার ভাড়ার প্রয়োজনীয়তা জানিয়ে চাহিদা পোস্ট করুন, বাড়িওয়ালারা সরাসরি যোগাযোগ করবে।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : _grey),
            ),
          ],
        ),
      );
    }

    final recentDemands = demands.take(3).toList();

    return Column(
      children: recentDemands.map((demand) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2625) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.orange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${demand.houseType.getLocalizedLabel(l10n)} (${demand.roomOrSeat})",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              "বাজেট: ${demand.budgetRange ?? '0'} ৳",
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.themeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${demand.area.name}, ${demand.district.name}",
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : _grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, ShowDemandDetailsScreen.name, arguments: demand);
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, EditDemandScreen.name, arguments: demand);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmDialog(context, demand.id, demandService, l10n),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWishlistPreview(
    BuildContext context,
    WishlistProvider wishlistProvider,
    bool isDark,
    AppLocalizations l10n,
    String userId,
  ) {
    final previewList = wishlistProvider.wishlistProperties.take(3).toList();

    if (previewList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2625) : const Color(0xFFF9FBFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'এখনো কোনো বাসা ফেভারিট করা হয়নি। বাসা খুঁজতে হোম স্ক্রিনে যান।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _grey),
          ),
        ),
      );
    }

    return Column(
      children: previewList.map((property) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2625) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: property.images.isNotEmpty
                    ? _buildImage(property.images.first, 52, 52)
                    : Container(color: Colors.grey[300], child: const Icon(Icons.home, color: Colors.grey)),
              ),
            ),
            title: Text(
              property.shortAddress.isNotEmpty ? property.shortAddress : property.houseType.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            subtitle: Text(
              "${property.amount} ৳ • ${property.area.name}, ${property.district.name}",
              style: const TextStyle(fontSize: 12, color: AppColors.themeColor, fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
              onPressed: () => wishlistProvider.toggleFavorite(userId, property.id),
            ),
            onTap: () {
              Navigator.pushNamed(context, PropertyDetailsScreen.name, arguments: property);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTenantActivityTimeline(
    UserModel user,
    int demandCount,
    int wishlistCount,
    bool isVerified,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2625) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildTimelineTile(
            icon: Icons.app_registration_rounded,
            iconColor: Colors.blueAccent,
            title: l10n.accountCreated,
            subtitle: 'যোগদান করেছেন: ${_formatTimestamp(user.createdAt)}',
            isLast: false,
          ),
          _buildTimelineTile(
            icon: Icons.assignment_rounded,
            iconColor: Colors.orange,
            title: '${l10n.myDemands}: $demandCount টি পোস্ট করা হয়েছে',
            subtitle: demandCount > 0
                ? 'আপনার চাহিদাসমূহ বাড়িওয়ালারা সরাসরি দেখতে পাচ্ছেন'
                : 'এখনো কোনো বাসা খোঁজার চাহিদা পোস্ট করা হয়নি',
            isLast: false,
          ),
          _buildTimelineTile(
            icon: Icons.favorite_rounded,
            iconColor: Colors.redAccent,
            title: '${l10n.savedProperties}: $wishlistCount টি বাসা পছন্দের তালিকায় রয়েছে',
            subtitle: 'আপনার সংরক্ষিত বাসাগুলো সুবিধাজনক সময়ে দেখতে পারবেন',
            isLast: false,
          ),
          _buildTimelineTile(
            icon: isVerified ? Icons.verified_rounded : Icons.shield_outlined,
            iconColor: isVerified ? Colors.green : Colors.amber.shade800,
            title: isVerified ? 'এনআইডি ভেরিফাইড ভাড়াটিয়া' : 'এনআইডি ভেরিফিকেশন পেন্ডিং',
            subtitle: isVerified
                ? 'আপনার জাতীয় পরিচয়পত্র যাচাই সম্পন্ন হয়েছে'
                : 'নির্ভরযোগ্যতা বাড়াতে প্রোফাইলে এনআইডি যুক্ত করুন',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: _grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    String demandId,
    TenantDemandFirestoreService demandService,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteDemandConfirmTitle),
        content: Text(l10n.deleteDemandConfirmSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await demandService.deleteDemand(demandId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.demandDeletedSuccess),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String src, double width, double height) {
    if (src.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
      );
    }
    if (src.startsWith('data:image') || src.startsWith('/9j/') || src.startsWith('iVBOR') || src.length > 255) {
      try {
        final Uint8List bytes = _base64Cache.putIfAbsent(src, () {
          final base64Str = src.contains(',') ? src.split(',').last : src;
          return base64Decode(base64Str.trim());
        });
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
        );
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
        ),
      );
    } else {
      try {
        if (src.length <= 255 && !kIsWeb && File(src).existsSync()) {
          return Image.file(
            File(src),
            width: width,
            height: height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
            ),
          );
        }
      } catch (_) {}
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.home_rounded, color: Colors.grey, size: 24),
      );
    }
  }

  String _formatTimestamp(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(isoDate);
      if (dt != null) {
        return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
      }
      return isoDate;
    } catch (_) {
      return isoDate;
    }
  }
}