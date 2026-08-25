import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/models/user_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/screens/home_rent_post_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/presentation/screens/my_post_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/my_profile_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/tenant_demand_show_screen.dart';

class HouseOwnerDashboardScreen extends StatelessWidget {
  static const String name = '/house-owner-dashboard';

  const HouseOwnerDashboardScreen({super.key});

  static const Color _grey = Color(0xFF7A8A88);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);

    final UserModel user = userProvider.user ??
        UserModel(
          uid: 'sample_owner',
          email: 'owner@bashabondhu.com',
          firstName: 'House',
          lastName: 'Owner',
          userType: 'House Owner',
          mobile: '01712345678',
          city: 'Dhaka',
          createdAt: DateTime.now().toIso8601String(),
        );

    final String name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();
    final String initials = user.initials;
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
              // 1. Host Profile Overview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00A896), Color(0xFF028090)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.themeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.verifiedHost.toUpperCase(),
                                  style: const TextStyle(color: AppColors.themeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isVerified ? l10n.nidVerified : l10n.nidPending,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isVerified ? Colors.green : Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(user.mobile.isNotEmpty ? user.mobile : user.email, style: const TextStyle(fontSize: 12, color: _grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.themeColor),
                      onPressed: () => Navigator.pushNamed(context, MyProfileScreen.name),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Metrics (2x2 Grid using Row/Column)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.apartment_rounded,
                      iconColor: AppColors.themeColor,
                      count: '2',
                      label: l10n.totalListings,
                      isDark: isDark,
                      onTap: () => Navigator.pushNamed(context, MyPostScreen.name),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: Colors.green,
                      count: '1',
                      label: l10n.availableUnits,
                      isDark: isDark,
                      onTap: () => Navigator.pushNamed(context, MyPostScreen.name),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.people_outline_rounded,
                      iconColor: Colors.purple,
                      count: '5',
                      label: l10n.allTenantDemands,
                      isDark: isDark,
                      onTap: () => Navigator.pushNamed(context, TenantDemandShowScreen.name),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                      iconColor: isVerified ? Colors.teal : Colors.amber.shade800,
                      count: isVerified ? '✓' : 'Pending',
                      label: l10n.verificationStatus,
                      isDark: isDark,
                      onTap: () => Navigator.pushNamed(context, MyProfileScreen.name),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. Boost Promo Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F3B36), const Color(0xFF164E46)]
                        : [const Color(0xFFE6F7F5), const Color(0xFFD0F0EC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch_rounded, color: AppColors.themeColor, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.boostListing, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          Text(
                            l10n.localeName == 'bn' ? 'বিজ্ঞাপন বুস্ট করে দ্রুত ভাড়াটিয়া পান।' : 'Promote listing to get faster inquiries.',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.localeName == 'bn' ? 'বুস্টিং ফিচারটি শীঘ্রই চালু হবে।' : 'Boost feature coming soon.'),
                            backgroundColor: AppColors.themeColor,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(l10n.localeName == 'bn' ? 'বুস্ট' : 'Boost', style: const TextStyle(fontSize: 11.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Quick Actions Hub
              DecoratedSectionHeader(title: l10n.quickShortcuts),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.add_home_rounded,
                      title: l10n.homeRentPost,
                      color: AppColors.themeColor,
                      onTap: () => Navigator.pushNamed(context, HomeRentPostScreen.name),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.list_alt_rounded,
                      title: l10n.myPost,
                      color: Colors.blueAccent,
                      onTap: () => Navigator.pushNamed(context, MyPostScreen.name),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.campaign_rounded,
                      title: l10n.allTenantDemands,
                      color: Colors.purple,
                      onTap: () => Navigator.pushNamed(context, TenantDemandShowScreen.name),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. My Listings Preview
              _buildSectionHeader(
                title: l10n.myPost,
                actionLabel: l10n.viewAll,
                onAction: () => Navigator.pushNamed(context, MyPostScreen.name),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2625) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: AppColors.themeColor, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.localeName == 'bn' ? 'ফ্যামিলি ফ্ল্যাট বাসা' : 'Family Flat Apartment',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "22,000 ৳ / ${l10n.monthUnit} • ${l10n.localeName == 'bn' ? 'মিরপুর ১০' : 'Mirpur 10'}",
                            style: const TextStyle(fontSize: 12, color: AppColors.themeColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, MyPostScreen.name),
                      child: Text(l10n.viewAction, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Tenant Demands Radar Preview
              _buildSectionHeader(
                title: l10n.marketDemandsRadar,
                actionLabel: l10n.viewAll,
                onAction: () => Navigator.pushNamed(context, TenantDemandShowScreen.name),
              ),
              const SizedBox(height: 10),
              Material(
                color: isDark ? const Color(0xFF1E2625) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pushNamed(context, TenantDemandShowScreen.name),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple.withValues(alpha: 0.12),
                          child: const Icon(Icons.person_search_rounded, color: Colors.purple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.localeName == 'bn' ? 'ফ্যামিলি বাসা খুঁজছেন (৩ রুম)' : 'Looking for Family House (3 Rooms)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${l10n.localeName == 'bn' ? 'মিরপুর, ঢাকা' : 'Mirpur, Dhaka'} • ${l10n.budgetLabel}: 25,000 ৳",
                                style: const TextStyle(fontSize: 11.5, color: _grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 7. Activity Timeline
              DecoratedSectionHeader(title: l10n.activityHistory),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2625) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildTimelineRow(
                      icon: Icons.app_registration_rounded,
                      color: Colors.blueAccent,
                      title: l10n.accountCreated,
                      subtitle: '${l10n.joinedOn}: ${user.createdAt.split('T').first}',
                    ),
                    const Divider(height: 16),
                    _buildTimelineRow(
                      icon: Icons.apartment_rounded,
                      color: AppColors.themeColor,
                      title: '${l10n.totalListings}: 2 (1 ${l10n.availableUnits})',
                      subtitle: l10n.localeName == 'bn' ? 'আপনার পোস্ট সক্রিয় রয়েছে' : 'Your listings are active',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
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
                Icon(icon, color: iconColor, size: 20),
                Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String actionLabel, required VoidCallback onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DecoratedSectionHeader(title: title),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const Icon(Icons.arrow_forward_ios_rounded, size: 11),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: _grey)),
            ],
          ),
        ),
      ],
    );
  }
}