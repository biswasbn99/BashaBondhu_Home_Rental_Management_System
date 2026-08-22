import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class BudgetDropdown extends StatelessWidget {
  const BudgetDropdown({
    super.key,
    required this.value,
    required this.ranges,
    required this.onChanged,
    this.isRequired = false,
  });

  final String? value;
  final List<String> ranges;
  final ValueChanged<String?> onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<String>(
      hint: l10n.budget,
      value: value,
      isRequired: isRequired,
      items: [
        if (!isRequired) DropdownMenuItem(value: null, child: Text(l10n.budget)),
        ...ranges.map((r) => DropdownMenuItem(value: r, child: Text("$r ৳"))),
      ],
      onChanged: onChanged,
    );
  }
}
