import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                  _buildInfoRow(Icons.location_on_outlined, p.shortAddress),
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
                      _buildAmenityChip(Icons.bed_outlined, p.roomOrSeat, theme),
                      if (p.floorNumber != null)
                        _buildAmenityChip(Icons.stairs_outlined, 'Floor: ${p.floorNumber}', theme),
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
                      if (p.hasCctv == true)
                        _buildAmenityChip(Icons.videocam_outlined, l10n.cctv, theme),
                      if (p.hasSecurityGuard == true)
                        _buildAmenityChip(Icons.security_outlined, l10n.securityGuard, theme),
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
              if (images.length > 1)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / ${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.themeColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: AppImageWidget(
                      imageSource: images[index],
                      borderRadius: BorderRadius.circular(6),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceSection(PropertyModel p, dynamic l10n, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "৳ ${p.amount}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.themeColor),
            ),
            Text(l10n.perMonth, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.houseType.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (p.tenantType != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.tenantType!.getLocalizedLabel(l10n),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.month}: ${p.month}',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.themeColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
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
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButtons(PropertyModel p, dynamic l10n) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('কল করুন: ${p.userMobile}'),
                  backgroundColor: AppColors.themeColor,
                ),
              );
            },
            icon: const Icon(Icons.call_rounded),
            label: Text(l10n.callNow),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
          child: IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('হোয়াটসঅ্যাপ: ${p.userWhatsApp}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.chat_outlined, color: Colors.white),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
