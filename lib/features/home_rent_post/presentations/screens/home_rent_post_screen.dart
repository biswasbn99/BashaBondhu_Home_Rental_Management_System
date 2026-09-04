import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/validators.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../auth/presentation/widgets/auth_prompt_dialog.dart';
import '../../../shared/presentation/providers/main_nav_holder_provider.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';
import '../../../shared/presentation/widgets/belcony_dropdown_button.dart';
import '../../../shared/presentation/widgets/decorated_section_header.dart';
import '../../../shared/presentation/widgets/floor_number_dropdown_button.dart';
import '../../../shared/presentation/widgets/house_type_dropdown_button.dart';
import '../../../shared/presentation/widgets/lift_dropdown_button.dart';
import '../../../shared/presentation/widgets/location_dropdown.dart';
import '../../../shared/presentation/widgets/month_dropdown_button.dart';
import '../../../shared/presentation/widgets/number_of_room_or_seat_dropdown_button.dart';
import '../../../shared/presentation/widgets/parking_dropdown_button.dart';
import '../../../shared/data/models/search_filter_model.dart';
import '../../../shared/presentation/widgets/post_icon.dart';
import '../../../shared/presentation/widgets/tenant_type_dropdown_button.dart';
import '../../../ai_assistant/presentation/providers/ai_assistant_provider.dart';
import '../../../ai_assistant/presentation/widgets/ai_floating_button.dart';
import '../../data/providers/home_rent_post_provider.dart';
import '../widgets/amenities_dropdown.dart';
import '../widgets/counter_dropdown.dart';
import '../widgets/distance_dropdown.dart';
import '../widgets/electricity_bill_dropdown.dart';
import '../widgets/multi_image_picker_widget.dart';
import '../widgets/property_location_picker_card.dart';
import '../widgets/validated_text_area.dart';

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

class _HomeRentPostView extends StatefulWidget {
  const _HomeRentPostView();

  @override
  State<_HomeRentPostView> createState() => _HomeRentPostViewState();
}

