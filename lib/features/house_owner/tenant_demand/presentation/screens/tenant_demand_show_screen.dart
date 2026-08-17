import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/tenant_demand/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/tenant_demand/presentation/screens/show_demand_details_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class TenantDemandShowScreen extends StatelessWidget {
  const TenantDemandShowScreen({super.key});

  static const String name = '/tenant-demand-show';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);

    // Dummy Data for demonstration
    final List<TenantDemandModel> demands = [
      TenantDemandModel(
        id: 'DEM-9001',
        month: 'September',
        houseType: HouseType.flat,
        roomOrSeat: '3 Bed',
        division: DivisionModel(id: '1', name: 'Dhaka', bnName: 'ঢাকা'),
        district: DistrictModel(id: '1', divisionId: '1', name: 'Dhaka', bnName: 'ঢাকা'),
        area: UpazilaModel(id: '1', districtId: '1', name: 'Uttara', bnName: 'উত্তরা'),
        budgetRange: '25000',
        tenantType: TenantType.family,
        userName: 'Ariful Islam',
        userMobile: '01711223344',
        userWhatsApp: '01711223344',
        shortAddress: 'Sector 10, Road 12',
        detailedDescription: 'I need a flat for my family in Uttara area. Preferred near metro station. Must have 3 bedrooms and lift.',
        postDate: DateTime.now().subtract(const Duration(hours: 2)),
        bathrooms: 3,
        kitchenCount: 1,
        hasLift: true,
      ),
      TenantDemandModel(
        id: 'DEM-9002',
        month: 'October',
        houseType: HouseType.room,
        roomOrSeat: '1 Room',
        division: DivisionModel(id: '1', name: 'Dhaka', bnName: 'ঢাকা'),
        district: DistrictModel(id: '1', divisionId: '1', name: 'Dhaka', bnName: 'ঢাকা'),
        area: UpazilaModel(id: '2', districtId: '1', name: 'Mirpur', bnName: 'মিরপুর'),
        budgetRange: '8000',
        tenantType: TenantType.bachelorMale,
        userName: 'Sabbir Ahmed',
        userMobile: '01911223344',
        userWhatsApp: '01911223344',
        shortAddress: 'Mirpur 10, Block C',
        detailedDescription: 'Single room needed for a student. Wifi is a must. Close to the main road.',
        postDate: DateTime.now().subtract(const Duration(days: 1)),
        hasWifi: true,
      ),
    ];

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.demand,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: demands.length,
        separatorBuilder: (_, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _DemandCard(demand: demands[index]);
        },
      ),
    );
  }
}

class _DemandCard extends StatelessWidget {
  const _DemandCard({required this.demand});

  final TenantDemandModel demand;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Name and Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.themeColor.withValues(alpha: 0.15),
                  AppColors.themeColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.themeColor,
                  child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demand.userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "${l10n.postedOn}: ${_formatDate(demand.postDate)}",
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    "${demand.budgetRange ?? 'Any'} ৳",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IconDetail(
                      icon: Icons.home_work_rounded,
                      label: "${demand.houseType.getLocalizedLabel(l10n)} - ${demand.roomOrSeat}",
                    ),
                    _IconDetail(
                      icon: Icons.calendar_month_rounded,
                      label: demand.month,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                
                // Location Row
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 18, color: AppColors.themeColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${demand.area.getLocalizedName(languageCode)}, ${demand.district.getLocalizedName(languageCode)}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Description Snippet
                Text(
                  demand.detailedDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Bottom Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        ShowDemandDetailsScreen.name,
                        arguments: demand,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.viewDetails,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simplified formatter
    return "${date.day}/${date.month}/${date.year}";
  }
}

class _IconDetail extends StatelessWidget {
  const _IconDetail({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
      ],
    );
  }
}
