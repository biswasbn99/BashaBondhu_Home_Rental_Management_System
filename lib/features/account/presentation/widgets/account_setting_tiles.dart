import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/providers/locale_provider.dart';
import 'package:bashabondhu_home_rental_management_system/app/providers/theme_provider.dart';

class AccountThemeSettingTile extends StatelessWidget {
  const AccountThemeSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentThemeMode == ThemeMode.dark ||
        (themeProvider.currentThemeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Colors.amber.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Theme Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            activeTrackColor: AppColors.themeColor,
            onChanged: (val) {
              themeProvider.changeThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        ],
      ),
    );
  }
}

class AccountLanguageSettingTile extends StatelessWidget {
  const AccountLanguageSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isBangla = localeProvider.currentLocale.languageCode == 'bn';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.language_rounded, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Language / ভাষা',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                Text(
                  isBangla ? 'বাংলা (Bangla)' : 'English',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isBangla,
            activeTrackColor: AppColors.themeColor,
            onChanged: (val) {
              localeProvider.changeLocale(Locale(val ? 'bn' : 'en'));
            },
          ),
        ],
      ),
    );
  }
}

