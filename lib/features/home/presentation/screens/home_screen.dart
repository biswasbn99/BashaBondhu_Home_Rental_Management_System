import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../shared/data/services/property_firestore_service.dart';
import '../../../shared/presentation/providers/main_nav_holder_provider.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/post_icon.dart';
import '../../../wishlist/data/providers/wishlist_provider.dart';
import '../../data/models/property_model.dart';
import '../widgets/property_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String name = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PropertyFirestoreService _firestoreService = PropertyFirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      context.read<WishlistProvider>().initialize(user?.uid ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bool isGuest = userProvider.isGuest;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: isGuest ? 12 : 20,
        actions: isGuest
            ? [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FreePostButton(),
                ),
              ]
            : null,
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: _firestoreService.streamAllProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            );
          }

          final properties = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // --- Interactive Promo Banners ---
              _buildBanners(context),
              const SizedBox(height: 20),

              // --- Search Bar Shortcut ---
              _buildSearchShortcut(context),
              const SizedBox(height: 20),

              // --- Newest Listings Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.newest,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${properties.length}',
                          style: const TextStyle(
                            color: AppColors.themeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to Find Home tab (Index 1)
                      context.read<MainNavHolderProvider>().changeIndex(1);
                    },
                    child: Text(
                      l10n.findHome,
                      style: const TextStyle(color: AppColors.themeColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Property Cards List / Empty State ---
              if (properties.isEmpty)
                _buildEmptyState(context)
              else
                ...properties.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PropertyCard(property: p),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchShortcut(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        context.read<MainNavHolderProvider>().changeIndex(1);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.themeColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${l10n.findHome}... (${l10n.division}, ${l10n.district}, ${l10n.area})',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.themeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_work_outlined,
              size: 56,
              color: AppColors.themeColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'এখনো কোনো বাসাভাড়া বিজ্ঞাপন নেই',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'শীঘ্রই নতুন বাসাভাড়ার বিজ্ঞাপন যুক্ত হবে অথবা বাড়িওয়ালা হিসেবে পোস্ট করুন।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanners(BuildContext context) {
    final l10n = context.localizations;
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _BannerItem(
            color: const Color(0xFFFDEDE3),
            title: l10n.bannerTitle,
            subtitle: l10n.bannerSubtitle,
            icon: Icons.support_agent,
            textColor: Colors.deepOrange,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _BannerItem(
            color: AppColors.themeColor.withValues(alpha: 0.1),
            title: l10n.postFree,
            subtitle: l10n.postSubtitle,
            icon: Icons.add_home_work_outlined,
            textColor: AppColors.themeColor,
            onTap: () {
              final userProvider = context.read<UserProvider>();
              if (userProvider.user?.userType == 'House Owner') {
                context.read<MainNavHolderProvider>().changeIndex(1);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _BannerItem extends StatelessWidget {
  const _BannerItem({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.textColor,
    this.onTap,
  });

  final Color color;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: textColor, size: 30),
          ],
        ),
      ),
    );
  }
}
