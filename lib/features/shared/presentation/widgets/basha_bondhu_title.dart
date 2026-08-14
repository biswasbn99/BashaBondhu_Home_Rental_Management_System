import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';

class BashaBondhuTitle extends StatelessWidget {
  const BashaBondhuTitle({super.key, this.fontSize = 22});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colorScheme = Theme.of(context).colorScheme;
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
        ),
        children: [
          TextSpan(
            text: l10n.basha,
            style: TextStyle(color: colorScheme.onSurface),
          ),
          TextSpan(
            text: l10n.bondhu,
            style: const TextStyle(color: AppColors.themeColor),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: l10n.app,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: fontSize * 0.7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
