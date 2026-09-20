import 'package:flutter/material.dart';

import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import 'subscription_status_details_modal.dart';

class AccountTierStatusBadge extends StatelessWidget {
  final UserModel user;

  const AccountTierStatusBadge({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSub = user.isSubscribed;
    final activeCount = user.activePlans.length;

    final badgeColor = isSub ? const Color(0xFF10B981) : Colors.amber.shade800;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          SubscriptionStatusDetailsModal.show(context, user);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: isSub
                ? [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSub ? Icons.verified_rounded : Icons.card_giftcard_rounded,
                size: 13,
                color: badgeColor,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  isSub
                      ? (activeCount > 1
                          ? (isBn
                              ? '⭐ প্রিমিয়াম (${activeCount.toString().toLocalizedDigits("bn")}টি প্ল্যান)'
                              : '⭐ Premium ($activeCount Plans)')
                          : (isBn ? '👑 প্রিমিয়াম অ্যাকাউন্ট' : '👑 Premium Account'))
                      : (isBn ? '🆓 ফ্রি অ্যাকাউন্ট (সুবিধা দেখুন)' : '🆓 Free Account (View Limits)'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: badgeColor.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

