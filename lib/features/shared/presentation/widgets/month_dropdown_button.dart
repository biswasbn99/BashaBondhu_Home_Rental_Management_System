import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class MonthDropdown extends StatelessWidget {
  const MonthDropdown({
    super.key,
    required this.value,
    required this.months,
    required this.onChanged,
    this.isRequired = false,
    this.showErrors = false,
  });

  final String? value;
  final List<String> months;
  final ValueChanged<String?> onChanged;
  final bool isRequired;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return FilterDropdown<String>(
      hint: isRequired ? l10n.month : '${l10n.month} (${l10n.optional})',
      value: value,
      isRequired: isRequired,
      showErrors: showErrors,
      items: [
        if (!isRequired)
          DropdownMenuItem<String>(
            value: null,
            child: Text(isBn ? 'সকল মাস' : 'All Months'),
          ),
        ...months.map(
          (m) => DropdownMenuItem(
            value: m,
            child: Text(m.getLocalizedMonth(l10n)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
