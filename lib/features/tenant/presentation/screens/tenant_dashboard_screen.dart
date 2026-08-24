import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/models/user_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/my_profile_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_network_image.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/my_demand_screen.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';

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
    final navProvider = context.read<MainNavHolderProvider>();

    final UserModel user = userProvider.user ??
        UserModel(
          uid: 'sample_tenant',
          email: 'tenant@bashabondhu.com',
          firstName: 'Tenant',
          lastName: 'User',
          userType: 'Tenant',
          mobile: '01712345678',
          city: 'Dhaka',
          createdAt: DateTime.now().toIso8601String(),
        );

    final int completion = user.profileCompletionPercentage;
    final bool isVerified = user.nidFrontImageUrl.isNotEmpty;

    return Scaffold(
      appBar: MainAppBar(
        title: Text(l10n.myDashboard),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                demandCount: 3,
                wishlistCount: 2,
                completion: completion,
                isVerified: isVerified,
                isDark: isDark,
                l10n: l10n,
                navProvider: navProvider,
              ),
              const SizedBox(height: 18),

              // 3. Move-in & Relocation Tips Banner
              _buildRelocationBanner(context, isDark, l10n),
              const SizedBox(height: 24),

              // 4. Quick Actions Hub
              DecoratedSectionHeader(title: l10n.quickShortcuts),
              const SizedBox(height: 12),
              _buildQuickActionsRow(context, navProvider, l10n),
              const SizedBox(height: 24),

              // 5. My Rental Demands Section
              _buildSectionHeaderWithAction(
                title: l10n.recentDemands,
                actionLabel: l10n.viewAll,
                onAction: () => Navigator.pushNamed(context, MyDemandScreen.name),
              ),
              const SizedBox(height: 12),
              _buildSampleDemandsList(context, isDark, l10n),
              const SizedBox(height: 24),

              // 6. Saved Properties / Wishlist Preview
              _buildSectionHeaderWithAction(
                title: l10n.savedProperties,
                actionLabel: l10n.viewAll,
                onAction: () {
                  Navigator.pop(context);
                  navProvider.changeIndex(3);
                },
              ),
              const SizedBox(height: 12),
              _buildSampleWishlistPreview(context, isDark, l10n, navProvider),
              const SizedBox(height: 24),

              // 7. Tenant Activity & History Timeline
              DecoratedSectionHeader(title: l10n.activityHistory),
              const SizedBox(height: 12),
              _buildTenantActivityTimeline(
                user,
                demandCount: 3,
                wishlistCount: 2,
                isVerified: isVerified,
                isDark: isDark,
                l10n: l10n,
              ),
            ],
          ),
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
                  ? AppImageWidget(
                      imageSource: user.profileImageUrl,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      cacheWidth: 150,
                      cacheHeight: 150,
                    )
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
                        isVerified ? l10n.nidVerified : l10n.nidPending,
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
          label: l10n.verificationStatus,
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

  Widget _buildRelocationBanner(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2415), const Color(0xFF382F18)]
              : [const Color(0xFFFFF9E6), const Color(0xFFFFF1CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.localeName == 'bn' ? 'মুভ-ইন চেকলিস্ট ও সহায়তা' : 'Move-in Assistant & Checklist',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.localeName == 'bn'
                      ? 'নতুন বাসায় ওঠার আগে মিটার রিডিং, চুক্তিপত্র ও চাবি বুঝে নিন।'
                      : 'Ensure utility checks, agreement signing, and keys handover before moving.',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildSampleDemandsList(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2625) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
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
                          l10n.localeName == 'bn' ? 'ফ্যামিলি ফ্ল্যাট (২ বেড)' : 'Family Flat (2 Bed)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          "${l10n.budgetLabel}: 18,000 ৳",
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.localeName == 'bn' ? 'উত্তরা, ঢাকা' : 'Uttara, Dhaka',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : _grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, MyDemandScreen.name),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: Text(l10n.myDemands, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleWishlistPreview(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
    MainNavHolderProvider navProvider,
  ) {
    return Material(
      color: isDark ? const Color(0xFF1E2625) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(context);
          navProvider.changeIndex(3);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.localeName == 'bn' ? 'সংরক্ষিত বাসার তালিকা দেখুন' : 'View Saved Wishlist Properties',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.localeName == 'bn' ? '২টি পছন্দের বাসা সংরক্ষিত আছে' : '2 saved properties in your wishlist',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : _grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTenantActivityTimeline(
    UserModel user, {
    required int demandCount,
    required int wishlistCount,
    required bool isVerified,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
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
            subtitle: '${l10n.joinedOn}: ${_formatTimestamp(user.createdAt)}',
            isLast: false,
          ),
          _buildTimelineTile(
            icon: Icons.assignment_rounded,
            iconColor: Colors.orange,
            title: '${l10n.myDemands}: $demandCount',
            subtitle: l10n.localeName == 'bn' ? 'আপনার চাহিদাসমূহ সক্রিয় রয়েছে' : 'Your demands are active and visible',
            isLast: false,
          ),
          _buildTimelineTile(
            icon: Icons.favorite_rounded,
            iconColor: Colors.redAccent,
            title: '${l10n.savedProperties}: $wishlistCount',
            subtitle: l10n.localeName == 'bn' ? 'আপনার সংরক্ষিত বাসাগুলো সুবিধাজনক সময়ে দেখতে পারবেন' : 'Access your saved homes anytime',
            isLast: false,
          ),
          _buildTimelineTile(
            icon: isVerified ? Icons.verified_rounded : Icons.shield_outlined,
            iconColor: isVerified ? Colors.green : Colors.amber.shade800,
            title: isVerified ? l10n.verifiedTenant : l10n.nidPending,
            subtitle: isVerified
                ? (l10n.localeName == 'bn' ? 'আপনার জাতীয় পরিচয়পত্র যাচাই সম্পন্ন হয়েছে' : 'Your National ID has been verified')
                : (l10n.localeName == 'bn' ? 'নির্ভরযোগ্যতা বাড়াতে প্রোফাইলে এনআইডি যুক্ত করুন' : 'Upload NID to boost credibility and trust'),
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