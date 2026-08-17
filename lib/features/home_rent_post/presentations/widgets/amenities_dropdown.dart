import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class AmenitiesDropdown extends StatelessWidget {
  const AmenitiesDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String hint;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<bool>(
      hint: hint,
      value: value,
      isRequired: false,
      items: [
        DropdownMenuItem(value: null, child: Text(hint)),
        DropdownMenuItem(value: true, child: Text(l10n.available)),
        DropdownMenuItem(value: false, child: Text(l10n.unavailable)),
      ],
      onChanged: onChanged,
    );
  }
}
