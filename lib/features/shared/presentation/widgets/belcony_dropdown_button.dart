import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class BalconyDropdown extends StatelessWidget {
  const BalconyDropdown({
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
      hint: l10n.balcony,
      value: value,
      isRequired: false,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.balcony)),
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
