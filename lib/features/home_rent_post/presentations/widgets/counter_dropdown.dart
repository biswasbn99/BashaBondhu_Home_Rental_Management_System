import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class CounterDropdown extends StatelessWidget {
  const CounterDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.maxCount = 10,
    this.isRequired = false,
    this.showErrors = false,
  });

  final String hint;
  final int? value;
  final ValueChanged<int?> onChanged;
  final int maxCount;
  final bool isRequired;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    return FilterDropdown<int>(
      hint: hint,
      value: value,
      isRequired: isRequired,
      showErrors: showErrors,
      items: [
        DropdownMenuItem(value: null, child: Text(hint)),
        ...List.generate(maxCount + 1, (i) => i).map(
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
