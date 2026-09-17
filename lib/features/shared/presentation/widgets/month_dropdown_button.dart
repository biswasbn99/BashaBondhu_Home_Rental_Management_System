import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class MonthDropdown extends StatelessWidget {
  const MonthDropdown({
    super.key,
    required this.value,
    required this.months,
    required this.onChanged,
    this.showErrors = false,
  });

  final String? value;
  final List<String> months;
  final ValueChanged<String?> onChanged;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;

    return FilterDropdown<String>(
      hint: l10n.month,
      value: value,
      showErrors: showErrors,
      items: months
          .map((m) => DropdownMenuItem(
                value: m,
                child: Text(m.getLocalizedMonth(l10n)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
