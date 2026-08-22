import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/bathroom_dropdown_button.dart';
import '../../../shared/presentation/widgets/belcony_dropdown_button.dart';
import '../../../shared/presentation/widgets/budget_dropdown_button.dart';
import '../../../shared/presentation/widgets/decorated_section_header.dart';
import '../../../shared/presentation/widgets/floor_number_dropdown_button.dart';
import '../../../shared/presentation/widgets/house_type_dropdown_button.dart';
import '../../../shared/presentation/widgets/lift_dropdown_button.dart';
import '../../../shared/presentation/widgets/location_dropdown.dart';
import '../../../shared/presentation/widgets/month_dropdown_button.dart';
import '../../../shared/presentation/widgets/number_of_room_or_seat_dropdown_button.dart';
import '../../../shared/presentation/widgets/parking_dropdown_button.dart';
import '../../../shared/presentation/widgets/post_icon.dart';
import '../../../shared/presentation/widgets/tenant_type_dropdown_button.dart';
import '../providers/find_home_provider.dart';
import 'search_result.dart';

class FindHomeScreen extends StatelessWidget {
  const FindHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = FindHomeProvider();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadDivisions(ctx.localizations);
        });
        return provider;
      },
      child: const _FindHomeView(),
    );
  }
}

class _FindHomeView extends StatelessWidget {
  const _FindHomeView();

  static const Color _grey = Color(0xFF7A8A88);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FindHomeProvider>(context);
    final l10n = context.localizations;
    final userProvider = Provider.of<UserProvider>(context);
    final bool isGuest = userProvider.isGuest;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: isGuest ? 12 : 20,
        actions: isGuest
            ? [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FreePostButton(),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.errorMessage != null) ...[
                _ErrorBanner(message: provider.errorMessage!),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),

              // ==========================================
              // 1. REQUIRED FIELDS SECTION
              // ==========================================
              DecoratedSectionHeader(title: l10n.accommodationPromptTitle),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: MonthDropdown(
                      value: provider.selectedMonth,
                      months: FindHomeProvider.months,
                      onChanged: provider.selectMonth,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HouseTypeDropdown(
                      value: provider.selectedHouseType,
                      houseTypes: FindHomeProvider.houseTypes,
                      onChanged: provider.selectHouseType,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // -------- Location (Required) --------
              DecoratedSectionHeader(title: l10n.locationPromptTitle),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DivisionDropdown(
                      value: provider.selectedDivision,
                      divisions: provider.divisions,
                      isLoading: provider.isLoadingDivisions,
                      onChanged: (val) => provider.selectDivision(val, l10n),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DistrictDropdown(
                      value: provider.selectedDistrict,
                      districts: provider.districts,
                      enabled: provider.selectedDivision != null,
                      isLoading: provider.isLoadingDistricts,
                      onChanged: (val) => provider.selectDistrict(val, l10n),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: UpazilaDropdown(
                      value: provider.selectedUpazila,
                      upazilas: provider.upazilas,
                      enabled: provider.selectedDistrict != null,
                      isLoading: provider.isLoadingUpazilas,
                      onChanged: (val) => provider.selectUpazila(val, l10n),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AreaDropdown(
                      value: provider.selectedArea,
                      areas: provider.areas,
                      enabled: provider.selectedUpazila != null,
                      isLoading: provider.isLoadingAreas,
                      onChanged: provider.selectArea,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // -------- Budget & Tenant Type (Required) --------
              DecoratedSectionHeader(title: l10n.budgetTenantPromptTitle),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: BudgetDropdown(
                      value: provider.selectedBudgetRange,
                      ranges: FindHomeProvider.budgetRanges,
                      onChanged: provider.selectBudget,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TenantTypeDropdown(
                      value: provider.selectedTenantType,
                      onChanged: provider.selectTenantType,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ==========================================
              // 2. OPTIONAL PREFERENCES SECTION
              // ==========================================
              DecoratedSectionHeader(
                title: '${l10n.amenitiesPromptTitle} (${l10n.optional})',
              ),
              const SizedBox(height: 12),

              // Room / Seat count (Optional)
              RoomOrSeatDropdown(
                hint: '${provider.roomOrSeatHint(l10n)} (${l10n.optional})',
                value: provider.selectedRoomOrSeat,
                enabled: provider.selectedHouseType != null,
                options: provider.roomOrSeatOptions(l10n),
                onChanged: provider.selectRoomOrSeat,
              ),
              const SizedBox(height: 12),

              // Bathrooms & Balcony (Optional)
              Row(
                children: [
                  Expanded(
                    child: BathroomDropdown(
                      value: provider.selectedBathrooms,
                      onChanged: provider.selectBathrooms,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BalconyDropdown(
                      value: provider.selectedBalconies,
                      onChanged: provider.selectBalconies,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Floor & Lift (Optional)
              Row(
                children: [
                  Expanded(
                    child: FloorNumberDropdown(
                      value: provider.selectedFloorNumber,
                      onChanged: provider.selectFloor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LiftDropdown(
                      value: provider.hasLift,
                      onChanged: provider.selectLift,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Parking (Optional)
              ParkingDropdown(
                value: provider.hasParking,
                onChanged: provider.selectParking,
              ),
              const SizedBox(height: 20),

              Text(
                l10n.findHomePrompt,
                style: const TextStyle(color: _grey, fontSize: 13.5),
              ),
              const SizedBox(height: 16),

              // Find Home Button
              FilledButton(
                onPressed: () {
                  if (provider.isSearchValid) {
                    _search(context, provider);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('অনুগ্রহ করে সকল আবশ্যকীয় তথ্য (বিভাগ, জেলা, এলাকা, সাব-এলাকা, মাস, বাসার ধরন, বাজেট এবং ভাড়াটিয়ার ধরন) নির্বাচন করুন।'),
                        backgroundColor: Colors.redAccent,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Text(l10n.findHomeButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _search(BuildContext context, FindHomeProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultScreen(filter: provider.buildFilter()),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
