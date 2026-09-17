import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
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
    this.validator,
    this.autovalidateMode,
    this.showErrors = false,
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool isLoading;
  final bool isRequired;
  final String? Function(T?)? validator;
  final AutovalidateMode? autovalidateMode;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = enabled && !isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final effectiveAutovalidateMode = autovalidateMode ??
        (showErrors ? AutovalidateMode.always : AutovalidateMode.onUserInteraction);

    // 1. Filter out null-value placeholder items if field is required
    final cleanItems = isRequired
        ? items.where((item) => item.value != null).toList()
        : items;

    // 2. Deduplicate items by value to prevent multiple items with the same value error
    final seenValues = <T?>{};
    final List<DropdownMenuItem<T>> safeItems = [];
    for (final item in cleanItems) {
      if (seenValues.add(item.value)) {
        safeItems.add(item);
      }
    }

    // 3. If value is provided and not present in items, safely insert it as a valid item
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
      // ignore: deprecated_member_use
      value: value,
      isExpanded: true,
      autovalidateMode: effectiveAutovalidateMode,
      hint: Text(
        isLoading ? context.localizations.loading : hint,
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 14,
        ),
      ),
      decoration: InputDecoration(
        hintText: isLoading ? context.localizations.loading : hint,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : (isEnabled ? Colors.white : Colors.grey.shade100),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: (showErrors && isRequired && (value == null || (value is String && (value as String).trim().isEmpty)))
                ? Colors.redAccent
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: (showErrors && isRequired && (value == null || (value is String && (value as String).trim().isEmpty))) ? 1.5 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.themeColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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
        if (validator != null) {
          return validator!(val);
        }
        if (isRequired && (val == null || (val is String && val.trim().isEmpty))) {
          return isBn
              ? 'দয়া করে $hint নির্বাচন করুন'
              : 'Please select $hint';
        }
        return null;
      },
    );
  }
}
