import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/app/validators.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/data/providers/home_rent_post_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/month_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/house_type_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/number_of_room_or_seat_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/location_dropdown.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/widgets/multi_image_picker_widget.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/widgets/counter_dropdown.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/widgets/electricity_bill_dropdown.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/widgets/amenities_dropdown.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/widgets/distance_dropdown.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/belcony_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/floor_number_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/lift_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/parking_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/widgets/validated_text_area.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/post_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeRentPostScreen extends StatelessWidget {
  const HomeRentPostScreen({super.key});

  static const String name = '/home-rent-post';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = HomeRentPostProvider();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadDivisions(ctx.localizations);
        });
        return provider;
      },
      child: const _HomeRentPostView(),
    );
  }
}

class _HomeRentPostView extends StatelessWidget {
  const _HomeRentPostView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeRentPostProvider>();
    final l10n = context.localizations;
    final userProvider = Provider.of<UserProvider>(context);
    final bool isGuest = userProvider.isGuest;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Photos ---
            MultiImagePickerWidget(
              images: provider.images,
              onImageAdded: provider.addImage,
              onImageRemoved: provider.removeImage,
            ),
            const SizedBox(height: 24),

            // --- Basic Info Section ---
            DecoratedSectionHeader(title: l10n.accommodationPromptTitle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MonthDropdown(
                    value: provider.selectedMonth,
                    months: HomeRentPostProvider.months,
                    onChanged: provider.selectMonth,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HouseTypeDropdown(
                    value: provider.selectedHouseType,
                    houseTypes: HomeRentPostProvider.houseTypes,
                    onChanged: provider.selectHouseType,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RoomOrSeatDropdown(
              hint: provider.roomOrSeatHint(l10n),
              value: provider.selectedRoomOrSeat,
              enabled: provider.selectedHouseType != null,
              options: provider.roomOrSeatOptions(l10n),
              onChanged: provider.selectRoomOrSeat,
            ),
            const SizedBox(height: 24),

            // --- Contact & Budget ---
            DecoratedSectionHeader(title: l10n.budgetTenantPromptTitle),
            const SizedBox(height: 12),
            _buildTextField(
              hint: l10n.contactPerson,
              prefixIcon: Icons.person_outline_rounded,
              initialValue: provider.contactName,
              onChanged: provider.setContactName,
              validator: (val) => Validators.validateName(val),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              hint: l10n.amount,
              prefixIcon: Icons.payments_outlined,
              initialValue: provider.amount,
              keyboardType: TextInputType.number,
              onChanged: provider.setAmount,
              validator: (val) => Validators.validateNumber(val),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              hint: l10n.enterMobile,
              prefixIcon: Icons.phone_android_rounded,
              initialValue: provider.userMobile,
              keyboardType: TextInputType.phone,
              onChanged: provider.setUserMobile,
              validator: (val) => Validators.validatePhoneNumber(val),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              hint: l10n.enterWhatsApp,
              prefixIcon: Icons.message_outlined,
              initialValue: provider.userWhatsApp,
              keyboardType: TextInputType.phone,
              onChanged: provider.setUserWhatsApp,
              validator: (val) {
                if (val != null && val.isNotEmpty) {
                  return Validators.validatePhoneNumber(val);
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // --- Location Section ---
            DecoratedSectionHeader(title: l10n.locationPromptTitle),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            ValidatedTextArea(
              hint: l10n.shortAddress,
              maxWords: 200,
              initialValue: provider.shortAddress,
              onChanged: provider.setShortAddress,
              validator: (val) => Validators.validateText(val),
            ),
            const SizedBox(height: 24),

            // --- Amenities Section ---
            DecoratedSectionHeader(title: l10n.amenitiesPromptTitle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CounterDropdown(
                    hint: l10n.commonBathroom,
                    value: provider.commonBathrooms,
                    onChanged: provider.selectCommonBathrooms,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CounterDropdown(
                    hint: l10n.attachedBathroom,
                    value: provider.attachedBathrooms,
                    onChanged: provider.selectAttachedBathrooms,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CounterDropdown(
                    hint: l10n.kitchen,
                    value: provider.kitchenCount,
                    onChanged: provider.selectKitchenCount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BalconyDropdown(
                    value: provider.balconies, // Add to provider
                    onChanged: provider.selectBalconies, // Add to provider
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FloorNumberDropdown(
                    value: provider.floorNumber, // Add to provider
                    onChanged: provider.selectFloor, // Add to provider
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElectricityBillDropdown(
                    value: provider.electricityBillType,
                    onChanged: provider.selectElectricityBillType,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AmenitiesDropdown(
                    hint: l10n.cctv,
                    value: provider.hasCctv,
                    onChanged: provider.selectCctv,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AmenitiesDropdown(
                    hint: l10n.wifi,
                    value: provider.hasWifi,
                    onChanged: provider.selectWifi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AmenitiesDropdown(
                    hint: l10n.generator,
                    value: provider.hasGenerator,
                    onChanged: provider.selectGenerator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AmenitiesDropdown(
                    hint: l10n.securityGuard,
                    value: provider.hasSecurityGuard,
                    onChanged: provider.selectSecurityGuard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ParkingDropdown(
                    value: provider.hasParking,
                    onChanged: provider.selectParking,
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
            DistanceDropdown(
              value: provider.marketDistance,
              onChanged: provider.selectMarketDistance,
            ),
            const SizedBox(height: 24),

            // --- Description Section ---
            DecoratedSectionHeader(title: l10n.detailedDescription),
            const SizedBox(height: 12),
            ValidatedTextArea(
              hint: l10n.detailedDescription,
              maxWords: 999,
              initialValue: provider.detailedDescription,
              onChanged: provider.setDetailedDescription,
              validator: (val) => Validators.validateText(val),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: provider.isFormValid ? () {} : null,
                child: Text(
                  l10n.postNow,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // --- Post Button ---
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required String initialValue,
    required ValueChanged<String> onChanged,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: AppColors.themeColor) : null,
      ),
    );
  }
}
