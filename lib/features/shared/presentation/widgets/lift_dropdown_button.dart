import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';
import 'filter_dropdown.dart';

class LiftDropdown extends StatelessWidget {
  const LiftDropdown({
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
      hint: l10n.lift,
      value: value,
      isRequired: false,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.lift)),
        DropdownMenuItem(value: true, child: Text(l10n.available)),
        DropdownMenuItem(value: false, child: Text(l10n.unavailable)),
      ],
      onChanged: onChanged,
    );
  }
}
