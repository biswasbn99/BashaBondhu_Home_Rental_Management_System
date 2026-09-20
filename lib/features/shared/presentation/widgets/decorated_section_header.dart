import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:flutter/material.dart';

class DecoratedSectionHeader extends StatelessWidget {
  const DecoratedSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.fitTitle = true,
  });

  final String title;
  final String? subtitle;
  final bool fitTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final titleWidget = Text(
      title,
      maxLines: fitTitle ? 1 : null,
      softWrap: !fitTitle,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 14.5,
        color: theme.colorScheme.onSurface,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.themeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: fitTitle
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: titleWidget,
                    )
                  : titleWidget,
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              subtitle!,
              softWrap: true,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
