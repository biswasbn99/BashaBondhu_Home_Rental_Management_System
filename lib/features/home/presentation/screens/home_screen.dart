import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../shared/data/services/property_firestore_service.dart';
import '../../../shared/presentation/providers/main_nav_holder_provider.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';
import '../../../shared/presentation/widgets/post_icon.dart';
import '../../../wishlist/data/providers/wishlist_provider.dart';
import '../../../ai_assistant/presentation/widgets/ai_floating_button.dart';
import '../../data/models/property_model.dart';
import '../widgets/property_card.dart';

enum PropertySortOption {
  newest,
  oldest,
  priceLowToHigh,
  priceHighToLow,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String name = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PropertyFirestoreService _firestoreService = PropertyFirestoreService();
  PropertySortOption _currentSort = PropertySortOption.newest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      context.read<WishlistProvider>().initialize(user?.uid ?? '');
    });
  }

  List<PropertyModel> _sortProperties(List<PropertyModel> properties) {
    final list = List<PropertyModel>.from(properties);
    switch (_currentSort) {
      case PropertySortOption.newest:
        list.sort((a, b) => b.postDate.compareTo(a.postDate));
        break;
      case PropertySortOption.oldest:
        list.sort((a, b) => a.postDate.compareTo(b.postDate));
        break;
      case PropertySortOption.priceLowToHigh:
        list.sort((a, b) {
          final priceA = int.tryParse(a.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final priceB = int.tryParse(b.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;
      case PropertySortOption.priceHighToLow:
        list.sort((a, b) {
          final priceA = int.tryParse(a.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final priceB = int.tryParse(b.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
    }
    return list;
  }

  String _getShortSortLabel(PropertySortOption sort, AppLocalizations l10n) {
    switch (sort) {
      case PropertySortOption.newest:
        return l10n.sortNewestShort;
      case PropertySortOption.oldest:
        return l10n.sortOldestShort;
      case PropertySortOption.priceLowToHigh:
        return l10n.sortPriceLowShort;
      case PropertySortOption.priceHighToLow:
        return l10n.sortPriceHighShort;
    }
  }

  PopupMenuItem<PropertySortOption> _buildPopupItem({
    required PropertySortOption option,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentSort == option;
    return PopupMenuItem<PropertySortOption>(
      value: option,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? AppColors.themeColor
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.themeColor
                    : (isDark ? Colors.grey[200] : const Color(0xFF2D3748)),
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.themeColor,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final bool isGuest = userProvider.isGuest;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: isGuest ? 12 : 20,
        actions: [
          if (isGuest)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: FreePostButton(),
            ),
          const LanguageActionButton(),
        ],
      ),
      floatingActionButton: const AIFloatingButton(),
      body: StreamBuilder<List<PropertyModel>>(
        stream: _firestoreService.streamAllProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            );
          }

          final properties = snapshot.data ?? [];
          final sortedProperties = _sortProperties(properties);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: sortedProperties.isEmpty ? 4 : sortedProperties.length + 3,
            itemBuilder: (context, index) {
              // Item 0: Banner
              if (index == 0) {
                return _buildBanners(context);
              }
              // Item 1: Spacer
              if (index == 1) {
                return const SizedBox(height: 20);
              }
              // Item 2: Header with sort dropdown
              if (index == 2) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.newest,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17.5,
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

                      // Modern Compact Anchored Sort Button
                      PopupMenuButton<PropertySortOption>(
                        initialValue: _currentSort,
                        onSelected: (PropertySortOption selected) {
                          setState(() {
                            _currentSort = selected;
                          });
                        },
                        offset: const Offset(0, 34),
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        color: isDark ? const Color(0xFF1E2827) : Colors.white,
                        itemBuilder: (BuildContext context) => [
                          _buildPopupItem(
                            option: PropertySortOption.newest,
                            icon: Icons.schedule_rounded,
                            label: l10n.sortNewestShort,
                            isDark: isDark,
                          ),
                          _buildPopupItem(
                            option: PropertySortOption.oldest,
                            icon: Icons.history_rounded,
                            label: l10n.sortOldestShort,
                            isDark: isDark,
                          ),
                          const PopupMenuDivider(height: 1),
                          _buildPopupItem(
                            option: PropertySortOption.priceLowToHigh,
                            icon: Icons.arrow_downward_rounded,
                            label: l10n.sortPriceLowShort,
                            isDark: isDark,
                          ),
                          _buildPopupItem(
                            option: PropertySortOption.priceHighToLow,
                            icon: Icons.arrow_upward_rounded,
                            label: l10n.sortPriceHighShort,
                            isDark: isDark,
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.themeColor.withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.themeColor.withValues(alpha: isDark ? 0.35 : 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentSort == PropertySortOption.newest
                                    ? Icons.schedule_rounded
                                    : _currentSort == PropertySortOption.oldest
                                        ? Icons.history_rounded
                                        : _currentSort == PropertySortOption.priceLowToHigh
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                size: 14,
                                color: AppColors.themeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getShortSortLabel(_currentSort, l10n),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.themeColor,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 16,
                                color: AppColors.themeColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Item 3+: Empty state or cards
              if (sortedProperties.isEmpty) {
                return _buildEmptyState(context);
              }

              final p = sortedProperties[index - 3];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PropertyCard(property: p),
              );
            },
          );
        },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to Demand tab (Index 2)
          context.read<MainNavHolderProvider>().changeIndex(2);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A1C16) : const Color(0xFFFDEDE3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.deepOrange.withValues(alpha: 0.3)
                  : Colors.deepOrange.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.campaign_rounded,
                          color: Colors.deepOrange,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.bannerTitle,
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.bannerSubtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark ? Colors.grey[300] : const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: isDark ? 0.25 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.deepOrange,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
