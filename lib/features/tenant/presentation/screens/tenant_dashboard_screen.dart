import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../home/presentation/screens/property_details_screen.dart';
import '../../../shared/data/services/tenant_demand_firestore_service.dart';
import '../../../shared/presentation/providers/main_nav_holder_provider.dart';
import '../../../shared/presentation/screens/my_profile_screen.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/decorated_section_header.dart';
import '../../../wishlist/data/providers/wishlist_provider.dart';
import '../../data/models/tenant_demand_model.dart';
import 'edit_demand_screen.dart';
import 'my_demand_screen.dart';
import 'show_demand_details_screen.dart';

class TenantDashboardScreen extends StatelessWidget {
  static const String name = '/tenant-dashboard';

  const TenantDashboardScreen({super.key});

  static const Color _grey = Color(0xFF7A8A88);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final UserModel? user = userProvider.user;
    final wishlistProvider = context.watch<WishlistProvider>();
    final navProvider = context.read<MainNavHolderProvider>();
    final demandService = TenantDemandFirestoreService();

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

    final String tenantId = user.uid;
    final String tenantEmail = user.email;

    return Scaffold(
      appBar: MainAppBar(
        title: Text(l10n.myDashboard),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<TenantDemandModel>>(
          stream: demandService.streamTenantDemands(tenantId, tenantEmail: tenantEmail),
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
                    // 1. Top Tenant Profile Overview Header
                    _buildProfileHeader(context, user, theme, isDark, l10n, completion, isVerified),
                    const SizedBox(height: 18),

                    // 2. Key Metrics Grid (4 Cards)
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

                    // 4. Recent Demands Section
                    _buildSectionHeaderWithAction(
                      title: l10n.recentDemands,
                      actionLabel: l10n.viewAll,
                      onAction: () => Navigator.pushNamed(context, MyDemandScreen.name),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentDemandsList(context, demands, isDark, l10n, demandService),
                    const SizedBox(height: 24),

                    // 5. Saved Houses / Wishlist Preview
                    if (wishlistProvider.wishlistProperties.isNotEmpty) ...[
                      _buildSectionHeaderWithAction(
                        title: l10n.savedProperties,
                        actionLabel: l10n.viewAll,
                        onAction: () => navProvider.changeIndex(3),
                      ),
                      const SizedBox(height: 12),
                      _buildWishlistPreview(context, wishlistProvider, isDark, l10n),
                      const SizedBox(height: 24),
                    ],

                    // 6. Activity & History Timeline
                    DecoratedSectionHeader(title: l10n.activityHistory),
                    const SizedBox(height: 12),
                    _buildActivityHistoryTimeline(user, demandCount, wishlistCount, isVerified, isDark, l10n),
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
                        color: const Color(0xFF028090).withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_rounded, size: 12, color: Color(0xFF028090)),
                          const SizedBox(width: 4),
                          Text(
                            l10n.verifiedTenant.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF028090),
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
                  name.isNotEmpty ? name : 'Tenant User',
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
          icon: Icons.post_add_rounded,
          iconColor: Colors.orange,
          count: demandCount.toString(),
          label: l10n.activeDemands,
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, MyDemandScreen.name),
        ),
        _buildMetricCard(
          icon: Icons.favorite_rounded,
          iconColor: Colors.redAccent,
          count: wishlistCount.toString(),
          label: l10n.savedHouses,
          isDark: isDark,
          onTap: () => navProvider.changeIndex(3),
        ),
        _buildMetricCard(
          icon: Icons.pie_chart_rounded,
          iconColor: completion == 100 ? Colors.green : AppColors.themeColor,
          count: '$completion%',
          label: l10n.profileCompletion,
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, MyProfileScreen.name),
        ),
        _buildMetricCard(
          icon: isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
          iconColor: isVerified ? Colors.teal : Colors.amber.shade800,
          count: isVerified ? '✓ Verified' : 'Pending',
          label: 'NID Status',
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2625) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
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
            title: l10n.postDemand,
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
            icon: Icons.favorite_border_rounded,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: const TextStyle(
                  color: AppColors.themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.themeColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDemandsList(
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
            const Icon(Icons.assignment_late_outlined, size: 40, color: _grey),
            const SizedBox(height: 8),
            Text(
              l10n.noDemandsYet,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'আপনার প্রয়োজনীয় বাসাভাড়ার চাহিদা পোস্ট করে বাড়িওয়ালাদের সাথে সহজে যুক্ত হন।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : _grey),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.read<MainNavHolderProvider>().changeIndex(2);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.postNewDemand),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2625) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      demand.month,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.themeColor,
                      ),
                    ),
                  ),
                  Text(
                    "${demand.budgetRange ?? '0'} ৳",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${demand.houseType.getLocalizedLabel(l10n)} • ${demand.roomOrSeat}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: _grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${demand.area.name}, ${demand.district.name}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : _grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
  ) {
    final previewList = wishlistProvider.wishlistProperties.take(3).toList();

    return Column(
      children: previewList.map((property) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2625) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: property.images.isNotEmpty
                    ? _buildImage(property.images.first, 60, 60)
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.home_work_outlined, color: Colors.grey),
                      ),
              ),
            ),
            title: Text(
              property.shortAddress.isNotEmpty ? property.shortAddress : property.houseType.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            subtitle: Text(
              "${property.amount} ৳ • ${property.area.name}",
              style: const TextStyle(fontSize: 12, color: AppColors.themeColor, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _grey),
            onTap: () {
              Navigator.pushNamed(context, PropertyDetailsScreen.name, arguments: property);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityHistoryTimeline(
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
          _buildTimelineItem(
            icon: Icons.account_circle_rounded,
            iconColor: AppColors.themeColor,
            title: l10n.accountCreated,
            subtitle: 'বাসাবন্ধু অ্যাকাউন্টে সফলভাবে যুক্ত হয়েছেন',
            timestamp: _formatTimestamp(user.createdAt),
          ),
          const Divider(height: 20),
          _buildTimelineItem(
            icon: Icons.post_add_rounded,
            iconColor: Colors.orange,
            title: '${l10n.activeDemands}: $demandCount টি',
            subtitle: demandCount > 0
                ? 'আপনার চাহিদাসমূহ বাড়িওয়ালাদের ড্যাশবোর্ডে দৃশ্যমান আছে'
                : 'এখনো কোনো চাহিদা পোস্ট করেননি',
            timestamp: 'লাইভ অ্যাক্টিভিটি',
          ),
          const Divider(height: 20),
          _buildTimelineItem(
            icon: Icons.favorite_rounded,
            iconColor: Colors.redAccent,
            title: '${l10n.savedProperties}: $wishlistCount টি',
            subtitle: 'পছন্দের তালিকায় সংরক্ষিত বাসাগুলো সহজেই খুঁজে পান',
            timestamp: 'আপডেট করা হয়েছে',
          ),
          const Divider(height: 20),
          _buildTimelineItem(
            icon: isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
            iconColor: isVerified ? Colors.green : Colors.amber.shade800,
            title: isVerified ? 'এনআইডি ভেরিফাইড' : 'এনআইডি ভেরিফিকেশন পেন্ডিং',
            subtitle: isVerified
                ? 'আপনার প্রোফাইল ট্রাস্টেড ও ভেরিফাইড'
                : 'এনআইডি ছবি আপলোড করে প্রোফাইল ১০০% সম্পন্ন করুন',
            timestamp: isVerified ? 'সম্পূর্ণ' : 'অসম্পূর্ণ',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String timestamp,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          radius: 16,
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  Text(timestamp, style: const TextStyle(fontSize: 11, color: _grey)),
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: _grey)),
            ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(l10n.deleteDemandConfirmTitle),
          ],
        ),
        content: Text(l10n.deleteDemandConfirmSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await demandService.deleteDemand(demandId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.demandDeletedSuccess),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.redAccent),
                  );
                }
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
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image_rounded, size: 24),
      );
    }
    if (src.startsWith('data:image')) {
      try {
        final base64Str = src.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 24)),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image_rounded, size: 24));
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 24)),
      );
    } else {
      return Image.file(
        File(src),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 24)),
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