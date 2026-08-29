import 'package:flutter/material.dart';

class PrivacyHelper {
  /// Masks a phone number (e.g. `01712345678` -> `017******78`)
  static String maskPhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return 'লক করা';
    final clean = phone.trim();

    // Map bengali digits to english if needed for slicing
    if (clean.length < 5) return '***';

    final prefix = clean.substring(0, 3);
    final suffix = clean.substring(clean.length - 2);
    return '$prefix******$suffix';
  }

  /// Formats location string based on unlock status
  /// For locked users: subArea is masked with a lock badge
  static String formatLocationWithPrivacy({
    required String subAreaName,
    required String areaName,
    required String districtName,
    required bool isUnlocked,
    required bool isGuest,
    required String languageCode,
  }) {
    final isBn = languageCode == 'bn';
    final List<String> parts = [];

    if (isUnlocked) {
      if (subAreaName.isNotEmpty) {
        parts.add(subAreaName);
      }
    } else {
      if (isGuest) {
        parts.add(isBn ? '🔒 [সাব-এরিয়া লক]' : '🔒 [Sub-area Locked]');
      } else {
        parts.add(isBn ? '🔒 [সাব-এরিয়া লক]' : '🔒 [Sub-area Locked]');
      }
    }

    if (areaName.isNotEmpty) parts.add(areaName);
    if (districtName.isNotEmpty) parts.add(districtName);

    return parts.join(', ');
  }

  /// Check if property info is unlocked for the current user
  static bool isPropertyUnlocked({
    required String propertyId,
    required bool isGuest,
    required bool isSubscribed,
    required List<String> unlockedPropertyIds,
  }) {
    if (isGuest) return false;
    if (isSubscribed) return true;
    return unlockedPropertyIds.contains(propertyId);
  }

  /// Check if demand contact is unlocked for house owner
  static bool isDemandUnlocked({
    required String demandId,
    required bool isGuest,
    required bool isSubscribed,
    required List<String> unlockedDemandIds,
  }) {
    if (isGuest) return false;
    if (isSubscribed) return true;
    return unlockedDemandIds.contains(demandId);
  }

  /// Lock badge widget to show in UI
  static Widget buildLockBadge({
    required BuildContext context,
    required bool isDark,
    required String languageCode,
    VoidCallback? onTap,
  }) {
    final isBn = languageCode == 'bn';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade700, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 13, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              isBn ? 'লক করা' : 'Locked',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.amber[300] : Colors.amber[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

