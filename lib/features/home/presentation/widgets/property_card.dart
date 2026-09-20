import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/utils/privacy_helper.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../auth/presentation/screens/sign_in_screen.dart';
import '../../../shared/data/models/search_filter_model.dart';
import '../../../shared/presentation/widgets/app_network_image.dart';
import '../../../subscription/data/models/free_tier_policy_model.dart';
import '../../../subscription/data/providers/subscription_provider.dart';
import '../../../subscription/presentation/screens/house_owner_subscription_screen.dart';
import '../../../subscription/presentation/screens/tenant_subscription_screen.dart';
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
    final subProvider = context.watch<SubscriptionProvider>();
    final policy = subProvider.currentPolicy ?? FreeTierPolicyModel.defaultPolicy();

    final isUnlocked = PrivacyHelper.isPropertyUnlocked(
      propertyId: property.id,
      isGuest: isGuest,
      isSubscribed: user?.isSubscribed ?? false,
      unlockedPropertyIds: user?.unlockedPropertyIds ?? [],
    );

    final subAreaName = property.subArea?.getLocalizedName(languageCode) ?? '';
    final areaName = property.area.getLocalizedName(languageCode);
    final districtName = property.district.getLocalizedName(languageCode);

    final bool isLandlord = user?.uid == property.ownerId;
    final bool isSubAreaUnlocked = isLandlord ||
        (user != null && user.isPropertySubAreaUnlocked(property.id, policy: policy, landlordId: property.ownerId));

    final locationText = PrivacyHelper.formatLocationWithPrivacy(
      subAreaName: subAreaName,
      areaName: areaName,
      districtName: districtName,
      isUnlocked: isSubAreaUnlocked,
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

                // Location Row (Clickable to open Google Maps navigation)
                InkWell(
                  onTap: () => _openGoogleMapsNavigation(context, property, user, policy),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
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
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me_rounded, size: 11, color: Color(0xFF0D9488)),
                              const SizedBox(width: 3),
                              Text(
                                languageCode == 'bn' ? 'ম্যাপ' : 'Map',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                // Contact Row (Masked if locked: 017******45) & Owner Verification Badge
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_iphone_rounded, size: 15, color: Colors.grey),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                isUnlocked ? property.userMobile : PrivacyHelper.maskPhoneNumber(property.userMobile),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.bold,
                                  color: isUnlocked ? theme.colorScheme.onSurfaceVariant : Colors.amber.shade800,
                                ),
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
                      const SizedBox(width: 6),
                      _buildOwnerVerificationBadge(property.ownerVerificationStatus, languageCode, isDark),
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

                // Action Buttons: View Details & Google Maps Direction
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.themeColor,
                          side: const BorderSide(color: AppColors.themeColor),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.viewDetails,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                        ),
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
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            languageCode == 'bn' ? 'গুগল ম্যাপ ডিরেকশন' : 'Map Direction',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        onPressed: () => _openGoogleMapsNavigation(context, property, user, policy),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerVerificationBadge(String status, String languageCode, bool isDark) {
    final isBn = languageCode == 'bn';
    final normalized = status.toLowerCase();

    if (normalized == 'verified') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              isBn ? 'ভেরিফাইড মালিক' : 'Verified Owner',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    } else if (normalized == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.5) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              isBn ? 'পেন্ডিং' : 'Pending',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gpp_bad_outlined, size: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              isBn ? 'আনভেরিফাইড' : 'Unverified',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }
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

  Future<void> _openGoogleMapsNavigation(
    BuildContext context,
    PropertyModel property,
    UserModel? user,
    FreeTierPolicyModel policy,
  ) async {
    if (user == null) {
      Navigator.pushNamed(context, SignInScreen.name);
      return;
    }

    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final languageCode = Localizations.localeOf(context).languageCode;

    // Check if user has quota
    if (!user.canOpenMapDirectionsForPolicy(policy: policy)) {
      final mapLimit = user.isSubscribed
          ? (user.activeSubscriptionPlans.isNotEmpty
              ? user.activeSubscriptionPlans.first.mapDirectionsLimit
              : user.subscriptionMaxMapDirections).toString().toLocalizedDigits(languageCode)
          : policy.tenantMapDirections.toString().toLocalizedDigits(languageCode);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBn ? 'দিকনির্দেশনা সীমা অতিক্রম' : 'Navigation Limit Reached',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            user.isSubscribed
                ? (isBn
                    ? 'আপনার বর্তমান প্যাকেজের গুগল ম্যাপ ডিরেকশন কোটা শেষ হয়ে গেছে। আনলিমিটেড বা অতিরিক্ত ডিরেকশন পেতে প্যাকেজ আপগ্রেড করুন।'
                    : 'Your active package Google Maps navigation quota has been exhausted. Please upgrade your plan for more directions.')
                : (isBn
                    ? 'ফ্রি অ্যাকাউন্টে গুগল ম্যাপ দিকনির্দেশনা ব্যবহারের সীমা ($mapLimitটি) শেষ হয়ে গেছে। আনলিমিটেড দিকনির্দেশনা পেতে সাবস্ক্রিপশন প্যাকেজ আপগ্রেড করুন।'
                    : 'Free tier Google Maps navigation limit ($mapLimit) has been reached. Please upgrade to a subscription plan for more directions.'),
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isBn ? 'পরে' : 'Maybe Later'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
              onPressed: () {
                Navigator.pop(ctx);
                if (user.isHouseOwner) {
                  Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
                } else {
                  Navigator.pushNamed(context, TenantSubscriptionScreen.name);
                }
              },
              child: Text(isBn ? 'প্যাকেজ আপগ্রেড করুন' : 'Upgrade Plan'),
            ),
          ],
        ),
      );
      return;
    }

    final remaining = user.remainingMapDirectionsForPolicy(policy: policy);
    final remainingStr = remaining >= 999
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : remaining.toString().toLocalizedDigits(languageCode);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.directions_rounded, color: Color(0xFF0D9488)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isBn ? 'গুগল ম্যাপ দিকনির্দেশনা' : 'Google Maps Directions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          user.isSubscribed
              ? (isBn
                  ? 'আপনি কি ১টি ক্রেডিট ব্যবহার করে এই বাসার লোকেশনে গুগল ম্যাপ ডিরেকশন চালু করতে চান?\n\n(আপনার অবশিষ্ট ডিরেকশন কোটা: $remainingStrটি)'
                  : 'Do you want to use 1 package credit to get Google Maps navigation to this property?\n\n(Remaining directions: $remainingStr)')
              : (isBn
                  ? 'আপনি কি ১টি ফ্রি ক্রেডিট ব্যবহার করে এই বাসার লোকেশনে গুগল ম্যাপ ডিরেকশন চালু করতে চান?\n\n(আপনার অবশিষ্ট ফ্রি ডিরেকশন কোটা: $remainingStrটি)'
                  : 'Do you want to use 1 free credit to get Google Maps navigation to this property?\n\n(Remaining free directions: $remainingStr)'),
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isBn ? 'না' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isBn ? 'হ্যাঁ, ম্যাপ খুলুন' : 'Yes, Open Map'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (context.mounted) {
      await context.read<SubscriptionProvider>().incrementMapDirectionCount(context, user);
    }

    final lat = property.latitude;
    final lng = property.longitude;
    Uri googleMapsUrl;
    Uri browserUrl;

    if (lat != null && lng != null) {
      googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
      browserUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else {
      final query = Uri.encodeComponent(
        '${property.subArea?.name ?? ''}, ${property.area.name}, ${property.district.name}, Bangladesh',
      );
      googleMapsUrl = Uri.parse('google.navigation:q=$query&mode=d');
      browserUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(browserUrl)) {
        await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
