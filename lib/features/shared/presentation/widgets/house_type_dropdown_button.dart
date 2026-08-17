import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class HouseTypeDropdown extends StatelessWidget {
  const HouseTypeDropdown({
    super.key,
    required this.value,
    required this.houseTypes,
    required this.onChanged,
  });

  final HouseType? value;
  final List<HouseType> houseTypes;
  final ValueChanged<HouseType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<HouseType>(
      hint: l10n.houseType,
      value: value,
      items: houseTypes
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(t.getLocalizedLabel(l10n)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
