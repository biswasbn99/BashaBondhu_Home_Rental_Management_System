import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';
import 'filter_dropdown.dart';

class ParkingDropdown extends StatelessWidget {
  const ParkingDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<bool>(
      hint: l10n.parking,
      value: value,
      isRequired: false,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.parking)),
        DropdownMenuItem(value: true, child: Text(l10n.available)),
        DropdownMenuItem(value: false, child: Text(l10n.unavailable)),
      ],
      onChanged: onChanged,
    );
  }
}
