import 'package:flutter/material.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';

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
                      if (demand.bathrooms != null)
                        _facilityBadge(
                          icon: Icons.bathtub_outlined,
                          label: "${demand.bathrooms} ${l10n.bathroom}",
                        ),
                      if (demand.attachedBathrooms != null)
                        _facilityBadge(
                          icon: Icons.wash_outlined,
                          label: "${demand.attachedBathrooms} Attached Bath",
                        ),
                      if (demand.balconies != null)
                        _facilityBadge(
                          icon: Icons.balcony_outlined,
                          label: "${demand.balconies} ${l10n.balcony}",
                        ),
                      if (demand.floorNumber != null)
                        _facilityBadge(
                          icon: Icons.layers_outlined,
                          label: "${demand.floorNumber} ${l10n.floorNumber}",
                        ),
                      if (demand.hasLift == true)
                        _facilityBadge(
                          icon: Icons.elevator_outlined,
                          label: l10n.lift,
                        ),
                      if (demand.hasParking == true)
                        _facilityBadge(
                          icon: Icons.local_parking_rounded,
                          label: l10n.parking,
                        ),
                      if (demand.hasGivenNotice != null)
                        _facilityBadge(
                          icon: Icons.info_outline,
                          label: demand.hasGivenNotice! ? "নোটিশ দেওয়া হয়েছে" : "নোটিশ দেওয়া হয়নি",
                          color: demand.hasGivenNotice! ? Colors.teal : Colors.orange,
                        ),
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
                      demand.detailedDescription.isNotEmpty
                          ? demand.detailedDescription
                          : 'কোনো অতিরিক্ত বিবরণ দেওয়া হয়নি।',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, letterSpacing: 0.2),
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // --- Contact Actions ---
                  _buildContactActions(context, l10n),
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
              backgroundColor: AppColors.themeColor.withValues(alpha: 0.15),
              child: Text(
                demand.userName.isNotEmpty ? demand.userName[0].toUpperCase() : 'T',
                style: const TextStyle(
                  color: AppColors.themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        demand.userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "ভাড়াটিয়া",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "পোস্ট করেছেন: ${_formatDate(demand.postDate)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _facilityBadge({
    required IconData icon,
    required String label,
    Color color = AppColors.themeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContactActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('কল করুন: ${demand.userMobile}'),
                  backgroundColor: AppColors.themeColor,
                ),
              );
            },
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            label: Text(
              l10n.callNow,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              shadowColor: AppColors.themeColor.withValues(alpha: 0.4),
            ),
          ),
        ),
        if (demand.userWhatsApp.isNotEmpty) ...[
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('হোয়াটসঅ্যাপ: ${demand.userWhatsApp}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.chat_outlined, color: Colors.white, size: 26),
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘন্টা আগে';
    } else {
      return '${diff.inDays} দিন আগে';
    }
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
