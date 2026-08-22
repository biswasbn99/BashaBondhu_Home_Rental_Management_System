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

    // 1. Deduplicate items by value to prevent multiple items with the same value error
    final seenValues = <T?>{};
    final List<DropdownMenuItem<T>> safeItems = [];
    for (final item in items) {
      if (seenValues.add(item.value)) {
        safeItems.add(item);
      }
    }

    // 2. If value is provided and not present in items, safely insert it as a valid item
    if (value != null && !safeItems.any((item) => item.value == value)) {
      safeItems.insert(
        0,
        DropdownMenuItem<T>(
          value: value,
          child: Text(value.toString()),
        ),
      );
    }

    return DropdownButtonFormField<T>(
      initialValue: value,
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
      items: safeItems,
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
