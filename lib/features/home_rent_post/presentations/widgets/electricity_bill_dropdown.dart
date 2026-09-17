import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class ElectricityBillDropdown extends StatelessWidget {
  const ElectricityBillDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.showErrors = false,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isRequired;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<String>(
      hint: l10n.electricityBill,
      value: value,
      isRequired: isRequired,
      showErrors: showErrors,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.electricityBill)),
        DropdownMenuItem(value: 'owner', child: Text(l10n.owner)),
        DropdownMenuItem(value: 'self', child: Text(l10n.self)),
        DropdownMenuItem(value: 'withRent', child: Text(l10n.withRent)),
      ],
      onChanged: onChanged,
    );
  }
}
