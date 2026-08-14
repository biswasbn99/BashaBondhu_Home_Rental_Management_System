import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({super.key, required this.filter});

  final SearchFilterModel filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: const MainAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.accommodationPromptTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _row(l10n.month, filter.month),
            _row(l10n.houseType, filter.houseType.getLocalizedLabel(l10n)),
            _row(l10n.division, filter.division.getLocalizedName(languageCode)),
            _row(l10n.district, filter.district.getLocalizedName(languageCode)),
            _row(l10n.upazila, filter.upazila.getLocalizedName(languageCode)),
            if (filter.area != null)
              _row(l10n.area, filter.area!.getLocalizedName(languageCode)),
            _row(l10n.roomOrSeat, filter.roomOrSeat),
            if (filter.budgetRange != null)
              _row(l10n.budget, filter.budgetRange!),
            if (filter.tenantType != null)
              _row(l10n.tenantType, filter.tenantType!.getLocalizedLabel(l10n)),
            if (filter.bathrooms != null)
              _row(l10n.bathroom, filter.bathrooms.toString()),
            if (filter.balconies != null)
              _row(l10n.balcony, filter.balconies.toString()),
            if (filter.floorNumber != null)
              _row(l10n.floorNumber, filter.floorNumber.toString()),
            if (filter.hasLift != null)
              _row(l10n.lift, filter.hasLift! ? l10n.available : l10n.unavailable),
            if (filter.hasParking != null)
              _row(l10n.parking, filter.hasParking! ? l10n.available : l10n.unavailable),
            _row(l10n.sortBy, filter.sortBy.getLocalizedLabel(l10n)),
           
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'এই ফিল্টার অনুযায়ী পোস্টগুলো এখানে দেখানো হবে।',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}