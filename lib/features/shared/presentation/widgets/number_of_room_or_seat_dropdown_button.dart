import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class RoomOrSeatDropdown extends StatelessWidget {
  const RoomOrSeatDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    required this.enabled,
  });

  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilterDropdown<String>(
      hint: hint,
      value: value,
      enabled: enabled,
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