class _HomeRentPostViewState extends State<_HomeRentPostView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeRentPostProvider>();
    final l10n = context.localizations;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';
    final userProvider = Provider.of<UserProvider>(context);
    final bool isGuest = userProvider.isGuest;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Validation Warning Banner if submitted with missing info ---
              if (provider.showValidationErrors && !provider.isFormValid) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isBn
                              ? 'দয়া করে লাল দাগ চিহ্নিত সব প্রয়োজনীয় ফিল্ড এবং থাম্বনেইল ছবি পূরণ করুন।'
                              : 'Please fill all required fields highlighted in red and add a thumbnail image.',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- Photos ---
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: (provider.showValidationErrors && !provider.hasThumbnail)
                      ? Border.all(color: Colors.redAccent, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MultiImagePickerWidget(
                      images: provider.images,
                      onImageAdded: provider.addImage,
                      onMultipleImagesAdded: provider.addMultipleImages,
                      onThumbnailSet: provider.setThumbnail,
                      onImageReplaced: provider.replaceImage,
                      onImageRemoved: provider.removeImage,
                    ),
                    if (provider.showValidationErrors && !provider.hasThumbnail) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 6),
                        child: Text(
                          isBn ? '* প্রধান থাম্বনেইল ছবি যুক্ত করা আবশ্যক' : '* Main thumbnail image is required',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
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
              Row(
                children: [
                  Expanded(
                    child: RoomOrSeatDropdown(
                      hint: provider.roomOrSeatHint(l10n),
                      value: provider.selectedRoomOrSeat,
                      enabled: provider.selectedHouseType != null,
                      options: provider.roomOrSeatOptions(l10n),
                      onChanged: provider.selectRoomOrSeat,
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
                showErrors: provider.showValidationErrors,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                hint: l10n.amount,
                prefixIcon: Icons.payments_outlined,
                initialValue: provider.amount,
                keyboardType: TextInputType.number,
                onChanged: provider.setAmount,
                validator: (val) => Validators.validateNumber(val),
                showErrors: provider.showValidationErrors,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                hint: l10n.enterMobile,
                prefixIcon: Icons.phone_android_rounded,
                initialValue: provider.userMobile,
                keyboardType: TextInputType.phone,
                onChanged: provider.setUserMobile,
                validator: (val) => Validators.validatePhoneNumber(val),
                showErrors: provider.showValidationErrors,
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
                showErrors: provider.showValidationErrors,
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
              const SizedBox(height: 16),

              // --- Property Exact Location on Map ---
              PropertyLocationPickerCard(
                latitude: provider.latitude,
                longitude: provider.longitude,
                onLocationChanged: (lat, lng) {
                  if (lat != null && lng != null) {
                    provider.setLocation(lat, lng);
                  } else {
                    provider.clearLocation();
                  }
                },
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
                      value: provider.balconies,
                      onChanged: provider.selectBalconies,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FloorNumberDropdown(
                      value: provider.floorNumber,
                      onChanged: provider.selectFloor,
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

              // --- Description Section with AI Generation Action ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: DecoratedSectionHeader(title: l10n.detailedDescription)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.themeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(
                      isBn ? 'এআই দিয়ে লিখুন' : 'AI Generate',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    onPressed: () async {
                      final division = provider.selectedDivision?.getLocalizedName(languageCode);
                      final district = provider.selectedDistrict?.getLocalizedName(languageCode);
                      final area = provider.selectedUpazila?.getLocalizedName(languageCode) ??
                          (isBn ? 'ঢাকা' : 'Dhaka');
                      final subArea = provider.selectedArea?.getLocalizedName(languageCode);
                      final shortAddress = provider.shortAddress;
                      final houseType = provider.selectedHouseType?.getLocalizedLabel(l10n) ??
                          (isBn ? 'ফ্ল্যাট' : 'Flat');
                      final roomOrSeat = provider.selectedRoomOrSeat?.getLocalizedRoomOrSeat(l10n) ??
                          (isBn ? '২ বেডরুম' : '2 Bedrooms');
                      final tenantType = provider.selectedTenantType?.getLocalizedLabel(l10n);
                      final month = provider.selectedMonth;
                      final floor = provider.floorNumber?.toString() ?? (isBn ? '৩' : '3');
                      final amount = provider.amount.isNotEmpty ? provider.amount : '15000';
                      final electricityBillType = provider.electricityBillType;
                      final marketDistance = provider.marketDistance;
                      final commonBathrooms = provider.commonBathrooms;
                      final attachedBathrooms = provider.attachedBathrooms;
                      final kitchenCount = provider.kitchenCount;
                      final balconies = provider.balconies;
                      final amenities = <String>[
                        if (provider.hasLift == true) (isBn ? 'লিফট সুবিধা' : 'Lift Access'),
                        if (provider.hasParking == true) (isBn ? 'গাড়ি পার্কিং' : 'Car Parking'),
                        if (provider.hasGenerator == true) (isBn ? 'জেনারেটর ব্যাকআপ' : 'Generator Backup'),
                        if (provider.hasCctv == true) (isBn ? 'সিসিটিভি নিরাপত্তা' : 'CCTV Security'),
                        if (provider.hasSecurityGuard == true) (isBn ? '২৪ ঘণ্টা দারোয়ান' : '24/7 Security Guard'),
                        if (provider.hasWifi == true) (isBn ? 'উচ্চগতির ওয়াইফাই' : 'High-speed WiFi'),
                      ];

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(isBn ? 'এআই সুন্দরভাবে বিবরণ তৈরি করছে...' : 'AI is generating decorated description...'),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      final genText = await context.read<AIAssistantProvider>().generateAdDescriptionForOwner(
                            area: area,
                            subArea: subArea,
                            district: district,
                            division: division,
                            shortAddress: shortAddress,
                            houseType: houseType,
                            roomOrSeat: roomOrSeat,
                            tenantType: tenantType,
                            month: month,
                            floor: floor,
                            amount: amount,
                            commonBathrooms: commonBathrooms,
                            attachedBathrooms: attachedBathrooms,
                            kitchenCount: kitchenCount,
                            balconies: balconies,
                            electricityBillType: electricityBillType,
                            amenities: amenities,
                            marketDistance: marketDistance,
                            languageCode: languageCode,
                          );

                      if (context.mounted) {
                        provider.setDetailedDescription(genText);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isBn ? '✨ এআই আকর্ষণীয় বিবরণ তৈরি করেছে!' : '✨ AI decorated description generated!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ValidatedTextArea(
                hint: l10n.detailedDescription,
                maxWords: 999,
                initialValue: provider.detailedDescription,
                onChanged: provider.setDetailedDescription,
                validator: (val) => Validators.validateText(val),
              ),
              const SizedBox(height: 24),

              // --- Post Now Button ---
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: provider.isSubmitting
                      ? null
                      : () async {
                          if (userProvider.isGuest || userProvider.user == null) {
                            AuthPromptDialog.show(
                              context,
                              requiredRole: 'House Owner',
                            );
                            return;
                          }

                          if (!provider.isFormValid) {
                            provider.triggerValidation();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isBn
                                      ? 'অনুগ্রহ করে থাম্বনেইল ছবি ও প্রয়োজনীয় সব তথ্য সঠিকভাবে পূরণ করুন।'
                                      : 'Please provide thumbnail image and fill all required fields correctly.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          // Bilingual Post Confirmation Dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  const Icon(Icons.help_outline_rounded, color: AppColors.themeColor),
                                  const SizedBox(width: 8),
                                  Text(isBn ? 'পোস্ট নিশ্চিতকরণ' : 'Confirm Post'),
                                ],
                              ),
                              content: Text(
                                isBn
                                    ? 'আপনি কি এই বাসাভাড়া বিজ্ঞাপনটি প্রকাশ করতে চান?'
                                    : 'Are you sure you want to publish this rental post?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(isBn ? 'বাতিল' : 'Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
                                  child: Text(isBn ? 'হ্যাঁ, পোস্ট করুন' : 'Yes, Publish'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          final success = await provider.publishPost(userProvider.user);
                          if (success) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isBn
                                        ? '🎉 আপনার বাসাভাড়া পোস্ট সফলভাবে প্রকাশিত হয়েছে!'
                                        : '🎉 Your rental post has been published successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                              );

                              // If House Owner, switch to MyPost tab (index 2)
                              if (userProvider.user?.userType == 'House Owner') {
                                context.read<MainNavHolderProvider>().changeIndex(2);
                              }
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isBn
                                        ? 'পোস্ট প্রকাশ করতে সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।'
                                        : 'Failed to publish post. Please try again.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: provider.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.postNow),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
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
    bool showErrors = false,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      autovalidateMode: showErrors ? AutovalidateMode.always : AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: AppColors.themeColor) : null,
      ),
    );
  }
}
