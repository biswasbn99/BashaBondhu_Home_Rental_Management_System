import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';
import 'filter_dropdown.dart';

class BathroomDropdown extends StatelessWidget {
  const BathroomDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<int>(
      hint: l10n.bathroom,
      value: value,
      isRequired: false,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.bathroom)),
        ...List.generate(5, (i) => i + 1).map(
          (i) => DropdownMenuItem(
            value: i,
            child: Text(i.toString()),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
