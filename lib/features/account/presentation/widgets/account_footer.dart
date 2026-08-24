import 'package:flutter/material.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';

class AccountFooter extends StatelessWidget {
  const AccountFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.localizations;

    return Center(
      child: Column(
        children: [
          Text(
            'BashaBondhu Home Rental • ${l10n.appVersion} 1.0.0',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '© 2026 BashaBondhu Inc. All rights reserved.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

