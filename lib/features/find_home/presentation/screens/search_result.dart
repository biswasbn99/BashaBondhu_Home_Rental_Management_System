import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../home/data/models/property_model.dart';
import '../../../home/presentation/widgets/property_card.dart';
import '../../../shared/data/models/search_filter_model.dart';
import '../../../shared/data/services/property_firestore_service.dart';
import '../../../shared/presentation/widgets/app_bar.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({super.key, required this.filter});

  final SearchFilterModel filter;

  bool _matchesBudget(String propertyAmount, String budgetRange) {
    final cleanedAmount = int.tryParse(propertyAmount.replaceAll(RegExp(r'[^0-9]'), ''));
    if (cleanedAmount == null) return true;

    if (budgetRange.contains('+')) {
      final minStr = budgetRange.replaceAll(RegExp(r'[^0-9]'), '');
      final min = int.tryParse(minStr) ?? 50000;
      return cleanedAmount >= min;
    }

    final parts = budgetRange.split('-');
    if (parts.length == 2) {
      final min = int.tryParse(parts[0].trim()) ?? 0;
      final max = int.tryParse(parts[1].trim()) ?? 9999999;
      return cleanedAmount >= min && cleanedAmount <= max;
    }

    final single = int.tryParse(budgetRange.replaceAll(RegExp(r'[^0-9]'), ''));
    if (single != null) {
      return cleanedAmount <= single;
    }

    return true;
  }

  bool _matchesFilter(PropertyModel property) {
    // 1. Division check (Required)
    if (property.division.id.isNotEmpty && filter.division.id.isNotEmpty) {
      if (property.division.id.toLowerCase() != filter.division.id.toLowerCase()) {
        return false;
      }
    }

    // 2. District check (Required)
    if (property.district.id.isNotEmpty && filter.district.id.isNotEmpty) {
      if (property.district.id.toLowerCase() != filter.district.id.toLowerCase()) {
        return false;
      }
    }

    // 3. Upazila/Area check (Required)
    if (property.area.id.isNotEmpty && filter.upazila.id.isNotEmpty) {
      if (property.area.id.toLowerCase() != filter.upazila.id.toLowerCase()) {
        return false;
      }
    }

    // 4. Sub-Area check (Required if post has sub-area)
    if (filter.area != null && property.subArea != null) {
      if (property.subArea!.id.isNotEmpty && filter.area!.id.isNotEmpty) {
        if (property.subArea!.id.toLowerCase() != filter.area!.id.toLowerCase()) {
          return false;
        }
      }
    }

    // 5. Month check (Required)
    if (filter.month.isNotEmpty &&
        property.month.toLowerCase() != filter.month.toLowerCase()) {
      return false;
    }

    // 6. House Type check (Required)
    if (property.houseType != filter.houseType) {
      return false;
    }

    // 7. Tenant Type check
    if (filter.tenantType != null && property.tenantType != null) {
      if (property.tenantType != filter.tenantType) {
        return false;
      }
    }

    // 8. Budget Range check
    if (filter.budgetRange != null && !_matchesBudget(property.amount, filter.budgetRange!)) {
      return false;
    }

    // --- Optional Checks ---

    // 9. Optional Room/Seat check
    if (filter.roomOrSeat != null && filter.roomOrSeat!.isNotEmpty) {
      if (property.roomOrSeat.toLowerCase() != filter.roomOrSeat!.toLowerCase()) {
        return false;
      }
    }

    // 10. Optional Bathroom check
    if (filter.bathrooms != null) {
      final totalBaths = (property.attachedBathrooms ?? 0) + (property.commonBathrooms ?? 0);
      if (totalBaths < filter.bathrooms!) {
        return false;
      }
    }

    // 11. Optional Balconies filter
    if (filter.balconies != null && (property.balconies ?? 0) < filter.balconies!) {
      return false;
    }

    // 12. Optional Floor filter
    if (filter.floorNumber != null && property.floorNumber != filter.floorNumber) {
      return false;
    }

    // 13. Optional Parking filter
    if (filter.hasParking != null && property.hasParking != filter.hasParking) {
      return false;
    }

    // 14. Optional Lift filter
    if (filter.hasLift != null && property.hasLift != filter.hasLift) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final service = PropertyFirestoreService();

    final locationSummary = [
      if (filter.area != null) filter.area!.getLocalizedName(languageCode),
      filter.upazila.getLocalizedName(languageCode),
      filter.district.getLocalizedName(languageCode),
    ].join(', ');

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.searchResult,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: service.streamAllProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            );
          }

          final allProperties = snapshot.data ?? [];
          final results = allProperties.where(_matchesFilter).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Search Query Summary Bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.themeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_searching_rounded, color: AppColors.themeColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$locationSummary • ${filter.houseType.getLocalizedLabel(l10n)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${l10n.month}: ${filter.month}${filter.tenantType != null ? " • ${filter.tenantType!.getLocalizedLabel(l10n)}" : ""}${filter.budgetRange != null ? " • ৳ ${filter.budgetRange}" : ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${results.length} পাওয়া গেছে',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (results.isEmpty)
                _buildNoResults(context, l10n)
              else
                ...results.map(
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

  Widget _buildNoResults(BuildContext context, dynamic l10n) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'কোনো ফলাফল মেলেনি',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'আপনার ফিল্টার অনুযায়ী বর্তমানে কোনো বাসাভাড়া পাওয়া যায়নি। অন্য এলাকা বা বাজেট দিয়ে আবার অনুসন্ধান করুন।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.themeColor),
              foregroundColor: AppColors.themeColor,
            ),
            child: const Text('ফিল্টার পরিবর্তন করুন'),
          ),
        ],
      ),
    );
  }
}