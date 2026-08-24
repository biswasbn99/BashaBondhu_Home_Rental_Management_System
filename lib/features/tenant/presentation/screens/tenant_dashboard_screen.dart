import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/models/user_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/my_profile_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/my_demand_screen.dart';

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
              // 1. Tenant Profile Overview Header
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
                          colors: [Color(0xFF028090), Color(0xFF00A896)],
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
                                child: const Text(
                                  'TENANT',
                                  style: TextStyle(color: AppColors.themeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
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
                      icon: Icons.assignment_rounded,
                      iconColor: Colors.orange,
                      count: '3',
                      label: l10n.myDemands,
                      isDark: isDark,
                      onTap: () => Navigator.pushNamed(context, MyDemandScreen.name),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.favorite_rounded,
                      iconColor: Colors.redAccent,
                      count: '2',
                      label: l10n.savedProperties,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        navProvider.changeIndex(3);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.donut_large_rounded,
                      iconColor: Colors.blueAccent,
                      count: '${user.profileCompletionPercentage}%',
                      label: l10n.profileCompletion,
                      isDark: isDark,
                      onTap: () => Navigator.pushNamed(context, MyProfileScreen.name),
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

              // 3. Move-in & Relocation Tips Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2A2415), const Color(0xFF382F18)]
                        : [const Color(0xFFFFF9E6), const Color(0xFFFFF1CC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: Colors.orange, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.localeName == 'bn' ? 'মুভ-ইন চেকলিস্ট ও সহায়তা' : 'Move-in Assistant & Checklist',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          Text(
                            l10n.localeName == 'bn'
                                ? 'নতুন বাসায় ওঠার আগে মিটার রিডিং ও চুক্তিপত্র বুঝে নিন।'
                                : 'Ensure utility checks and agreement signing before moving.',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                          ),
                        ],
                      ),
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
              ),
              const SizedBox(height: 24),

              // 5. My Demands Preview
              _buildSectionHeader(
                title: l10n.recentDemands,
                actionLabel: l10n.viewAll,
                onAction: () => Navigator.pushNamed(context, MyDemandScreen.name),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.localeName == 'bn' ? 'ফ্যামিলি ফ্ল্যাট (২ বেড)' : 'Family Flat (2 Bed)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${l10n.budgetLabel}: 18,000 ৳ • ${l10n.localeName == 'bn' ? 'উত্তরা' : 'Uttara'}",
                            style: const TextStyle(fontSize: 12, color: AppColors.themeColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, MyDemandScreen.name),
                      child: Text(l10n.viewAction, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Saved Properties / Wishlist Preview
              _buildSectionHeader(
                title: l10n.savedProperties,
                actionLabel: l10n.viewAll,
                onAction: () {
                  Navigator.pop(context);
                  navProvider.changeIndex(3);
                },
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
                  onTap: () {
                    Navigator.pop(context);
                    navProvider.changeIndex(3);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.localeName == 'bn' ? 'সংরক্ষিত পছন্দের বাসা' : 'Saved Favorite Properties',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.localeName == 'bn' ? '২টি পছন্দের বাসা সেভ করা আছে' : '2 properties in your wishlist',
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
                      icon: Icons.assignment_rounded,
                      color: Colors.orange,
                      title: '${l10n.myDemands}: 3',
                      subtitle: l10n.localeName == 'bn' ? 'আপনার চাহিদাসমূহ সক্রিয় রয়েছে' : 'Your demands are active',
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
        Expanded(child: DecoratedSectionHeader(title: title)),
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