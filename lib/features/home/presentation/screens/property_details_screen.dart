import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/data/models/property_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PropertyDetailsScreen extends StatelessWidget {
  const PropertyDetailsScreen({super.key, required this.property});

  final PropertyModel property;

  static const String name = '/property-details';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

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
            // --- Image Slider (Simplified as Placeholder) ---
            _buildImageGallery(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceSection(l10n),
                  const SizedBox(height: 24),

                  DecoratedSectionHeader(title: l10n.locationLabel),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.map_outlined, "${property.area.getLocalizedName(languageCode)}, ${property.district.getLocalizedName(languageCode)}"),
                  _buildInfoRow(Icons.location_on_outlined, property.shortAddress),
                  const SizedBox(height: 24),

                  DecoratedSectionHeader(title: l10n.facilitiesLabel),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildAmenityChip(Icons.bed_outlined, property.roomOrSeat),
                      if (property.commonBathrooms != null)
                        _buildAmenityChip(Icons.bathtub_outlined, "${property.commonBathrooms} ${l10n.commonBathroom}"),
                      if (property.hasWifi == true)
                        _buildAmenityChip(Icons.wifi_rounded, l10n.wifi),
                      if (property.hasLift == true)
                        _buildAmenityChip(Icons.elevator_outlined, l10n.lift),
                      if (property.hasParking == true)
                        _buildAmenityChip(Icons.local_parking_rounded, l10n.parking),
                    ],
                  ),
                  const SizedBox(height: 24),

                  DecoratedSectionHeader(title: l10n.descriptionLabel),
                  const SizedBox(height: 12),
                  Text(
                    property.detailedDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  _buildContactButtons(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: property.images.isNotEmpty
          ? Image.network(property.images[0], fit: BoxFit.cover)
          : const Icon(Icons.home_work_outlined, size: 80, color: Colors.grey),
    );
  }

  Widget _buildPriceSection(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${property.amount} ৳",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.themeColor),
            ),
            Text(l10n.perMonth, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.themeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            property.id,
            style: const TextStyle(color: AppColors.themeColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.themeColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildContactButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.call_rounded),
            label: Text(l10n.callNow),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.message_rounded, color: Colors.white),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
