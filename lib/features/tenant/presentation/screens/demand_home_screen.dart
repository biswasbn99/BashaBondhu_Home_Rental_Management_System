import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/app/validators.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/widgets/auth_prompt_dialog.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/bathroom_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/belcony_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/budget_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/floor_number_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/house_type_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/lift_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/location_dropdown.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/month_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/number_of_room_or_seat_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/parking_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/post_icon.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/tenant_type_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/providers/demand_home_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/my_demand_screen.dart';

class DemandHomeScreen extends StatelessWidget {
  const DemandHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = DemandHomeProvider();
        final userProvider = Provider.of<UserProvider>(ctx, listen: false);
        if (!userProvider.isGuest && userProvider.user != null) {
          final fullName = "${userProvider.user!.firstName} ${userProvider.user!.lastName}".trim();
          if (fullName.isNotEmpty) provider.userName = fullName;
          if (userProvider.user!.mobile.isNotEmpty) provider.userMobile = userProvider.user!.mobile;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadDivisions(ctx.localizations);
        });
        return provider;
      },
      child: const _DemandHomeView(),
    );
  }
}

class _DemandHomeView extends StatefulWidget {
  const _DemandHomeView();

  @override
  State<_DemandHomeView> createState() => _DemandHomeViewState();
}

class _DemandHomeViewState extends State<_DemandHomeView> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  static const Color _grey = Color(0xFF7A8A88);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DemandHomeProvider>(context);
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
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOrangeBanner(context),
                const SizedBox(height: 24),

                // Accommodation Section (Required)
                DecoratedSectionHeader(title: l10n.accommodationPromptTitle),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel(l10n.month),
                          const SizedBox(height: 6),
                          MonthDropdown(
                            value: provider.selectedMonth,
                            months: DemandHomeProvider.months,
                            onChanged: provider.setMonth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel(l10n.houseType),
                          const SizedBox(height: 6),
                          HouseTypeDropdown(
                            value: provider.selectedHouseType,
                            houseTypes: DemandHomeProvider.houseTypes,
                            onChanged: provider.setHouseType,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Location Section (Required)
                DecoratedSectionHeader(title: l10n.locationPromptTitle),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DivisionDropdown(
                        value: provider.selectedDivision,
                        divisions: provider.divisions,
                        isLoading: provider.isLoadingDivisions,
                        onChanged: (div) => provider.selectDivision(div, l10n),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DistrictDropdown(
                        value: provider.selectedDistrict,
                        districts: provider.districts,
                        enabled: provider.selectedDivision != null,
                        isLoading: provider.isLoadingDistricts,
                        onChanged: (dist) => provider.selectDistrict(dist, l10n),
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
                        onChanged: (upazila) => provider.selectUpazila(upazila, l10n),
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

                // Budget & Tenant Type (Required)
                DecoratedSectionHeader(title: l10n.budgetTenantPromptTitle),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: BudgetDropdown(
                        value: provider.selectedBudgetRange,
                        ranges: DemandHomeProvider.budgetRanges,
                        isRequired: true,
                        onChanged: provider.setBudgetRange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TenantTypeDropdown(
                        value: provider.selectedTenantType,
                        isRequired: true,
                        onChanged: provider.setTenantType,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Room / Seat count (Required)
                DecoratedSectionHeader(title: l10n.roomSeatPromptTitle),
                const SizedBox(height: 12),

                RoomOrSeatDropdown(
                  hint: l10n.roomOrSeatNo,
                  value: provider.selectedRoomOrSeat,
                  enabled: provider.selectedHouseType != null,
                  options: provider.roomOrSeatOptions,
                  onChanged: provider.setRoomOrSeat,
                ),

                const SizedBox(height: 20),

                // Amenities (Optional)
                DecoratedSectionHeader(title: '${l10n.amenitiesPromptTitle} (${l10n.optional})'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: BathroomDropdown(
                        value: provider.selectedBathrooms,
                        onChanged: provider.setBathrooms,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BalconyDropdown(
                        value: provider.selectedBalconies,
                        onChanged: provider.setBalconies,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: FloorNumberDropdown(
                        value: provider.selectedFloorNumber,
                        onChanged: provider.setFloorNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LiftDropdown(
                        value: provider.hasLift,
                        onChanged: provider.setLift,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ParkingDropdown(
                  value: provider.hasParking,
                  onChanged: provider.setParking,
                ),

                const SizedBox(height: 20),

                // Notice Status (Optional)
                DecoratedSectionHeader(title: l10n.noticeQuestion),
                const SizedBox(height: 12),

                _buildSectionLabel(l10n.noticeQuestion),
                const SizedBox(height: 8),
                FilterDropdown<bool>(
                  hint: l10n.noticeHint,
                  value: provider.hasGivenNotice,
                  isRequired: false,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.noticeHint),
                    ),
                    DropdownMenuItem(
                      value: true,
                      child: Text(l10n.yes),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text(l10n.no),
                    ),
                  ],
                  onChanged: provider.setGivenNotice,
                ),

                const SizedBox(height: 20),

                // Contact Details (Name & Phone Required, WhatsApp Optional)
                DecoratedSectionHeader(title: l10n.contactPromptTitle),
                const SizedBox(height: 12),

                _buildTextField(
                  hint: l10n.enterName,
                  initialValue: provider.userName,
                  prefixIcon: Icons.person_outline_rounded,
                  onChanged: provider.setUserName,
                  validator: Validators.validateName,
                ),

                const SizedBox(height: 12),

                _buildTextField(
                  hint: l10n.enterMobile,
                  initialValue: provider.userMobile,
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  onChanged: provider.setUserMobile,
                  validator: Validators.validatePhoneNumber,
                ),

                const SizedBox(height: 12),

                _buildTextField(
                  hint: '${l10n.enterWhatsApp} (${l10n.optional})',
                  initialValue: provider.userWhatsApp,
                  prefixIcon: Icons.message_outlined,
                  keyboardType: TextInputType.phone,
                  onChanged: provider.setUserWhatsApp,
                  validator: Validators.validateWhatsAppNumber,
                ),

                const SizedBox(height: 14),
                Text(
                  l10n.postDemandPrompt,
                  style: const TextStyle(color: _grey, fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: provider.isPosting
                      ? null
                      : () {
                          setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
                          final isFormValid = _formKey.currentState?.validate() ?? false;
                          if (isFormValid && provider.isDemandValid) {
                            _postDemand(context, provider);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('অনুগ্রহ করে সকল আবশ্যকীয় তথ্য (বিভাগ, জেলা, এলাকা, মাস, বাসার ধরন, বাজেট, ভাড়াটিয়ার ধরন, রুম/সিট, যোগাযোগের নাম ও সঠিক মোবাইল নম্বর) সঠিকভাবে পূরণ করুন।'),
                                backgroundColor: Colors.redAccent,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                  child: provider.isPosting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(l10n.postDemand),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _postDemand(BuildContext context, DemandHomeProvider provider) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final l10n = context.localizations;

    if (userProvider.isGuest || userProvider.user == null) {
      AuthPromptDialog.show(
        context,
        requiredRole: 'Tenant',
      );
      return;
    }

    try {
      await provider.submitDemand(
        tenantId: userProvider.user!.uid,
        tenantEmail: userProvider.user!.email,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.demandPostedSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: l10n.myDemands,
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, MyDemandScreen.name);
              },
            ),
          ),
        );
        provider.resetFilters();
        setState(() => _autovalidateMode = AutovalidateMode.disabled);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি ঘটেছে: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildOrangeBanner(BuildContext context) {
    final l10n = context.localizations;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFFE65100), const Color(0xFFBF360C)]
              : [const Color(0xFFFF8A65), const Color(0xFFFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bannerTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bannerSubtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
              children: [
                TextSpan(
                  text: '${l10n.version}: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: l10n.bannerNote),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required String initialValue,
    required ValueChanged<String> onChanged,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _grey, size: 20) : null,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.themeColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
