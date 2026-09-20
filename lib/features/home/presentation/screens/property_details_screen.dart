import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/utils/privacy_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../auth/presentation/screens/sign_in_screen.dart';
import '../../../shared/data/models/search_filter_model.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/app_network_image.dart';
import '../../../shared/presentation/widgets/decorated_section_header.dart';
import '../../../shared/presentation/widgets/full_screen_image_viewer.dart';
import '../../../subscription/data/models/free_tier_policy_model.dart';
import '../../../subscription/data/providers/subscription_provider.dart';
import '../../../subscription/presentation/screens/house_owner_subscription_screen.dart';
import '../../../subscription/presentation/screens/tenant_subscription_screen.dart';
import '../../data/models/property_model.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key, required this.property});

  final PropertyModel property;

  static const String name = '/property-details';

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  String? _tenantDistanceString;

  @override
  void initState() {
    super.initState();
    _calculateDistanceToProperty();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _calculateDistanceToProperty() async {
    final p = widget.property;
    if (p.latitude == null || p.longitude == null) return;

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      Position? currentPos = await Geolocator.getLastKnownPosition();
      currentPos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      final distanceMeters = const Distance().as(
        LengthUnit.Meter,
        LatLng(currentPos.latitude, currentPos.longitude),
        LatLng(p.latitude!, p.longitude!),
      );

      if (mounted) {
        setState(() {
          if (distanceMeters < 1000) {
            _tenantDistanceString = '${distanceMeters.toStringAsFixed(0)} m away';
          } else {
            final km = distanceMeters / 1000;
            _tenantDistanceString = '${km.toStringAsFixed(1)} km away';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _openGoogleMapsNavigation(double lat, double lng, UserModel? user, FreeTierPolicyModel? policy) async {
    if (user == null) {
      Navigator.pushNamed(context, SignInScreen.name);
      return;
    }

    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final languageCode = Localizations.localeOf(context).languageCode;
    if (!user.canOpenMapDirectionsForPolicy(policy: policy)) {
      final mapLimit = (policy?.tenantMapDirections ?? 2).toString().toLocalizedDigits(languageCode);
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

    await context.read<SubscriptionProvider>().incrementMapDirectionCount(context, user);

    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final browserUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(browserUrl)) {
        await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _handleUnlock(BuildContext context, UserModel? user, FreeTierPolicyModel? policy) {
    if (user == null) {
      Navigator.pushNamed(context, SignInScreen.name);
      return;
    }

    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final l10n = context.localizations;
    final languageCode = Localizations.localeOf(context).languageCode;

    if (!user.canUnlockContactForPolicy(policy: policy)) {
      final freeLimit = (policy?.tenantUnlockNumbers ?? 5).toString().toLocalizedDigits(languageCode);
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
                  isBn ? 'নম্বর আনলক সীমা শেষ' : 'Contact Unlock Limit Reached',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            user.isSubscribed
                ? (isBn
                    ? 'আপনার বর্তমান প্যাকেজের ফোন নম্বর আনলক করার কোটা শেষ হয়ে গেছে। আরও নম্বর আনলক করতে প্যাকেজ রিনিউ বা আপগ্রেড করুন।'
                    : 'Your subscription contact unlock quota is exhausted. Please renew or upgrade your package.')
                : (isBn
                    ? 'আপনার ফ্রি $freeLimitটি নম্বর আনলক শেষ হয়ে গেছে। বাড়িওয়ালার ফোন নম্বর ও অন্যান্য তথ্য আনলক করতে সাপোর্ট প্যাকেজ গ্রহণ করুন।'
                    : 'You have used all $freeLimit free contact unlocks. Please activate a support package to unlock more contacts.'),
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
                Navigator.pushNamed(context, TenantSubscriptionScreen.name);
              },
              child: Text(isBn ? 'প্যাকেজ দেখুন' : 'View Packages'),
            ),
          ],
        ),
      );
      return;
    }

    final remaining = user.remainingContactUnlocksForPolicy(policy: policy);
    final remainingStr = remaining >= 999999
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : remaining.toString().toLocalizedDigits(languageCode);
    final totalLimit = policy?.tenantUnlockNumbers ?? 5;
    final totalLimitStr = totalLimit == -1
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : totalLimit.toString().toLocalizedDigits(languageCode);

    final dialogContent = user.isSubscribed
        ? (isBn
            ? 'আপনি কি ১টি ক্রেডিট ব্যবহার করে এই বাসার সঠিক সাব-এরিয়া, বাড়িওয়ালার ফোন নম্বর ও অন্যান্য তথ্য আনলক করতে চান?\n\n(আপনার প্যাকেজে আনলক বাকি: $remainingStr)'
            : 'Do you want to use 1 package credit to unlock this landlord\'s contact info?\n\n(Package unlocks remaining: $remainingStr)')
        : l10n.unlockPropertyDialogContent(remainingStr, totalLimitStr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.lock_open_rounded, color: AppColors.themeColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.unlockPropertyDialogTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
              ),
            ),
          ],
        ),
        content: Text(
          dialogContent,
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.no),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final subProvider = context.read<SubscriptionProvider>();
              final ok = await subProvider.unlockProperty(context, user, widget.property.id);
              if (ok && mounted) {
                setState(() {});
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.unlockSuccessMessage),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(l10n.yesUnlock),
          ),
        ],
      ),
    );
  }

  void _handleUnlockSubArea(BuildContext context, UserModel? user, FreeTierPolicyModel policy) {
    if (user == null) {
      Navigator.pushNamed(context, SignInScreen.name);
      return;
    }

    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final languageCode = Localizations.localeOf(context).languageCode;
    final canUnlock = user.canUnlockSubAreaForTenant(policy: policy);

    if (!canUnlock) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBn ? 'সাব-এরিয়া আনলক সীমা শেষ' : 'Sub-Area Unlock Limit Reached',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            user.isSubscribed
                ? (isBn
                    ? 'আপনার বর্তমান প্যাকেজের সাব-এরিয়া লোকেশন আনলক করার কোটা শেষ হয়ে গেছে। আরও আনলক করতে প্যাকেজ রিনিউ বা আপগ্রেড করুন।'
                    : 'Your package sub-area unlock quota has been exhausted. Please renew or upgrade your plan.')
                : (isBn
                    ? (policy.tenantSubAreaUnlocks <= 0
                        ? 'ফ্রি অ্যাকাউন্টে সাব-এরিয়া লোকেশন সুবিধা অন্তর্ভুক্ত নেই। বাসার সঠিক সাব-এরিয়া ও ঠিকানা দেখতে সাবস্ক্রিপশন প্ল্যান গ্রহণ করুন।'
                        : 'আপনার ফ্রি ${policy.tenantSubAreaUnlocks}টি সাব-এরিয়া আনলক শেষ হয়ে গেছে। আরও আনলক করতে সাবস্ক্রিপশন প্ল্যান গ্রহণ করুন।')
                    : 'You have exhausted your free sub-area unlocks. Please subscribe to unlock more property locations.'),
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isBn ? 'পরে' : 'Maybe Later'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, TenantSubscriptionScreen.name);
              },
              child: Text(isBn ? 'প্যাকেজ দেখুন' : 'View Packages'),
            ),
          ],
        ),
      );
      return;
    }

    final remaining = user.remainingTenantSubAreaUnlocks(policy: policy);
    final remainingStr = remaining >= 999
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : remaining.toString().toLocalizedDigits(languageCode);

    final dialogContent = user.isSubscribed
        ? (isBn
            ? 'আপনি কি ১টি ক্রেডিট ব্যবহার করে এই বাসার বিস্তারিত সাব-এরিয়া লোকেশন ও সুনির্দিষ্ট ঠিকানা আনলক করতে চান?\n\n(আপনার প্যাকেজে সাব-এরিয়া আনলক বাকি: $remainingStr টি)'
            : 'Do you want to use 1 package credit to unlock this property\'s sub-area location & detailed address?\n\n(Package sub-area unlocks remaining: $remainingStr)')
        : (isBn
            ? 'আপনি কি ১টি ফ্রি ক্রেডিট ব্যবহার করে এই বাসার সাব-এরিয়া লোকেশন আনলক করতে চান?\n\n(আপনার ফ্রি সাব-এরিয়া আনলক বাকি: $remainingStr টি)'
            : 'Do you want to use 1 free credit to unlock this property\'s sub-area location?\n\n(Free sub-area unlocks remaining: $remainingStr)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.location_city_rounded, color: Color(0xFF0D9488)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBn ? 'সাব-এরিয়া লোকেশন আনলক করুন' : 'Unlock Sub-Area Location',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
              ),
            ),
          ],
        ),
        content: Text(
          dialogContent,
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'না' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            onPressed: () async {
              Navigator.pop(ctx);
              final subProvider = context.read<SubscriptionProvider>();
              final ok = await subProvider.unlockPropertySubArea(context, user, widget.property.id);
              if (ok && mounted) {
                setState(() {});
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBn
                          ? 'বাসার সাব-এরিয়া লোকেশন সফলভাবে আনলক হয়েছে!'
                          : 'Property sub-area unlocked successfully!',
                    ),
                    backgroundColor: const Color(0xFF0D9488),
                  ),
                );
              }
            },
            child: Text(isBn ? 'হ্যাঁ, আনলক করুন' : 'Yes, Unlock'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUnlockPhotos(BuildContext context, UserModel user, String propertyId, FreeTierPolicyModel? policy) async {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final languageCode = Localizations.localeOf(context).languageCode;

    if (!user.canUnlockPhotoGallery(policy: policy)) {
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
                  isBn ? 'ফটো গ্যালারি সীমা অতিক্রম' : 'Photo Gallery Limit Reached',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            user.isSubscribed
                ? (isBn
                    ? 'আপনার বর্তমান প্যাকেজের ফটো গ্যালারি আনলক কোটা শেষ হয়ে গেছে। আরও ছবি দেখতে প্যাকেজ আপগ্রেড করুন।'
                    : 'Your active package photo gallery unlock quota has been exhausted. Please upgrade your plan.')
                : (isBn
                    ? 'আপনার ফ্রি ফটো গ্যালারি দেখার লিমিট শেষ হয়ে গেছে। অতিরিক্ত ছবি দেখতে সাবস্ক্রিপশন প্যাকেজ সক্রিয় করুন।'
                    : 'You have reached your free photo gallery unlock limit. Please subscribe to view additional photos.'),
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
                Navigator.pushNamed(context, TenantSubscriptionScreen.name);
              },
              child: Text(isBn ? 'প্যাকেজ দেখুন' : 'View Packages'),
            ),
          ],
        ),
      );
      return;
    }

    final remaining = user.remainingPhotoGalleryUnlocks(policy: policy);
    final remainingStr = remaining >= 999
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : remaining.toString().toLocalizedDigits(languageCode);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.photo_library_rounded, color: AppColors.themeColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBn ? 'ফটো গ্যালারি আনলক করুন' : 'Unlock Photo Gallery',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
              ),
            ),
          ],
        ),
        content: Text(
          isBn
              ? (user.isSubscribed
                  ? 'আপনি কি ১টি প্যাকেজ ফটো গ্যালারি কোটা ব্যবহার করে এই বাসার সকল ছবি আনলক করতে চান?\n\n(আপনার অবশিষ্ট কোটা: $remainingStrটি)'
                  : 'আপনি কি ১টি ফ্রি ফটো গ্যালারি কোটা ব্যবহার করে এই বাসার সকল ছবি আনলক করতে চান?\n\n(আপনার অবশিষ্ট কোটা: $remainingStrটি)')
              : (user.isSubscribed
                  ? 'Do you want to use 1 package photo gallery unlock credit for this property?\n\n(Remaining unlocks: $remainingStr)'
                  : 'Do you want to use 1 free photo gallery unlock credit for this property?\n\n(Remaining unlocks: $remainingStr)'),
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isBn ? 'না' : 'No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isBn ? 'হ্যাঁ, আনলক করুন' : 'Yes, Unlock'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await context.read<SubscriptionProvider>().unlockPhotoGallery(context, user, propertyId);
      if (ok && mounted) {
        setState(() {});
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(isBn ? 'ফটো গ্যালারি সফলভাবে আনলক হয়েছে!' : 'Photo gallery unlocked successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSubAreaLockedCard(
    BuildContext context,
    UserModel? user,
    bool isDark,
    bool isBn,
    FreeTierPolicyModel policy,
  ) {
    final canUnlock = user?.canUnlockSubAreaForTenant(policy: policy) ?? false;
    final remaining = user?.remainingTenantSubAreaUnlocks(policy: policy) ?? 0;
    final languageCode = Localizations.localeOf(context).languageCode;
    final remainingStr = remaining >= 999
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : remaining.toString().toLocalizedDigits(languageCode);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132A26) : const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0D9488).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, size: 18, color: Color(0xFF0D9488)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'বাসার সাব-এরিয়া ও পূর্ণাঙ্গ ঠিকানা লক করা' : 'Sub-Area & Full Address Locked',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  user == null
                      ? (isBn ? 'লগইন করে সাব-এরিয়া আনলক করুন' : 'Log in to unlock sub-area')
                      : (canUnlock
                          ? (isBn
                              ? 'সুনির্দিষ্ট এলাকা ও পাড়া দেখতে আনলক করুন (বাকি: $remainingStr টি)'
                              : 'Unlock to view exact sub-area & neighborhood ($remainingStr left)')
                          : (isBn
                              ? 'সাব-এরিয়া আনলক লিমিট শেষ। আপগ্রেড করুন।'
                              : 'Sub-area unlock limit reached. Upgrade to unlock.')),
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.lock_open_rounded, size: 14),
            label: Text(
              isBn ? 'সাব-এরিয়া আনলক' : 'Unlock Sub-Area',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _handleUnlockSubArea(context, user, policy),
          ),
        ],
      ),
    );
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
    final p = widget.property;
    final subProvider = context.watch<SubscriptionProvider>();

    return StreamBuilder<FreeTierPolicyModel>(
      stream: subProvider.streamFreeTierPolicy(),
      builder: (context, policySnap) {
        final policy = policySnap.data ?? FreeTierPolicyModel.defaultPolicy();
        final bool isBn = languageCode == 'bn';

        final bool isLandlord = user?.uid == p.ownerId;
        final bool isSubAreaUnlocked = isLandlord ||
            (user != null && user.isPropertySubAreaUnlocked(p.id, policy: policy, landlordId: p.ownerId));

        final isUnlocked = isLandlord ||
            PrivacyHelper.isPropertyUnlocked(
              propertyId: p.id,
              isGuest: isGuest,
              isSubscribed: user?.isSubscribed ?? false,
              unlockedPropertyIds: user?.unlockedPropertyIds ?? [],
            );

        final bool canViewPhotos = !isGuest && user.isPhotoGalleryUnlockedForProperty(p.id, policy: policy);

        final subAreaName = p.subArea?.getLocalizedName(languageCode) ?? '';
        final areaName = p.area.getLocalizedName(languageCode);
        final districtName = p.district.getLocalizedName(languageCode);

        final locationText = PrivacyHelper.formatLocationWithPrivacy(
          subAreaName: subAreaName,
          areaName: areaName,
          districtName: districtName,
          isUnlocked: isSubAreaUnlocked,
          isGuest: isGuest,
          languageCode: languageCode,
        );

        final String displayMobile = isUnlocked ? p.userMobile : PrivacyHelper.maskPhoneNumber(p.userMobile);
        final String displayWhatsApp = isUnlocked ? p.userWhatsApp : PrivacyHelper.maskPhoneNumber(p.userWhatsApp);

        return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.viewDetails,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Image Slider Gallery (Template only for locked) ---
            _buildImageGallery(p, isGuest, canViewPhotos, isDark, languageCode),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. Price and Type Row ---
                  _buildPriceSection(p, l10n, theme),
                  const SizedBox(height: 20),

                  // --- 2.1 Additional Photos Section (Gallery for Tenant / Login Lock for Guest / Subscription Lock for Free) ---
                  _buildAdditionalPhotosSection(p, isGuest, canViewPhotos, isDark, languageCode, user, policy),

                  // --- 3. Location Section with Sub-Area Privacy Mask ---
                  DecoratedSectionHeader(title: l10n.locationLabel),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.map_outlined, locationText),
                  if (p.shortAddress.isNotEmpty && isSubAreaUnlocked)
                    _buildInfoRow(Icons.location_on_outlined, p.shortAddress),

                  // Sub-Area Unlock Card when locked
                  if (!isSubAreaUnlocked && subAreaName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSubAreaLockedCard(context, user, isDark, isBn, policy),
                  ],

                  // --- 4. Interactive Map Section (Locked Container if not unlocked) ---
                  if (p.latitude != null && p.longitude != null)
                    _buildMapSection(p, l10n, theme, isDark, isUnlocked, user, policy),

                  const SizedBox(height: 24),

                  // --- 5. Facilities Section ---
                  DecoratedSectionHeader(title: l10n.facilitiesLabel),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (p.tenantType != null)
                        _buildAmenityChip(Icons.people_outline_rounded, p.tenantType!.getLocalizedLabel(l10n), theme),
                      _buildAmenityChip(Icons.bed_outlined, p.roomOrSeat.getLocalizedRoomOrSeat(l10n), theme),
                      if (p.floorNumber != null)
                        _buildAmenityChip(Icons.stairs_outlined, '${l10n.floorLabel}: ${p.floorNumber}', theme),
                      if (p.attachedBathrooms != null && p.attachedBathrooms! > 0)
                        _buildAmenityChip(Icons.bathtub_outlined, '${p.attachedBathrooms} ${l10n.attachedBathroom}', theme),
                      if (p.commonBathrooms != null && p.commonBathrooms! > 0)
                        _buildAmenityChip(Icons.bathroom_outlined, '${p.commonBathrooms} ${l10n.commonBathroom}', theme),
                      if (p.kitchenCount != null && p.kitchenCount! > 0)
                        _buildAmenityChip(Icons.kitchen_outlined, '${p.kitchenCount} ${l10n.kitchen}', theme),
                      if (p.balconies != null && p.balconies! > 0)
                        _buildAmenityChip(Icons.balcony_outlined, '${p.balconies} ${l10n.balcony}', theme),
                      if (p.electricityBillType != null && p.electricityBillType!.isNotEmpty)
                        _buildAmenityChip(Icons.electric_bolt_outlined, '${l10n.electricityBill}: ${p.electricityBillType}', theme),
                      if (p.hasLift == true)
                        _buildAmenityChip(Icons.elevator_outlined, l10n.lift, theme),
                      if (p.hasParking == true)
                        _buildAmenityChip(Icons.local_parking_rounded, l10n.parking, theme),
                      if (p.hasWifi == true)
                        _buildAmenityChip(Icons.wifi_rounded, l10n.wifi, theme),
                      if (p.hasGenerator == true)
                        _buildAmenityChip(Icons.bolt_outlined, l10n.generator, theme),
                      if (p.hasSecurityGuard == true)
                        _buildAmenityChip(Icons.security_rounded, l10n.securityGuard, theme),
                      if (p.hasCctv == true)
                        _buildAmenityChip(Icons.videocam_outlined, l10n.cctv, theme),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- 6. Description Section ---
                  if (p.detailedDescription.isNotEmpty) ...[
                    DecoratedSectionHeader(title: l10n.descriptionLabel),
                    const SizedBox(height: 12),
                    Text(
                      p.detailedDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- 7. Landlord Contact Section ---
                  DecoratedSectionHeader(title: l10n.contactPerson),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2725) : const Color(0xFFF3F9F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF263936) : const Color(0xFFD4E8E5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.themeColor.withValues(alpha: 0.2),
                              child: const Icon(Icons.person, color: AppColors.themeColor, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        p.contactName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      _buildOwnerVerificationBadge(p.ownerVerificationStatus, languageCode, isDark),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        displayMobile,
                                        style: TextStyle(
                                          color: isUnlocked ? theme.colorScheme.onSurfaceVariant : Colors.amber.shade800,
                                          fontWeight: isUnlocked ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (!isUnlocked) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.lock_rounded, size: 12, color: Colors.amber),
                                      ],
                                    ],
                                  ),
                                  if (p.userWhatsApp.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'WhatsApp: $displayWhatsApp',
                                          style: TextStyle(
                                            color: isUnlocked ? theme.colorScheme.onSurfaceVariant : Colors.amber.shade800,
                                            fontWeight: isUnlocked ? FontWeight.normal : FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (!isUnlocked) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.lock_rounded, size: 12, color: Colors.amber),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- 8. Dynamic Bottom Unlock / Contact Action Bar ---
                  _buildBottomActionBar(context, p, isUnlocked, user, isGuest, l10n, policy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildBottomActionBar(
    BuildContext context,
    PropertyModel p,
    bool isUnlocked,
    UserModel? user,
    bool isGuest,
    AppLocalizations l10n,
    FreeTierPolicyModel policy,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (!isUnlocked) {
      if (isGuest) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, SignInScreen.name),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.login_rounded),
            label: Text(
              l10n.loginToUnlockInfo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      }

      final canUnlock = user?.canUnlockContactForPolicy(policy: policy) ?? false;

      if (canUnlock) {
        final isSub = user?.isSubscribed ?? false;
        final count = user?.remainingContactUnlocksForPolicy(policy: policy) ?? 0;
        final countStr = count >= 999999
            ? (languageCode == 'bn' ? 'আনলিমিটেড' : 'Unlimited')
            : count.toString().toLocalizedDigits(languageCode);
        final totalCount = policy.tenantUnlockNumbers;
        final totalStr = totalCount == -1
            ? (languageCode == 'bn' ? 'আনলিমিটেড' : 'Unlimited')
            : totalCount.toString().toLocalizedDigits(languageCode);
        final btnText = isSub
            ? (languageCode == 'bn'
                ? 'প্যাকেজ কোটায় নম্বর আনলক ($countStr বাকি)'
                : 'Unlock with Package ($countStr Left)')
            : l10n.unlockInfoAndNumberWithQuota(countStr, totalStr);

        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _handleUnlock(context, user, policy),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(
              btnText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, TenantSubscriptionScreen.name),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.workspace_premium_rounded),
            label: Text(
              l10n.unlockWithSupportPackage,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      }
    }

    // When Unlocked: Show Call & WhatsApp buttons
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.phone),
            label: Text(l10n.callNow),
            onPressed: () => _launchCaller(p.userMobile),
          ),
        ),
        if (p.userWhatsApp.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.chat),
              label: const Text('WhatsApp'),
              onPressed: () => _launchWhatsApp(p.userWhatsApp),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMapSection(
    PropertyModel p,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
    bool isUnlocked,
    UserModel? user,
    FreeTierPolicyModel? policy,
  ) {
    if (p.latitude == null || p.longitude == null) return const SizedBox.shrink();

    if (!isUnlocked) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF24231A) : const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            const Icon(Icons.map_outlined, color: Colors.amber, size: 36),
            const SizedBox(height: 8),
            Text(
              l10n.mapLockedTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.mapLockedSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: Text(l10n.unlockMap, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _handleUnlock(context, user, policy),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: Text(
                    Localizations.localeOf(context).languageCode == 'bn'
                        ? 'গুগল ম্যাপ ডিরেকশন (${user?.remainingMapDirectionsForPolicy(policy: policy).toString().toLocalizedDigits("bn") ?? 0} বাকি)'
                        : 'Google Maps Directions (${user?.remainingMapDirectionsForPolicy(policy: policy) ?? 0} Left)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openGoogleMapsNavigation(p.latitude!, p.longitude!, user, policy),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final propertyLatLng = LatLng(p.latitude!, p.longitude!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: propertyLatLng,
                    initialZoom: 15.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bashabondhu_home_rental_management_system',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: propertyLatLng,
                          width: 46,
                          height: 46,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Distance Badge (if tenant location computed)
                if (_tenantDistanceString != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation_rounded, color: AppColors.themeColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            _tenantDistanceString!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Live Google Maps Direction Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openGoogleMapsNavigation(p.latitude!, p.longitude!, user, policy),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: Text(
              l10n.viewDirections,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(
    PropertyModel p,
    bool isGuest,
    bool canViewPhotos,
    bool isDark,
    String languageCode,
  ) {
    final images = p.images;
    final isBn = languageCode == 'bn';

    if (images.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        color: isDark ? Colors.grey[850] : Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.home_work_outlined, size: 64, color: Colors.grey),
        ),
      );
    }

    // Guest users or users without additional photos quota can only view the 1st image (template)
    final bool canAccessAll = !isGuest && canViewPhotos;
    final displayImages = canAccessAll ? images : [images.first];

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        children: [
          // Slider / Main Image
          PageView.builder(
            controller: _pageController,
            itemCount: displayImages.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  FullScreenImageViewer.show(
                    context,
                    images: displayImages,
                    initialIndex: canAccessAll ? index : 0,
                  );
                },
                child: AppImageWidget(
                  imageSource: displayImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 260,
                ),
              );
            },
          ),

          // Top-Left: Template / Image Badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_work_rounded, color: AppColors.themeColor, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    _currentImageIndex == 0
                        ? (isBn ? 'প্রধান টেমপ্লেট ছবি' : 'Main Template Photo')
                        : (isBn ? 'অতিরিক্ত ছবি #${_currentImageIndex.toString().toLocalizedDigits("bn")}' : 'Photo #${_currentImageIndex + 1}'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top-Right: Tap to Zoom Badge
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  FullScreenImageViewer.show(
                    context,
                    images: displayImages,
                    initialIndex: canAccessAll ? _currentImageIndex : 0,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_in_rounded, color: AppColors.themeColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        isBn ? 'জুম করে দেখুন' : 'Tap to Zoom',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom-Right: Photo Counter Badge
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!canAccessAll && images.length > 1) ...[
                    const Icon(Icons.lock_rounded, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    !canAccessAll
                        ? (isBn
                            ? '১/${images.length.toString().toLocalizedDigits("bn")} (বাকি ছবি লক)'
                            : '1/${images.length} (More Locked)')
                        : '${(_currentImageIndex + 1).toLocalizedDigits(languageCode)}/${images.length.toLocalizedDigits(languageCode)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Additional Photos Section:
  /// - For Tenant (with access): Shows horizontal gallery of additional photos with zoom support
  /// - For Guest: Shows locked banner with login prompt
  /// - For Logged-in without Photo Access: Shows locked banner with subscription prompt
  Widget _buildAdditionalPhotosSection(
    PropertyModel p,
    bool isGuest,
    bool canViewPhotos,
    bool isDark,
    String languageCode,
    UserModel? user,
    FreeTierPolicyModel? policy,
  ) {
    if (p.images.length <= 1) return const SizedBox.shrink();

    final isBn = languageCode == 'bn';
    final additionalImages = p.images.sublist(1);
    final countText = additionalImages.length.toString().toLocalizedDigits(languageCode);

    // --- GUEST USER: Locked Banner ---
    if (isGuest) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF24231A) : const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_rounded, color: Colors.amber.shade900, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? '🔒 অতিরিক্ত $countTextটি ছবি দেখতে লগইন করুন' : '🔒 $countText Additional Photos Available',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBn
                            ? 'বাড়ির ভিতরের রুম ও অন্যান্য সুবিধার ছবি দেখতে অনুগ্রহ করে একাউন্টে লগইন করুন।'
                            : 'Please log in to view all additional room and interior photos.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, SignInScreen.name),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.login_rounded, size: 16),
                label: Text(
                  isBn ? 'লগইন করে সব ছবি দেখুন' : 'Login to View Photos',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // --- LOGGED-IN BUT NO ACCESS TO ADDITIONAL PHOTOS ---
    if (!canViewPhotos) {
      final bool canUnlockFree = user != null && user.canUnlockPhotoGallery(policy: policy);
      final remainingFree = user?.remainingPhotoGalleryUnlocks(policy: policy) ?? 0;
      final remainingStr = remainingFree.toString().toLocalizedDigits(languageCode);

      if (canUnlockFree) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2D2A) : const Color(0xFFE8F5F3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.themeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.themeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? '🔒 অতিরিক্ত $countTextটি ছবি দেখতে আনলক করুন' : '🔒 $countText Additional Photos Locked',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.teal.shade300 : AppColors.themeColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBn
                              ? 'আপনার ফ্রি ফটো গ্যালারি কোটা থেকে ১টি ব্যবহার করে এই বাসার সব ছবি দেখতে পারবেন। (বাকি: $remainingStrটি)'
                              : 'You can use 1 free photo gallery unlock credit to view all photos of this property. ($remainingStr remaining)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _handleUnlockPhotos(context, user, p.id, policy),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: Text(
                    isBn ? 'ফ্রি কোটায় গ্যালারি আনলক করুন ($remainingStr বাকি)' : 'Unlock Gallery ($remainingStr Left)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Out of free quota -> Show subscription purchase CTA
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D1F16) : const Color(0xFFFFF3EB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepOrange.shade400.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.deepOrange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? '🔒 অতিরিক্ত $countTextটি ছবি দেখতে সাবস্ক্রিপশন প্রয়োজন' : '🔒 $countText Additional Photos Locked',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.orange.shade300 : Colors.deepOrange.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBn
                            ? 'আপনার ফ্রি ফটো গ্যালারি কোটা শেষ হয়ে গেছে। বাড়িওয়ালার আপলোড করা অতিরিক্ত রুম ও ভেতরের সকল ছবির গ্যালারি এক্সেস পেতে সাপোর্ট প্যাকেজ গ্রহণ করুন।'
                            : 'Your free photo gallery unlock quota is exhausted. Activate a support package to unlock all additional interior and room photos uploaded by the landlord.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, TenantSubscriptionScreen.name),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                label: Text(
                  isBn ? 'সাপোর্ট প্যাকেজ দেখুন' : 'View Support Packages',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // --- LOGGED-IN TENANT WITH ACCESS: Additional Photos Gallery ---
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_library_rounded, size: 20, color: AppColors.themeColor),
                  const SizedBox(width: 8),
                  Text(
                    isBn ? 'অতিরিক্ত ছবিসমূহ ($countTextটি ছবি)' : 'Additional Photos ($countText Photos)',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    isBn ? 'জুম ভিউ' : 'Zoom View',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isBn ? 'বড় করে ও জুম (Zoom) করে দেখতে যেকোনো ছবিতে স্পর্শ করুন' : 'Tap any photo to open full-screen zoom viewer',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Gallery of Additional Photos
          SizedBox(
            height: 105,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: additionalImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final actualIndex = index + 1; // index 0 is template
                final imageSource = additionalImages[index];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      FullScreenImageViewer.show(
                        context,
                        images: p.images,
                        initialIndex: actualIndex,
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 125,
                          height: 105,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.themeColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppImageWidget(
                              imageSource: imageSource,
                              fit: BoxFit.cover,
                              width: 125,
                              height: 105,
                            ),
                          ),
                        ),

                        // Image Index Tag
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${(index + 1).toString().toLocalizedDigits(languageCode)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Zoom Icon on Top-Right
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(PropertyModel p, AppLocalizations l10n, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '৳ ${p.amount}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              '${l10n.perMonth} (${p.month.getLocalizedMonth(l10n)})',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.themeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            p.houseType.getLocalizedLabel(l10n),
            style: const TextStyle(
              color: AppColors.themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.themeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.themeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
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

  Future<void> _launchCaller(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
