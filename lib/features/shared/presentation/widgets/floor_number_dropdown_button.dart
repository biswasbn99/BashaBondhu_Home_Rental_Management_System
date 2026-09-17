import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class FloorNumberDropdown extends StatelessWidget {
  const FloorNumberDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.showErrors = false,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final bool isRequired;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<int>(
      hint: l10n.floorNumber,
      value: value,
      isRequired: isRequired,
      showErrors: showErrors,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.floorNumber)),
        ...List.generate(20, (i) => i + 1).map(
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
