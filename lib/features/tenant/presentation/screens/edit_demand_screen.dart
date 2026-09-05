import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/app/validators.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/sub_area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/repository/location_repository.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/services/tenant_demand_firestore_service.dart';
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
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/tenant_type_dropdown_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/providers/demand_home_provider.dart';

class EditDemandScreen extends StatefulWidget {
  const EditDemandScreen({super.key, required this.demand});

  final TenantDemandModel demand;
  static const String name = '/edit-demand';

  @override
  State<EditDemandScreen> createState() => _EditDemandScreenState();
}

class _EditDemandScreenState extends State<EditDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocationRepository _repository = LocationRepository();

  late String? _selectedMonth;
  late HouseType _selectedHouseType;
  late String? _selectedRoomOrSeat;
  late DivisionModel _selectedDivision;
  late DistrictModel _selectedDistrict;
  late UpazilaModel _selectedUpazila;
  late UnionModel? _selectedArea;
  late String? _selectedBudgetRange;
  late TenantType? _selectedTenantType;
  late int? _selectedBathrooms;
  late int? _attachedBathrooms;
  late int? _selectedBalconies;
  late int? _selectedFloorNumber;
  late bool? _hasLift;
  late bool? _hasParking;
  late bool? _hasGivenNotice;
  late String _userName;
  late String _userMobile;
  late String _userWhatsApp;
  late String _shortAddress;
  late String _detailedDescription;

  List<DivisionModel> _divisions = [];
  List<DistrictModel> _districts = [];
  List<UpazilaModel> _upazilas = [];
  List<UnionModel> _areas = [];

  bool _isLoadingDivisions = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingUpazilas = false;
  bool _isLoadingAreas = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.demand;
    _selectedMonth = d.month;
    _selectedHouseType = d.houseType;
    _selectedRoomOrSeat = d.roomOrSeat;
    _selectedDivision = d.division;
    _selectedDistrict = d.district;
    _selectedUpazila = d.area;
    _selectedArea = d.subArea;
    _selectedBudgetRange = d.budgetRange;
    _selectedTenantType = d.tenantType;
    _selectedBathrooms = d.bathrooms;
    _attachedBathrooms = d.attachedBathrooms;
    _selectedBalconies = d.balconies;
    _selectedFloorNumber = d.floorNumber;
    _hasLift = d.hasLift;
    _hasParking = d.hasParking;
    _hasGivenNotice = d.hasGivenNotice;
    _userName = d.userName;
    _userMobile = d.userMobile;
    _userWhatsApp = d.userWhatsApp;
    _shortAddress = d.shortAddress;
    _detailedDescription = d.detailedDescription;

    _loadInitialLocations();
  }

  Future<void> _loadInitialLocations() async {
    setState(() => _isLoadingDivisions = true);
    try {
      _divisions = await _repository.getDivisions();
      if (_selectedDivision.id.isNotEmpty) {
        _districts = await _repository.getDistrictsByDivision(_selectedDivision.id);
      }
      if (_selectedDistrict.id.isNotEmpty) {
        _upazilas = await _repository.getUpazilasByDistrict(_selectedDistrict.id);
      }
      if (_selectedUpazila.id.isNotEmpty) {
        _areas = await _repository.getUnionsByUpazila(_selectedUpazila.id);
      }
    } catch (e) {
      debugPrint('Error loading initial locations: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDivisions = false);
    }
  }

  Future<void> _onDivisionChanged(DivisionModel? division) async {
    setState(() {
      _selectedDivision = division ?? const DivisionModel(id: '', name: '', bnName: '');
      _selectedDistrict = const DistrictModel(id: '', divisionId: '', name: '', bnName: '');
      _selectedUpazila = const UpazilaModel(id: '', districtId: '', name: '', bnName: '');
      _selectedArea = null;
      _districts = [];
      _upazilas = [];
      _areas = [];
      _isLoadingDistricts = true;
    });

    if (division != null && division.id.isNotEmpty) {
      try {
        final dList = await _repository.getDistrictsByDivision(division.id);
        if (mounted) setState(() => _districts = dList);
      } catch (e) {
        debugPrint('Error loading districts: $e');
      }
    }
    if (mounted) setState(() => _isLoadingDistricts = false);
  }

  Future<void> _onDistrictChanged(DistrictModel? district) async {
    setState(() {
      _selectedDistrict = district ?? const DistrictModel(id: '', divisionId: '', name: '', bnName: '');
      _selectedUpazila = const UpazilaModel(id: '', districtId: '', name: '', bnName: '');
      _selectedArea = null;
      _upazilas = [];
      _areas = [];
      _isLoadingUpazilas = true;
    });

    if (district != null && district.id.isNotEmpty) {
      try {
        final uList = await _repository.getUpazilasByDistrict(district.id);
        if (mounted) setState(() => _upazilas = uList);
      } catch (e) {
        debugPrint('Error loading upazilas: $e');
      }
    }
    if (mounted) setState(() => _isLoadingUpazilas = false);
  }

  Future<void> _onUpazilaChanged(UpazilaModel? upazila) async {
    setState(() {
      _selectedUpazila = upazila ?? const UpazilaModel(id: '', districtId: '', name: '', bnName: '');
      _selectedArea = null;
      _areas = [];
      _isLoadingAreas = true;
    });

    if (upazila != null && upazila.id.isNotEmpty) {
      try {
        final aList = await _repository.getUnionsByUpazila(upazila.id);
        if (mounted) setState(() => _areas = aList);
      } catch (e) {
        debugPrint('Error loading unions: $e');
      }
    }
    if (mounted) setState(() => _isLoadingAreas = false);
  }

  List<String> _roomOrSeatOptions(dynamic l10n) {
    switch (_selectedHouseType) {
      case HouseType.flat:
        return List.generate(8, (i) => "${l10n.bedroom} - ${i + 1}");
      case HouseType.room:
        return List.generate(8, (i) => "${l10n.room} - ${i + 1}");
      case HouseType.seat:
        return List.generate(8, (i) => "${l10n.emptySeat} - ${i + 1}");
      case HouseType.unit:
        return List.generate(8, (i) => "${l10n.unit} - ${i + 1}");
    }
  }

  Future<void> _saveDemand() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMonth == null ||
        _selectedDivision.id.isEmpty ||
        _selectedDistrict.id.isEmpty ||
        _selectedUpazila.id.isEmpty ||
        _selectedRoomOrSeat == null ||
        _selectedBudgetRange == null ||
        _selectedTenantType == null) {
      final isBn = Localizations.localeOf(context).languageCode == 'bn';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'অনুগ্রহ করে সকল আবশ্যকীয় তথ্য পূরণ করুন।' : 'Please fill in all required fields.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      final finalName = (user != null && "${user.firstName} ${user.lastName}".trim().isNotEmpty)
          ? "${user.firstName} ${user.lastName}".trim()
          : _userName.trim();
      final finalMobile = (user != null && user.mobile.isNotEmpty)
          ? user.mobile.trim()
          : _userMobile.trim();

      final updatedDemand = widget.demand.copyWith(
        month: _selectedMonth!,
        houseType: _selectedHouseType,
        roomOrSeat: _selectedRoomOrSeat!,
        division: _selectedDivision,
        district: _selectedDistrict,
        area: _selectedUpazila,
        subArea: _selectedArea,
        budgetRange: _selectedBudgetRange,
        tenantType: _selectedTenantType,
        bathrooms: _selectedBathrooms,
        attachedBathrooms: _attachedBathrooms,
        balconies: _selectedBalconies,
        floorNumber: _selectedFloorNumber,
        hasLift: _hasLift,
        hasParking: _hasParking,
        hasGivenNotice: _hasGivenNotice,
        userName: finalName,
        userMobile: finalMobile,
        userWhatsApp: _userWhatsApp.trim(),
        shortAddress: _shortAddress.trim(),
        detailedDescription: _detailedDescription.trim(),
      );

      await TenantDemandFirestoreService().updateDemand(updatedDemand);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.localizations.demandUpdatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final bool isGuest = userProvider.isGuest;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.editDemand,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accommodation Section
                DecoratedSectionHeader(title: l10n.accommodationPromptTitle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: MonthDropdown(
                        value: _selectedMonth,
                        months: DemandHomeProvider.months,
                        onChanged: (val) => setState(() => _selectedMonth = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HouseTypeDropdown(
                        value: _selectedHouseType,
                        houseTypes: DemandHomeProvider.houseTypes,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedHouseType = val;
                              _selectedRoomOrSeat = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Location Section
                DecoratedSectionHeader(title: l10n.locationPromptTitle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DivisionDropdown(
                        value: _selectedDivision.id.isNotEmpty ? _selectedDivision : null,
                        divisions: _divisions,
                        isLoading: _isLoadingDivisions,
                        onChanged: (val) => _onDivisionChanged(val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DistrictDropdown(
                        value: _selectedDistrict.id.isNotEmpty ? _selectedDistrict : null,
                        districts: _districts,
                        enabled: _selectedDivision.id.isNotEmpty,
                        isLoading: _isLoadingDistricts,
                        onChanged: (val) => _onDistrictChanged(val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: UpazilaDropdown(
                        value: _selectedUpazila.id.isNotEmpty ? _selectedUpazila : null,
                        upazilas: _upazilas,
                        enabled: _selectedDistrict.id.isNotEmpty,
                        isLoading: _isLoadingUpazilas,
                        onChanged: (val) => _onUpazilaChanged(val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AreaDropdown(
                        value: _selectedArea,
                        areas: _areas,
                        enabled: _selectedUpazila.id.isNotEmpty,
                        isLoading: _isLoadingAreas,
                        onChanged: (val) => setState(() => _selectedArea = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Budget & Tenant Type
                DecoratedSectionHeader(title: l10n.budgetTenantPromptTitle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: BudgetDropdown(
                        value: _selectedBudgetRange,
                        ranges: DemandHomeProvider.budgetRanges,
                        isRequired: true,
                        onChanged: (val) => setState(() => _selectedBudgetRange = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TenantTypeDropdown(
                        value: _selectedTenantType,
                        isRequired: true,
                        onChanged: (val) => setState(() => _selectedTenantType = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Room / Seat count
                DecoratedSectionHeader(title: l10n.roomSeatPromptTitle),
                const SizedBox(height: 10),
                RoomOrSeatDropdown(
                  hint: l10n.roomOrSeatNo,
                  value: _selectedRoomOrSeat,
                  enabled: true,
                  options: _roomOrSeatOptions(l10n),
                  onChanged: (val) => setState(() => _selectedRoomOrSeat = val),
                ),
                const SizedBox(height: 20),

                // Amenities (Optional)
                DecoratedSectionHeader(title: '${l10n.amenitiesPromptTitle} (${l10n.optional})'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: BathroomDropdown(
                        value: _selectedBathrooms,
                        onChanged: (val) => setState(() => _selectedBathrooms = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BalconyDropdown(
                        value: _selectedBalconies,
                        onChanged: (val) => setState(() => _selectedBalconies = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FloorNumberDropdown(
                        value: _selectedFloorNumber,
                        onChanged: (val) => setState(() => _selectedFloorNumber = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LiftDropdown(
                        value: _hasLift,
                        onChanged: (val) => setState(() => _hasLift = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ParkingDropdown(
                  value: _hasParking,
                  onChanged: (val) => setState(() => _hasParking = val),
                ),
                const SizedBox(height: 20),

                // Notice Status
                Text(l10n.noticeQuestion, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                FilterDropdown<bool>(
                  hint: l10n.noticeHint,
                  value: _hasGivenNotice,
                  isRequired: false,
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.noticeHint)),
                    DropdownMenuItem(value: true, child: Text(l10n.yes)),
                    DropdownMenuItem(value: false, child: Text(l10n.no)),
                  ],
                  onChanged: (val) => setState(() => _hasGivenNotice = val),
                ),
                const SizedBox(height: 20),

                // Contact Details
                DecoratedSectionHeader(title: l10n.contactPromptTitle),
                const SizedBox(height: 10),
                TextFormField(
                  key: ValueKey('edit_demand_name_${isGuest ? "guest" : "${user?.firstName ?? ""}_${user?.lastName ?? ""}"}'),
                  initialValue: !isGuest && user != null
                      ? "${user.firstName} ${user.lastName}".trim()
                      : _userName,
                  readOnly: !isGuest && user != null,
                  style: TextStyle(
                    fontWeight: (!isGuest && user != null) ? FontWeight.w600 : FontWeight.normal,
                    color: (!isGuest && user != null) ? (isDark ? Colors.grey[200] : Colors.grey[800]) : null,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.enterName,
                    helperText: !isGuest && user != null
                        ? (isBn ? '🔒 প্রোফাইল থেকে সংরক্ষিত' : '🔒 Fixed from profile')
                        : null,
                    helperStyle: const TextStyle(fontSize: 11.5, color: AppColors.themeColor, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    suffixIcon: !isGuest && user != null
                        ? const Icon(Icons.lock_outline_rounded, color: AppColors.themeColor, size: 18)
                        : null,
                    filled: !isGuest && user != null,
                    fillColor: (!isGuest && user != null)
                        ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08))
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: (!isGuest && user != null) ? AppColors.themeColor.withValues(alpha: 0.35) : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  onChanged: (val) => _userName = val,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('edit_demand_mobile_${isGuest ? "guest" : (user?.mobile ?? "")}'),
                  initialValue: !isGuest && user != null && user.mobile.isNotEmpty
                      ? user.mobile
                      : _userMobile,
                  keyboardType: TextInputType.phone,
                  readOnly: !isGuest && user != null && user.mobile.isNotEmpty,
                  style: TextStyle(
                    fontWeight: (!isGuest && user != null && user.mobile.isNotEmpty) ? FontWeight.w600 : FontWeight.normal,
                    color: (!isGuest && user != null && user.mobile.isNotEmpty) ? (isDark ? Colors.grey[200] : Colors.grey[800]) : null,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.enterMobile,
                    helperText: !isGuest && user != null && user.mobile.isNotEmpty
                        ? (isBn ? '🔒 প্রোফাইল থেকে সংরক্ষিত' : '🔒 Fixed from profile')
                        : null,
                    helperStyle: const TextStyle(fontSize: 11.5, color: AppColors.themeColor, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.phone_android_rounded),
                    suffixIcon: !isGuest && user != null && user.mobile.isNotEmpty
                        ? const Icon(Icons.lock_outline_rounded, color: AppColors.themeColor, size: 18)
                        : null,
                    filled: !isGuest && user != null && user.mobile.isNotEmpty,
                    fillColor: (!isGuest && user != null && user.mobile.isNotEmpty)
                        ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08))
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: (!isGuest && user != null && user.mobile.isNotEmpty) ? AppColors.themeColor.withValues(alpha: 0.35) : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  onChanged: (val) => _userMobile = val,
                  validator: Validators.validatePhoneNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _userWhatsApp,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '${l10n.enterWhatsApp} (${l10n.optional})',
                    prefixIcon: const Icon(Icons.message_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => _userWhatsApp = val,
                  validator: Validators.validateWhatsAppNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _shortAddress,
                  decoration: InputDecoration(
                    hintText: '${l10n.shortAddress} (${l10n.optional})',
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => _shortAddress = val,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _detailedDescription,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '${l10n.detailedDescription} (${l10n.optional})',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => _detailedDescription = val,
                ),
                const SizedBox(height: 24),

                // Save Changes Button
                FilledButton(
                  onPressed: _isSaving ? null : _saveDemand,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(l10n.saveChanges),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

