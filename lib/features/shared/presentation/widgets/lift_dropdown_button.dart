import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class LiftDropdown extends StatelessWidget {
  const LiftDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.showErrors = false,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;
  final bool isRequired;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<bool>(
      hint: l10n.lift,
      value: value,
      isRequired: isRequired,
      showErrors: showErrors,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.lift)),
        DropdownMenuItem(value: true, child: Text(l10n.available)),
        DropdownMenuItem(value: false, child: Text(l10n.unavailable)),
      ],
      onChanged: onChanged,
    );
  }
}
