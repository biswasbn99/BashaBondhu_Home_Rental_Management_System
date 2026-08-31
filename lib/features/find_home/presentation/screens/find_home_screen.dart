import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../ai_assistant/presentation/widgets/ai_floating_button.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../home_rent_post/presentations/widgets/property_location_picker_card.dart';
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
import '../../../subscription/data/providers/subscription_provider.dart';
import '../../../subscription/presentation/screens/tenant_subscription_screen.dart';
import '../providers/find_home_provider.dart';
import 'search_result.dart';

class FindHomeScreen extends StatelessWidget {
  const FindHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isGuest = userProvider.isGuest;

    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = FindHomeProvider();
        if (isGuest) {
          provider.setSearchMode(false); // Guest only gets Area search
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadDivisions(ctx.localizations);
          if (!isGuest) {
            provider.initLocationOnOpen(ctx.localizations);
          }
        });
        return provider;
      },
      child: const _FindHomeView(),
    );
  }
}

class _FindHomeView extends StatelessWidget {
  const _FindHomeView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FindHomeProvider>(context);
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      floatingActionButton: const AIFloatingButton(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (provider.errorMessage != null) ...[
                _ErrorBanner(message: provider.errorMessage!),
                const SizedBox(height: 12),
              ],

              // --- 1. Mode Switcher (Nearby Radius vs By Area) ---
              // Visible ONLY for Tenant user, completely hidden for Guest user
              if (!isGuest) ...[
                _buildModeSwitcher(context, provider, l10n, isDark),
                const SizedBox(height: 20),
              ],

              // --- 2. Dynamic Content Based on Search Mode ---
              if (!isGuest && provider.isRadiusSearchMode)
                _buildRadiusSearchForm(context, provider, l10n, theme, isDark)
              else
                _buildTraditionalAreaSearchForm(context, provider, l10n, theme),

              const SizedBox(height: 20),

              // --- 3. Optional Amenities Section ---
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
              const SizedBox(height: 24),

              // --- 4. Submit Search Button ---
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final isRadius = !isGuest && provider.isRadiusSearchMode;
                    if (isRadius ? true : provider.isSearchValid) {
                      _search(context, provider);
                    } else {
                      final errorMsg = isRadius
                          ? l10n.selectSearchCenterPrompt
                          : 'অনুগ্রহ করে সকল আবশ্যকীয় তথ্য (বিভাগ, জেলা, এলাকা, সাব-এলাকা, মাস, বাসার ধরন, বাজেট এবং ভাড়াটিয়ার ধরন) নির্বাচন করুন।';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMsg),
                          backgroundColor: Colors.redAccent,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    (!isGuest && provider.isRadiusSearchMode)
                        ? '${provider.searchRadiusKm.toInt()} km ${l10n.findHomeButton}'
                        : l10n.findHomeButton,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern Toggle Switcher for Search Mode
  Widget _buildModeSwitcher(
    BuildContext context,
    FindHomeProvider provider,
    dynamic l10n,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2827) : const Color(0xFFE8F3F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // 1. Nearby (Radius) Search Tab
          Expanded(
            child: InkWell(
              onTap: () => provider.setSearchMode(true),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: provider.isRadiusSearchMode
                      ? AppColors.themeColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: provider.isRadiusSearchMode
                      ? [
                          BoxShadow(
                            color: AppColors.themeColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 16,
                      color: provider.isRadiusSearchMode
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : const Color(0xFF4A5568)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.radiusSearchTab,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: provider.isRadiusSearchMode
                            ? Colors.white
                            : (isDark ? Colors.grey[400] : const Color(0xFF4A5568)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. By Area (Division/District) Tab
          Expanded(
            child: InkWell(
              onTap: () => provider.setSearchMode(false),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !provider.isRadiusSearchMode
                      ? AppColors.themeColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !provider.isRadiusSearchMode
                      ? [
                          BoxShadow(
                            color: AppColors.themeColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_city_rounded,
                      size: 16,
                      color: !provider.isRadiusSearchMode
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : const Color(0xFF4A5568)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.areaSearchTab,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: !provider.isRadiusSearchMode
                            ? Colors.white
                            : (isDark ? Colors.grey[400] : const Color(0xFF4A5568)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Advanced Radius Search Form Section
  Widget _buildRadiusSearchForm(
    BuildContext context,
    FindHomeProvider provider,
    dynamic l10n,
    ThemeData theme,
    bool isDark,
  ) {
    const radiusOptions = [1.0, 3.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Center Location Picker Card
        DecoratedSectionHeader(title: l10n.centerPoint),
        const SizedBox(height: 10),
        PropertyLocationPickerCard(
          latitude: provider.searchLatitude,
          longitude: provider.searchLongitude,
          onLocationChanged: (lat, lng) {
            if (lat != null && lng != null) {
              provider.setCenterLocation(lat, lng, 'Selected Location');
            } else {
              provider.setCenterLocation(0, 0, null);
            }
          },
        ),
        const SizedBox(height: 20),

        // 2. Radius Selection (5km, 10km, etc.)
        DecoratedSectionHeader(title: l10n.searchRadius),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2827) : const Color(0xFFF7FAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.searchRadiusSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.searchRadiusKm.toInt()} km',
                      style: const TextStyle(
                        color: AppColors.themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Radius Quick Chips (1km, 3km, 5km, 10km, 15km, 20km)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: radiusOptions.map((r) {
                  final isSelected = provider.searchRadiusKm == r;
                  return ChoiceChip(
                    label: Text('${r.toInt()} km'),
                    selected: isSelected,
                    selectedColor: AppColors.themeColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : const Color(0xFF2D3748)),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                    backgroundColor: isDark ? const Color(0xFF121918) : Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.themeColor
                          : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                    onSelected: (_) => provider.setRadiusKm(r),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Interactive Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.themeColor,
                  thumbColor: AppColors.themeColor,
                  overlayColor: AppColors.themeColor.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: provider.searchRadiusKm,
                  min: 1.0,
                  max: 30.0,
                  divisions: 29,
                  label: '${provider.searchRadiusKm.toInt()} km',
                  onChanged: (val) => provider.setRadiusKm(val),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Accommodation & Budget (Optional in Radius Search)
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
        const SizedBox(height: 14),

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
      ],
    );
  }

  /// Traditional Division/District Form Section
  Widget _buildTraditionalAreaSearchForm(
    BuildContext context,
    FindHomeProvider provider,
    dynamic l10n,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  void _search(BuildContext context, FindHomeProvider provider) async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    final isGuest = userProvider.isGuest || user == null;
    final isRadius = !isGuest && provider.isRadiusSearchMode;

    final l10n = context.localizations;

    if (isRadius) {
      if (!isGuest && !user.isSubscribed && user.freeRadiusSearchesRemaining <= 0) {
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
                    l10n.radiusLimitReachedTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              l10n.radiusLimitReachedSubtitle,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.maybeLater),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, TenantSubscriptionScreen.name);
                },
                child: Text(l10n.viewPackages),
              ),
            ],
          ),
        );
        return;
      }

      if (!isGuest && !user.isSubscribed) {
        await context.read<SubscriptionProvider>().incrementRadiusSearchCount(context, user);
      }
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResultScreen(filter: provider.buildFilter()),
        ),
      );
    }
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
