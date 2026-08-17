import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class MonthDropdown extends StatelessWidget {
  const MonthDropdown({
    super.key,
    required this.value,
    required this.months,
    required this.onChanged,
  });

  final String? value;
  final List<String> months;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterDropdown<String>(
      hint: context.localizations.month,
      value: value,
      items: months
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
