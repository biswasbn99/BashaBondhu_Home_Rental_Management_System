import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';

class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.isLoading = false,
    this.isRequired = true,
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool isLoading;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = enabled && !isLoading;

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: isLoading ? context.localizations.loading : hint,
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      icon: isEnabled
          ? const Icon(Icons.keyboard_arrow_down_rounded)
          : Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
      items: items,
      onChanged: isEnabled ? onChanged : null,
      validator: (val) {
        if (isRequired && enabled && val == null) {
          return 'দয়া করে এটি পূরণ করুন';
        }
        return null;
      },
    );
  }
}
