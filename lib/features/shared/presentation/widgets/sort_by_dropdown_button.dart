import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:flutter/material.dart';
import 'filter_dropdown.dart';

class SortByDropdown extends StatelessWidget {
  const SortByDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SortBy value;
  final ValueChanged<SortBy?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<SortBy>(
      hint: l10n.sortBy,
      value: value,
      items: SortBy.values
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s.getLocalizedLabel(l10n)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
