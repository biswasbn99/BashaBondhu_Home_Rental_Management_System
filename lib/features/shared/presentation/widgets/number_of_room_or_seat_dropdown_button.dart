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
    this.isRequired = false,
    this.showErrors = false,
    this.validator,
  });

  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final bool isRequired;
  final bool showErrors;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return FilterDropdown<String>(
      hint: hint,
      value: value,
      enabled: enabled,
      isRequired: isRequired,
      showErrors: showErrors,
      validator: isRequired
          ? (validator ??
              (val) {
                if (val == null || val.trim().isEmpty) {
                  if (!enabled) {
                    return isBn ? 'প্রথমে বাসার ধরন নির্বাচন করুন' : 'Please select house type first';
                  }
                  return isBn ? 'দয়া করে $hint নির্বাচন করুন' : 'Please select $hint';
                }
                return null;
              })
          : null,
      items: [
        if (!isRequired)
          DropdownMenuItem<String>(
            value: null,
            child: Text(isBn ? 'যেকোনো সংখ্যা' : 'Any Count'),
          ),
        ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
      ],
      onChanged: onChanged,
    );
  }
}
