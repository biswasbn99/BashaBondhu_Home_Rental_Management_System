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
import '../../../subscription/data/providers/subscription_provider.dart';
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

  Future<void> _openGoogleMapsNavigation(double lat, double lng) async {
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

  void _handleUnlock(BuildContext context, UserModel? user) {
    if (user == null) {
      Navigator.pushNamed(context, SignInScreen.name);
      return;
    }

    if (user.freePropertyUnlocksRemaining <= 0 && !user.isSubscribed) {
      Navigator.pushNamed(context, TenantSubscriptionScreen.name);
      return;
    }

    final l10n = context.localizations;
    final languageCode = Localizations.localeOf(context).languageCode;

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
          l10n.unlockPropertyDialogContent(user.freePropertyUnlocksRemaining.toLocalizedDigits(languageCode)),
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

    final isUnlocked = PrivacyHelper.isPropertyUnlocked(
      propertyId: p.id,
      isGuest: isGuest,
      isSubscribed: user?.isSubscribed ?? false,
      unlockedPropertyIds: user?.unlockedPropertyIds ?? [],
    );

    final subAreaName = p.subArea?.getLocalizedName(languageCode) ?? '';
    final areaName = p.area.getLocalizedName(languageCode);
    final districtName = p.district.getLocalizedName(languageCode);

    final locationText = PrivacyHelper.formatLocationWithPrivacy(
      subAreaName: subAreaName,
      areaName: areaName,
      districtName: districtName,
      isUnlocked: isUnlocked,
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
            _buildImageGallery(p, isGuest, isDark, languageCode),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. Price and Type Row ---
                  _buildPriceSection(p, l10n, theme),
                  const SizedBox(height: 20),

                  // --- 2.1 Additional Photos Section (Gallery for Tenant / Login Lock for Guest) ---
                  _buildAdditionalPhotosSection(p, isGuest, isDark, languageCode),

                  // --- 3. Location Section with Sub-Area Privacy Mask ---
                  DecoratedSectionHeader(title: l10n.locationLabel),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.map_outlined, locationText),
                  if (p.shortAddress.isNotEmpty && isUnlocked)
                    _buildInfoRow(Icons.location_on_outlined, p.shortAddress),

                  // --- 4. Interactive Map Section (Locked Container if not unlocked) ---
                  if (p.latitude != null && p.longitude != null)
                    _buildMapSection(p, l10n, theme, isDark, isUnlocked, user),

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
                                  Text(
                                    p.contactName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  _buildBottomActionBar(context, p, isUnlocked, user, isGuest, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    PropertyModel p,
    bool isUnlocked,
    UserModel? user,
    bool isGuest,
    AppLocalizations l10n,
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

      final remaining = user?.freePropertyUnlocksRemaining ?? 0;

      if (remaining > 0) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _handleUnlock(context, user),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(
              l10n.unlockInfoAndNumberWithQuota(remaining.toLocalizedDigits(languageCode)),
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
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.lock_open_rounded, size: 16),
              label: Text(l10n.unlockMap, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _handleUnlock(context, user),
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
            onPressed: () => _openGoogleMapsNavigation(p.latitude!, p.longitude!),
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

  Widget _buildImageGallery(PropertyModel p, bool isGuest, bool isDark, String languageCode) {
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

    // Guest users can only see the 1st image (template), logged-in users can swipe between all photos
    final displayImages = isGuest ? [images.first] : images;

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
                    images: isGuest ? [images.first] : images,
                    initialIndex: isGuest ? 0 : index,
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
                    images: isGuest ? [images.first] : images,
                    initialIndex: isGuest ? 0 : _currentImageIndex,
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
                  if (isGuest && images.length > 1) ...[
                    const Icon(Icons.lock_rounded, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    isGuest
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
  /// - For Tenant (logged in): Shows horizontal gallery of additional photos with zoom support
  /// - For Guest: Shows locked banner with login prompt
  Widget _buildAdditionalPhotosSection(PropertyModel p, bool isGuest, bool isDark, String languageCode) {
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

    // --- LOGGED-IN TENANT: Additional Photos Gallery ---
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
