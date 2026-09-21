import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../ai_assistant/presentation/widgets/ai_floating_button.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../home_rent_post/presentations/widgets/property_location_picker_card.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';
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
import '../../../home/data/models/property_model.dart';
import '../../../shared/data/models/district_model.dart';
import '../../../shared/data/models/area_model.dart';
import '../../../shared/data/models/sub_area_model.dart';
import '../../../subscription/data/models/free_tier_policy_model.dart';
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
    final user = userProvider.user;
    final bool isGuest = userProvider.isGuest || user == null;
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final policy = subProvider.currentPolicy ?? FreeTierPolicyModel.defaultPolicy();
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';

    final bool isRadius = !isGuest && provider.isRadiusSearchMode;
    final bool canPerformNearby = !isRadius || user.canPerformNearbySearchForPolicy(policy: policy);
    final int remainingNearby = user?.remainingNearbySearchesForPolicy(policy: policy) ?? 0;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: isGuest ? 12 : 20,
        actions: [
          if (isGuest)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: FreePostButton(),
            ),
          const LanguageActionButton(),
        ],
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
                const SizedBox(height: 14),
                if (provider.isRadiusSearchMode) ...[
                  _buildNearbyQuotaStatusCard(
                    context: context,
                    user: user,
                    policy: policy,
                    isBn: isBn,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                ],
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
                enabled: true,
                isRequired: false,
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
                    final isRadiusMode = !isGuest && provider.isRadiusSearchMode;

                    // 1. Quota Check for Radius Mode: If limit is already reached, prompt upgrade
                    if (isRadiusMode && !canPerformNearby) {
                      _showQuotaExhaustedDialog(
                        context: context,
                        user: user,
                        policy: policy,
                        isBn: isBn,
                        languageCode: languageCode,
                        l10n: l10n,
                      );
                      return;
                    }

                    // 2. Strict Required Fields Validation
                    if (!provider.isSearchValid) {
                      provider.setValidationErrors(true);
                      final missingFields = provider.getMissingRequiredFields(l10n, isBn);
                      final String missingStr = missingFields.join(', ');
                      final errorMsg = isBn
                          ? 'অনুগ্রহ করে আবশ্যকীয় তথ্য নির্বাচন করুন: $missingStr'
                          : 'Please select required fields: $missingStr';

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMsg,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red.shade700,
                          duration: const Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }

                    // 3. Search inputs valid -> clear validation error and proceed
                    provider.setValidationErrors(false);
                    _search(context, provider, policy);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: (!canPerformNearby && isRadius)
                        ? Colors.deepOrange
                        : AppColors.themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: (!canPerformNearby && isRadius)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              isBn ? 'প্যাকেজ আপগ্রেড করুন (সার্চ সীমা শেষ)' : 'Upgrade Plan (Limit Reached)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                          ],
                        )
                      : Text(
                          isRadius
                              ? (remainingNearby >= 999
                                  ? '${provider.searchRadiusKm.toInt()} km ${l10n.findHomeButton} (${isBn ? "আনলিমিটেড" : "Unlimited"})'
                                  : '${provider.searchRadiusKm.toInt()} km ${l10n.findHomeButton} (${remainingNearby.toString().toLocalizedDigits(languageCode)} ${isBn ? "বাকি" : "Left"})')
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

  void _updateCenterFromDistrict(FindHomeProvider provider, DistrictModel district) {
    if (district.coordinates != null && district.coordinates!.isNotEmpty) {
      final parts = district.coordinates!.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          provider.setCenterLocation(lat, lng, district.name);
          return;
        }
      }
    }
    final lat = PropertyModel.resolveFallbackLat(district.name, provider.selectedDivision?.name ?? '');
    final lng = PropertyModel.resolveFallbackLng(district.name, provider.selectedDivision?.name ?? '');
    if (lat != null && lng != null) {
      provider.setCenterLocation(lat, lng, district.name);
    }
  }

  void _updateCenterFromUpazila(FindHomeProvider provider, UpazilaModel upazila) {
    if (upazila.coordinates != null && upazila.coordinates!.isNotEmpty) {
      final parts = upazila.coordinates!.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          provider.setCenterLocation(lat, lng, '${upazila.name}, ${provider.selectedDistrict?.name ?? ""}');
          return;
        }
      }
    }
    if (provider.selectedDistrict != null) {
      _updateCenterFromDistrict(provider, provider.selectedDistrict!);
    }
  }

  void _updateCenterFromArea(FindHomeProvider provider, UnionModel area) {
    if (area.coordinates != null && area.coordinates!.isNotEmpty) {
      final parts = area.coordinates!.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          provider.setCenterLocation(lat, lng, '${area.name}, ${provider.selectedUpazila?.name ?? ""}');
          return;
        }
      }
    }
    if (provider.selectedUpazila != null) {
      _updateCenterFromUpazila(provider, provider.selectedUpazila!);
    }
  }

  Widget _buildQuickAreaCenterPicker(
    BuildContext context,
    FindHomeProvider provider,
    dynamic l10n,
    bool isDark,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E2827) : const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.location_city_rounded, color: AppColors.themeColor, size: 20),
          title: Text(
            isBn ? 'অথবা ড্রপডাউন থেকে এরিয়া বেছে নিয়ে সেন্টার সেট করুন' : 'Or Select Area from Dropdown as Center',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: provider.selectedUpazila != null
              ? Text(
                  '${provider.selectedUpazila!.getLocalizedName(languageCode)}, ${provider.selectedDistrict?.getLocalizedName(languageCode) ?? ""}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.themeColor, fontWeight: FontWeight.bold),
                )
              : Text(
                  isBn ? 'ড্রপডাউন থেকে বিভাগ, জেলা ও থানা নির্বাচন করুন' : 'Select division, district & upazila',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
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
                          onChanged: (val) {
                            provider.selectDistrict(val, l10n);
                            if (val != null) {
                              _updateCenterFromDistrict(provider, val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: UpazilaDropdown(
                          value: provider.selectedUpazila,
                          upazilas: provider.upazilas,
                          enabled: provider.selectedDistrict != null,
                          isLoading: provider.isLoadingUpazilas,
                          onChanged: (val) {
                            provider.selectUpazila(val, l10n);
                            if (val != null) {
                              _updateCenterFromUpazila(provider, val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AreaDropdown(
                          value: provider.selectedArea,
                          areas: provider.areas,
                          enabled: provider.selectedUpazila != null,
                          isLoading: provider.isLoadingAreas,
                          onChanged: (val) {
                            provider.selectArea(val);
                            if (val != null) {
                              _updateCenterFromArea(provider, val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Center Location Picker Card (Required)
        DecoratedSectionHeader(
          title: '${l10n.centerPoint} (${isBn ? "আবশ্যক" : "Required"})',
        ),
        const SizedBox(height: 10),
        if (provider.showValidationErrors && (provider.searchLatitude == 0 || provider.searchLongitude == 0)) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBn
                        ? 'সেন্টার পয়েন্ট আবশ্যক: অনুগ্রহ করে মানচিত্রে পিন করুন অথবা নিচের ড্রপডাউন ব্যবহার করুন।'
                        : 'Center point required: Please pin on map or use the dropdown below.',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: (provider.showValidationErrors && (provider.searchLatitude == 0 || provider.searchLongitude == 0))
                ? Border.all(color: Colors.redAccent, width: 1.5)
                : null,
          ),
          child: PropertyLocationPickerCard(
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
        ),
        const SizedBox(height: 10),
        _buildQuickAreaCenterPicker(context, provider, l10n, isDark),
        const SizedBox(height: 20),

        // 2. Radius Selection (Required: 1km, 3km, 5km, 10km, 15km, 20km, 25km, 30km)
        DecoratedSectionHeader(
          title: '${l10n.searchRadius} (${isBn ? "আবশ্যক" : "Required"})',
        ),
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

              // Radius Quick Chips (1km, 3km, 5km, 10km, 15km, 20km, 25km, 30km)
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
        DecoratedSectionHeader(
          title: '${l10n.accommodationPromptTitle} (${l10n.optional})',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MonthDropdown(
                value: provider.selectedMonth,
                months: FindHomeProvider.months,
                isRequired: false,
                onChanged: provider.selectMonth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HouseTypeDropdown(
                value: provider.selectedHouseType,
                houseTypes: FindHomeProvider.houseTypes,
                isRequired: false,
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
                isRequired: false,
                onChanged: provider.selectBudget,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TenantTypeDropdown(
                value: provider.selectedTenantType,
                isRequired: false,
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
        
        // 1. REQUIRED FIELDS SECTION
        
        DecoratedSectionHeader(title: l10n.accommodationPromptTitle),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MonthDropdown(
                value: provider.selectedMonth,
                months: FindHomeProvider.months,
                isRequired: true,
                showErrors: provider.showValidationErrors &&
                    (provider.selectedMonth == null || provider.selectedMonth!.isEmpty),
                onChanged: provider.selectMonth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HouseTypeDropdown(
                value: provider.selectedHouseType,
                houseTypes: FindHomeProvider.houseTypes,
                isRequired: true,
                showErrors: provider.showValidationErrors && (provider.selectedHouseType == null),
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
                showErrors: provider.showValidationErrors && (provider.selectedDivision == null),
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
                showErrors: provider.showValidationErrors && (provider.selectedDistrict == null),
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
                showErrors: provider.showValidationErrors && (provider.selectedUpazila == null),
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
                isRequired: false,
                showErrors: false,
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
                isRequired: true,
                showErrors: provider.showValidationErrors &&
                    (provider.selectedBudgetRange == null || provider.selectedBudgetRange!.isEmpty),
                onChanged: provider.selectBudget,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TenantTypeDropdown(
                value: provider.selectedTenantType,
                isRequired: true,
                showErrors: provider.showValidationErrors && (provider.selectedTenantType == null),
                onChanged: provider.selectTenantType,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNearbyQuotaStatusCard({
    required BuildContext context,
    required UserModel user,
    required FreeTierPolicyModel policy,
    required bool isBn,
    required bool isDark,
  }) {
    final bool isSub = user.isSubscribed;
    final bool canPerform = user.canPerformNearbySearchForPolicy(policy: policy);
    final int remaining = user.remainingNearbySearchesForPolicy(policy: policy);

    // Free account total limit
    final int freeTotalLimit = policy.tenantNearbySearches;
    final String freeTotalLimitStr = freeTotalLimit.toString().toLocalizedDigits(isBn ? 'bn' : 'en');
    final String remainingStr = remaining.toString().toLocalizedDigits(isBn ? 'bn' : 'en');

    // Quota exhausted or disabled -> Alert Card
    if (!canPerform) {
      String titleText;
      String descText;

      if (isSub) {
        if (user.activePlans.isNotEmpty && user.activePlans.every((p) => p.nearbySearchLimit == 0)) {
          titleText = isBn ? '🔒 প্যাকেজে কাছাকাছি সার্চ সুবিধা নেই' : '🔒 Nearby Search Not in Package';
          descText = isBn
              ? 'আপনার বর্তমান সাবস্ক্রিপশন প্যাকেজে নিকটবর্তী এরিয়া সার্চের সুবিধা অন্তর্ভুক্ত নেই। এই সুবিধা পেতে উচ্চতর প্যাকেজ আপগ্রেড করুন।'
              : 'Nearby radius search is not included in your current subscription plan. Please upgrade to a higher package.';
        } else {
          titleText = isBn ? '⚠️ নিকটবর্তী সার্চ কোটা শেষ' : '⚠️ Nearby Search Quota Reached';
          descText = isBn
              ? 'আপনার বর্তমান প্যাকেজের নিকটবর্তী এরিয়া সার্চের কোটা শেষ হয়ে গেছে। আনলিমিটেড বা অতিরিক্ত সার্চ সুবিধা পেতে প্যাকেজ আপগ্রেড করুন।'
              : 'You have reached your package limit for nearby searches. Please upgrade your package for additional searches.';
        }
      } else {
        if (freeTotalLimit <= 0) {
          titleText = isBn ? '🔒 ফ্রি অ্যাকাউন্টে কাছাকাছি সার্চ বন্ধ' : '🔒 Nearby Search Disabled';
          descText = isBn
              ? 'ফ্রি অ্যাকাউন্টে কাছাকাছি (দূরত্ব অনুযায়ী) সার্চের সুবিধা বন্ধ আছে। এই সুবিধা উপভোগ করতে সাবস্ক্রিপশন প্যাকেজ গ্রহণ করুন।'
              : 'Nearby radius search is disabled on free accounts. Upgrade to a subscription package to enjoy nearby search.';
        } else {
          titleText = isBn ? '⚠️ কাছাকাছি সার্চের ফ্রি সীমা শেষ' : '⚠️ Free Nearby Search Limit Reached';
          descText = isBn
              ? 'আপনার ফ্রি $freeTotalLimitStrটি কাছাকাছি (রেডিয়াস) সার্চের কোটা শেষ হয়ে গেছে। আনলিমিটেড বা অতিরিক্ত সার্চ সুবিধা পেতে প্যাকেজ আপগ্রেড করুন।'
              : 'You have used all $freeTotalLimitStr free nearby radius searches. Please activate a subscription package for additional searches.';
        }
      }

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D1810) : const Color(0xFFFFF3EB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.deepOrange.shade400.withValues(alpha: 0.7), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.deepOrange, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.orange.shade300 : Colors.deepOrange.shade900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        descText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, TenantSubscriptionScreen.name),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                label: Text(
                  isBn ? 'প্যাকেজ আপগ্রেড করুন' : 'Upgrade Plan',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Active Quota Remaining Card
    String quotaText;
    if (isSub) {
      if (remaining >= 999) {
        quotaText = isBn ? 'প্যাকেজ কোটায় নিকটবর্তী সার্চ: আনলিমিটেড' : 'Package Nearby Search: Unlimited';
      } else {
        quotaText = isBn
            ? 'প্যাকেজ কোটায় নিকটবর্তী সার্চ: $remainingStrটি বাকি'
            : 'Package Nearby Search: $remainingStr Left';
      }
    } else {
      if (freeTotalLimit == -1) {
        quotaText = isBn ? 'ফ্রি কোটায় কাছাকাছি সার্চ: আনলিমিটেড' : 'Free Nearby Search: Unlimited';
      } else {
        quotaText = isBn
            ? 'ফ্রি কোটায় কাছাকাছি সার্চ: $remainingStrটি বাকি (মোট $freeTotalLimitStrটি)'
            : 'Free Nearby Search: $remainingStr Left (Total $freeTotalLimitStr)';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF142422) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.teal.shade700 : Colors.teal.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar_rounded, size: 18, color: AppColors.themeColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quotaText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.teal.shade200 : const Color(0xFF0F5132),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBn
                      ? 'মানচিত্রে নির্দিষ্ট পয়েন্ট নির্বাচন করে নির্দিষ্ট দূরত্বের মধ্যে বাসা খুঁজুন।'
                      : 'Pick a center point on map to discover homes within your desired radius.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuotaExhaustedDialog({
    required BuildContext context,
    required UserModel user,
    required FreeTierPolicyModel policy,
    required bool isBn,
    required String languageCode,
    required dynamic l10n,
  }) {
    final int freeLimit = policy.tenantNearbySearches;
    final String freeLimitStr = freeLimit.toString().toLocalizedDigits(languageCode);

    String dialogTitle;
    String dialogContent;

    if (user.isSubscribed) {
      dialogTitle = isBn ? 'নিকটবর্তী সার্চ কোটা শেষ' : 'Nearby Search Quota Reached';
      dialogContent = isBn
          ? 'আপনার বর্তমান প্যাকেজের নিকটবর্তী এরিয়া সার্চের কোটা শেষ হয়ে গেছে। আনলিমিটেড বা অতিরিক্ত সার্চ সুবিধা পেতে প্যাকেজ আপগ্রেড করুন।'
          : 'You have reached your package limit for nearby searches. Please upgrade your package for additional searches.';
    } else {
      if (freeLimit <= 0) {
        dialogTitle = isBn ? 'কাছাকাছি সার্চ সুবিধা সীমাবদ্ধ' : 'Nearby Search Disabled';
        dialogContent = isBn
            ? 'ফ্রি অ্যাকাউন্টে কাছাকাছি (দূরত্ব অনুযায়ী) সার্চের সুবিধা বন্ধ আছে। এই সুবিধা উপভোগ করতে অনুগ্রহ করে সাবস্ক্রিপশন প্যাকেজ গ্রহণ করুন।'
            : 'Nearby radius search is disabled on free accounts. Please activate a subscription package to enjoy nearby search.';
      } else {
        dialogTitle = l10n.radiusLimitReachedTitle;
        dialogContent = l10n.radiusLimitReachedSubtitle(freeLimitStr);
      }
    }

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
                dialogTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          dialogContent,
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
  }

  void _search(BuildContext context, FindHomeProvider provider, FreeTierPolicyModel policy) async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    final isGuest = userProvider.isGuest || user == null;
    final isRadius = !isGuest && provider.isRadiusSearchMode;

    final l10n = context.localizations;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';

    if (isRadius) {
      if (!user.canPerformNearbySearchForPolicy(policy: policy)) {
        _showQuotaExhaustedDialog(
          context: context,
          user: user,
          policy: policy,
          isBn: isBn,
          languageCode: languageCode,
          l10n: l10n,
        );
        return;
      }

      await context.read<SubscriptionProvider>().recordRadiusSearch(context, user);
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
