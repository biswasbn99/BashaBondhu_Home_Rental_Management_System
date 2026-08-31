import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/utils/privacy_helper.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../shared/data/models/search_filter_model.dart';
import '../../../shared/presentation/widgets/app_network_image.dart';
import '../../../wishlist/data/providers/wishlist_provider.dart';
import '../../data/models/property_model.dart';
import '../screens/property_details_screen.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.distanceKm,
  });

  final PropertyModel property;
  final double? distanceKm;

  static String formatDateTimeWithDay(DateTime dt, String languageCode) {
    final isBn = languageCode == 'bn';
    final daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final daysBn = ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'];
    final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthsBn = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];

    final dayName = isBn ? daysBn[dt.weekday - 1] : daysEn[dt.weekday - 1];
    final monthName = isBn ? monthsBn[dt.month - 1] : monthsEn[dt.month - 1];

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? (isBn ? 'PM' : 'PM') : (isBn ? 'AM' : 'AM');

    String convertNumber(String input) {
      if (!isBn) return input;
      const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      var result = input;
      for (int i = 0; i < 10; i++) {
        result = result.replaceAll(enDigits[i], bnDigits[i]);
      }
      return result;
    }

    final formattedDayNum = convertNumber(dt.day.toString());
    final formattedYear = convertNumber(dt.year.toString());
    final formattedTime = '${convertNumber(hour.toString())}:${convertNumber(minute)} $period';

    return '$dayName, $formattedDayNum $monthName $formattedYear • $formattedTime';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isGuest = userProvider.isGuest || user == null;
    final wishlistProvider = context.watch<WishlistProvider>();
    final isFav = wishlistProvider.isFavorite(property.id);

    final isUnlocked = PrivacyHelper.isPropertyUnlocked(
      propertyId: property.id,
      isGuest: isGuest,
      isSubscribed: user?.isSubscribed ?? false,
      unlockedPropertyIds: user?.unlockedPropertyIds ?? [],
    );

    final subAreaName = property.subArea?.getLocalizedName(languageCode) ?? '';
    final areaName = property.area.getLocalizedName(languageCode);
    final districtName = property.district.getLocalizedName(languageCode);

    final locationText = PrivacyHelper.formatLocationWithPrivacy(
      subAreaName: subAreaName,
      areaName: areaName,
      districtName: districtName,
      isUnlocked: isUnlocked,
      isGuest: isGuest,
      languageCode: languageCode,
    );

    final dateDayTimeString = formatDateTimeWithDay(property.postDate, languageCode);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Image Banner ---
          Stack(
            children: [
              AppImageWidget(
                imageSource: property.images.isNotEmpty ? property.images.first : null,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              // Price Badge
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    '৳ ${property.amount} / ${l10n.perMonth}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // House Type & Month Tag
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        property.houseType.getLocalizedLabel(l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        property.month.getLocalizedMonth(l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (property.tenantType != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          property.tenantType!.getLocalizedLabel(l10n),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Image Count / Locked Badge
              if (property.images.length > 1)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isGuest) ...[
                          const Icon(Icons.lock_rounded, color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isGuest
                              ? '${1.toLocalizedDigits(languageCode)}/${property.images.length.toLocalizedDigits(languageCode)} ${languageCode == 'bn' ? '(বাকি ছবি লক)' : '(Locked)'}'
                              : '${1.toLocalizedDigits(languageCode)}/${property.images.length.toLocalizedDigits(languageCode)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              // Wishlist Heart Icon (Hidden for Guest users)
              if (!isGuest)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        wishlistProvider.toggleFavorite(
                          userProvider.user?.uid ?? '',
                          property.id,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // --- Body Info ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title / Room Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property.roomOrSeat.getLocalizedRoomOrSeat(l10n),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    if (property.floorNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${l10n.floorLabel}: ${property.floorNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location Row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.themeColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Key Facilities Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.themeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded, size: 13, color: AppColors.themeColor),
                            const SizedBox(width: 4),
                            Text(
                              distanceKm! < 1.0
                                  ? '${(distanceKm! * 1000).toStringAsFixed(0).toLocalizedDigits(languageCode)} ${languageCode == 'bn' ? 'মিটার দূরে' : 'm away'}'
                                  : '${distanceKm!.toStringAsFixed(1).toLocalizedDigits(languageCode)} ${languageCode == 'bn' ? 'কিমি দূরে' : 'km away'}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (property.attachedBathrooms != null && property.attachedBathrooms! > 0)
                      _buildChip(
                        Icons.bathtub_outlined,
                        '${property.attachedBathrooms} ${languageCode == 'bn' ? 'অ্যাটাচড বাথ' : 'Attached Bath'}',
                        theme,
                      ),
                    if (property.balconies != null && property.balconies! > 0)
                      _buildChip(
                        Icons.balcony_outlined,
                        '${property.balconies} ${languageCode == 'bn' ? 'বারান্দা' : 'Balcony'}',
                        theme,
                      ),
                    if (property.hasLift == true)
                      _buildChip(
                        Icons.elevator_outlined,
                        languageCode == 'bn' ? 'লিফট' : 'Lift',
                        theme,
                      ),
                    if (property.hasGenerator == true)
                      _buildChip(
                        Icons.bolt_outlined,
                        languageCode == 'bn' ? 'জেনারেটর' : 'Generator',
                        theme,
                      ),
                    if (property.hasWifi == true)
                      _buildChip(
                        Icons.wifi,
                        languageCode == 'bn' ? 'ওয়াইফাই' : 'WiFi',
                        theme,
                      ),
                  ],
                ),
                // Contact Row (Masked if locked: 017******45)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded, size: 15, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        isUnlocked ? property.userMobile : PrivacyHelper.maskPhoneNumber(property.userMobile),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.bold,
                          color: isUnlocked ? theme.colorScheme.onSurfaceVariant : Colors.amber.shade800,
                        ),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.shade700, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, size: 10, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                l10n.locked,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Post Date, Day and Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2827) : const Color(0xFFEEF7F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppColors.themeColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          dateDayTimeString,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : const Color(0xFF2C5E58),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.themeColor,
                      side: const BorderSide(color: AppColors.themeColor),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(l10n.viewDetails),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailsScreen(property: property),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.themeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
