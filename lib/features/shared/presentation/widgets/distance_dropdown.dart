import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';
import 'filter_dropdown.dart';

class DistanceDropdown extends StatelessWidget {
  const DistanceDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final List<String> options = [
      'below 0.5km',
      '0.5km',
      '1km',
      '2km',
      '3km',
      '3km+',
    ];

    return FilterDropdown<String>(
      hint: l10n.marketDistance,
      value: value,
      isRequired: false,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.marketDistance)),
        ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
      ],
      onChanged: onChanged,
    );
  }
}
