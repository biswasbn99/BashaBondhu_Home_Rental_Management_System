import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/tenant_demand/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ShowDemandDetailsScreen extends StatelessWidget {
  const ShowDemandDetailsScreen({super.key, required this.demand});

  final TenantDemandModel demand;

  static const String name = '/show-demand-details';

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
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Profile ---
            _buildUserHeader(context, theme, l10n),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // --- Accommodation Section ---
                  DecoratedSectionHeader(title: l10n.accommodationPromptTitle),
                  const SizedBox(height: 16),
                  _DetailTile(
                    icon: Icons.calendar_today_rounded,
                    label: l10n.month,
                    value: demand.month,
                  ),
                  _DetailTile(
                    icon: Icons.home_work_outlined,
                    label: l10n.houseType,
                    value: demand.houseType.getLocalizedLabel(l10n),
                  ),
                  _DetailTile(
                    icon: Icons.bed_outlined,
                    label: l10n.roomOrSeat,
                    value: demand.roomOrSeat,
                  ),
                  
                  const SizedBox(height: 28),

                  // --- Location Section ---
                  DecoratedSectionHeader(title: l10n.locationLabel),
                  const SizedBox(height: 16),
                  _DetailTile(
                    icon: Icons.map_outlined,
                    label: l10n.division,
                    value: demand.division.getLocalizedName(languageCode),
                  ),
                  _DetailTile(
                    icon: Icons.location_city_rounded,
                    label: l10n.district,
                    value: demand.district.getLocalizedName(languageCode),
                  ),
                  _DetailTile(
                    icon: Icons.pin_drop_rounded,
                    label: l10n.upazila,
                    value: demand.area.getLocalizedName(languageCode),
                  ),
                  if (demand.shortAddress.isNotEmpty)
                    _DetailTile(
                      icon: Icons.home_outlined,
                      label: l10n.shortAddress,
                      value: demand.shortAddress,
                    ),
                  
                  const SizedBox(height: 28),

                  // --- Budget Section ---
                  DecoratedSectionHeader(title: l10n.budgetTenantPromptTitle),
                  const SizedBox(height: 16),
                  _DetailTile(
                    icon: Icons.payments_outlined,
                    label: l10n.budget,
                    value: "${demand.budgetRange ?? 'Any'} ৳",
                    valueColor: AppColors.themeColor,
                    isBoldValue: true,
                  ),
                  _DetailTile(
                    icon: Icons.people_outline_rounded,
                    label: l10n.tenantType,
                    value: demand.tenantType?.getLocalizedLabel(l10n) ?? 'Any',
                  ),
                  
                  const SizedBox(height: 28),

                  // --- Facilities Section ---
                  DecoratedSectionHeader(title: l10n.facilitiesLabel),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (demand.bathrooms != null) _buildAmenityChip(theme, Icons.bathtub_outlined, "${demand.bathrooms} ${l10n.bathroom}"),
                      if (demand.kitchenCount != null) _buildAmenityChip(theme, Icons.kitchen_outlined, "${demand.kitchenCount} ${l10n.kitchen}"),
                      if (demand.hasWifi == true) _buildAmenityChip(theme, Icons.wifi_rounded, l10n.wifi),
                      if (demand.hasLift == true) _buildAmenityChip(theme, Icons.elevator_outlined, l10n.lift),
                      if (demand.hasParking == true) _buildAmenityChip(theme, Icons.local_parking_rounded, l10n.parking),
                      if (demand.hasCctv == true) _buildAmenityChip(theme, Icons.videocam_outlined, l10n.cctv),
                      if (demand.hasGenerator == true) _buildAmenityChip(theme, Icons.bolt_rounded, l10n.generator),
                    ],
                  ),
                  
                  const SizedBox(height: 28),

                  // --- Description Section ---
                  DecoratedSectionHeader(title: l10n.descriptionLabel),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      demand.detailedDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, letterSpacing: 0.2),
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // --- Contact Actions ---
                  _buildContactActions(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.themeColor.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.themeColor.withValues(alpha: 0.1),
              child: const Icon(Icons.person_rounded, color: AppColors.themeColor, size: 45),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demand.userName,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${l10n.postIdLabel}: ${demand.id}",
                    style: theme.textTheme.labelMedium?.copyWith(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.themeColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildContactActions(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.call_rounded, size: 20),
            label: Text(l10n.callNow, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              shadowColor: AppColors.themeColor.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF25D366),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.message_rounded, color: Colors.white, size: 26),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBoldValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBoldValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.themeColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isBoldValue ? FontWeight.w900 : FontWeight.w600,
                    color: valueColor ?? theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
