import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/data/models/search_filter_model.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/app_network_image.dart';
import '../../../shared/presentation/widgets/decorated_section_header.dart';
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

      final distanceKm = distanceMeters / 1000;
      if (mounted) {
        final l10n = context.localizations;
        final isBn = l10n.localeName == 'bn';

        String formatNum(String s) {
          if (!isBn) return s;
          const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
          const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
          var res = s;
          for (int i = 0; i < 10; i++) {
            res = res.replaceAll(en[i], bn[i]);
          }
          return res;
        }

        final distStr = distanceKm < 1.0
            ? '${formatNum(distanceMeters.toStringAsFixed(0))} ${isBn ? "মিটার" : "m"}'
            : '${formatNum(distanceKm.toStringAsFixed(1))} ${isBn ? "কিমি" : "km"}';

        setState(() {
          _tenantDistanceString = '$distStr ${l10n.distanceAway}';
        });
      }
    } catch (_) {}
  }

  Future<void> _openGoogleMapsNavigation(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching Google Maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final p = widget.property;

    final locationText = [
      if (p.subArea != null) p.subArea!.getLocalizedName(languageCode),
      p.area.getLocalizedName(languageCode),
      p.district.getLocalizedName(languageCode),
    ].join(', ');

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
            // --- Interactive Image Slider Gallery ---
            _buildImageGallery(p),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Type Row
                  _buildPriceSection(p, l10n, theme),
                  const SizedBox(height: 20),

                  // Location Section
                  DecoratedSectionHeader(title: l10n.locationLabel),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.map_outlined, locationText),
                  if (p.shortAddress.isNotEmpty)
                    _buildInfoRow(Icons.location_on_outlined, p.shortAddress),

                  // Interactive Map & Navigation Card (If coordinates are provided)
                  if (p.latitude != null && p.longitude != null)
                    _buildMapSection(p, l10n, theme, isDark),

                  const SizedBox(height: 24),

                  // Facilities Section
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
                      if (p.marketDistance != null && p.marketDistance!.isNotEmpty)
                        _buildAmenityChip(Icons.storefront_outlined, '${l10n.marketDistance}: ${p.marketDistance}', theme),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description Section
                  DecoratedSectionHeader(title: l10n.descriptionLabel),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      p.detailedDescription.isNotEmpty ? p.detailedDescription : 'কোনো অতিরিক্ত বিবরণ দেওয়া হয়নি।',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contact Person Section
                  DecoratedSectionHeader(title: l10n.contactPerson),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.themeColor.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppColors.themeColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.contactName.isNotEmpty ? p.contactName : 'House Owner',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.userMobile,
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildContactButtons(p, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(PropertyModel p, AppLocalizations l10n, ThemeData theme, bool isDark) {
    if (p.latitude == null || p.longitude == null) return const SizedBox.shrink();

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

  Widget _buildImageGallery(PropertyModel p) {
    final images = p.images;

    if (images.isEmpty) {
      return Container(
        height: 240,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.home_work_outlined, size: 64, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          width: double.infinity,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return AppImageWidget(
                    imageSource: images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                  );
                },
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildContactButtons(PropertyModel p, AppLocalizations l10n) {
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
