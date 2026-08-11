import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeChangerDropdown extends StatelessWidget {
  const ThemeChangerDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.themeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ThemeMode>(
              value: themeProvider.currentThemeMode,
              dropdownColor: AppColors.themeColor,
              iconEnabledColor: Colors.white,
              isExpanded: true,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              items: themeProvider.themeModes.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: (ThemeMode? newThemeMode) {
                if (newThemeMode != null) {
                  themeProvider.changeThemeMode(newThemeMode);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
