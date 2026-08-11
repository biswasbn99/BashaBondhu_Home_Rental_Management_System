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
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool isLoading;

  static const Color _mintBg = Color(0xFFE3F6F5);
  static const Color _disabledBg = Color(0xFFEDEDED);
  static const Color _textDark = Color(0xFF16211E);

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = enabled && !isLoading;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: enabled ? _mintBg : _disabledBg,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            isLoading ? context.localizations.loading : hint,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: enabled ? _textDark : Colors.grey.shade500,
            ),
          ),
          icon: isLoading
              ? const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled ? _textDark : Colors.grey.shade500,
                ),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
          items: items,
          onChanged: isEnabled ? onChanged : null,
        ),
      ),
    );
  }
}