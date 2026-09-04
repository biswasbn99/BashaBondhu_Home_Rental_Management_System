import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../../admin/data/providers/admin_provider.dart';

class LanguageActionButton extends StatelessWidget {
  const LanguageActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isBn = localeProvider.currentLocale.languageCode == 'bn';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final newLang = isBn ? 'en' : 'bn';
            localeProvider.changeLocale(Locale(newLang));
            try {
              final adminProvider = context.read<AdminProvider>();
              adminProvider.setLanguage(newLang == 'bn');
            } catch (_) {}
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.themeColor.withValues(alpha: 0.18)
                  : AppColors.themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.themeColor.withValues(alpha: isDark ? 0.4 : 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 15,
                  color: isDark ? const Color(0xFF26A69A) : AppColors.themeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isBn ? 'English' : 'বাংলা',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF26A69A) : AppColors.themeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
