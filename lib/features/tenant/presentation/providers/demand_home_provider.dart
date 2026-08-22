import 'package:flutter/material.dart';
import 'package:bashabondhu_home_rental_management_system/app/validators.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/sub_area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/repository/location_repository.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/services/tenant_demand_firestore_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';

class DemandHomeProvider extends ChangeNotifier {
  DemandHomeProvider({LocationRepository? repository})
      : repository = repository ?? LocationRepository();

  final LocationRepository repository;

  // Selected Filter Values
  String? selectedMonth;
  HouseType? selectedHouseType;
  DivisionModel? selectedDivision;
  DistrictModel? selectedDistrict;
  UpazilaModel? selectedUpazila;
  UnionModel? selectedArea;
  String? selectedRoomOrSeat;
  String? selectedBudgetRange;
  TenantType? selectedTenantType;
  int? selectedBathrooms;
  int? attachedBathrooms;
  int? selectedBalconies;
  int? selectedFloorNumber;
  int? kitchenCount;
  bool? hasLift;
  bool? hasParking;
  bool? hasGivenNotice;
  String userName = '';
  String userMobile = '';
  String userWhatsApp = '';
  String? electricityBillType;
  bool? hasCctv;
  bool? hasWifi;
  bool? hasGenerator;
  bool? hasSecurityGuard;
  String? marketDistance;
  String shortAddress = '';
  String detailedDescription = '';

  SortBy selectedSortBy = SortBy.newest;

  // Location lists
  List<DivisionModel> divisions = [];
  List<DistrictModel> districts = [];
  List<UpazilaModel> upazilas = [];
  List<UnionModel> areas = [];

  // Loading states
  bool isLoadingDivisions = false;
  bool isLoadingDistricts = false;
  bool isLoadingUpazilas = false;
  bool isLoadingAreas = false;

  // Error Message
  String? errorMessage;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // --- Static Options Data ---
  static const List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<HouseType> houseTypes = [
    HouseType.flat,
    HouseType.room,
    HouseType.seat,
    HouseType.unit,
  ];

  static const List<String> budgetRanges = [
    '0-5000',
    '6000-10000',
    '11000-15000',
    '16000-20000',
    '21000-25000',
    '26000-30000',
    '31000-35000',
    '36000-40000',
    '41000-45000',
    '46000-50000',
    '50000+',
  ];

  static const List<TenantType> tenantTypes = [
    TenantType.family,
    TenantType.bachelorMale,
    TenantType.bachelorFemale,
    TenantType.subLet,
  ];

  static const List<int> bathroomOptions = [1, 2, 3, 4, 5];
  static const List<int> balconyOptions = [1, 2, 3, 4];
  static const List<int> floorOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];

  List<String> get roomOrSeatOptions {
    if (selectedHouseType == null) return [];
    switch (selectedHouseType!) {
      case HouseType.flat:
        return List.generate(8, (i) => "Bedroom - ${i + 1}");
      case HouseType.room:
        return List.generate(8, (i) => "Room - ${i + 1}");
      case HouseType.seat:
        return List.generate(8, (i) => "Empty Seat - ${i + 1}");
      case HouseType.unit:
        return List.generate(8, (i) => "Unit - ${i + 1}");
    }
  }

  // --- Methods to Update State ---

  void setMonth(String? month) {
    selectedMonth = month;
    _safeNotifyListeners();
  }

  void setHouseType(HouseType? houseType) {
    selectedHouseType = houseType;
    selectedRoomOrSeat = null;
    _safeNotifyListeners();
  }

  void setRoomOrSeat(String? roomOrSeat) {
    selectedRoomOrSeat = roomOrSeat;
    _safeNotifyListeners();
  }

  void setBudgetRange(String? budgetRange) {
    selectedBudgetRange = budgetRange;
    _safeNotifyListeners();
  }

  void setTenantType(TenantType? tenantType) {
    selectedTenantType = tenantType;
    _safeNotifyListeners();
  }

  void setBathrooms(int? bathrooms) {
    selectedBathrooms = bathrooms;
    _safeNotifyListeners();
  }

  void setAttachedBathrooms(int? attached) {
    attachedBathrooms = attached;
    _safeNotifyListeners();
  }

  void setBalconies(int? balconies) {
    selectedBalconies = balconies;
    _safeNotifyListeners();
  }

  void setFloorNumber(int? floor) {
    selectedFloorNumber = floor;
    _safeNotifyListeners();
  }

  void setKitchenCount(int? kitchens) {
    kitchenCount = kitchens;
    _safeNotifyListeners();
  }

  void setLift(bool? lift) {
    hasLift = lift;
    _safeNotifyListeners();
  }

  void setParking(bool? parking) {
    hasParking = parking;
    _safeNotifyListeners();
  }

  void setGivenNotice(bool? notice) {
    hasGivenNotice = notice;
    _safeNotifyListeners();
  }

  void setUserName(String name) {
    userName = name;
    _safeNotifyListeners();
  }

  void setUserMobile(String mobile) {
    userMobile = mobile;
    _safeNotifyListeners();
  }

  void setUserWhatsApp(String whatsApp) {
    userWhatsApp = whatsApp;
    _safeNotifyListeners();
  }

  void setElectricityBillType(String? type) {
    electricityBillType = type;
    _safeNotifyListeners();
  }

  void setCctv(bool? cctv) {
    hasCctv = cctv;
    _safeNotifyListeners();
  }

  void setWifi(bool? wifi) {
    hasWifi = wifi;
    _safeNotifyListeners();
  }

  void setGenerator(bool? generator) {
    hasGenerator = generator;
    _safeNotifyListeners();
  }

  void setSecurityGuard(bool? security) {
    hasSecurityGuard = security;
    _safeNotifyListeners();
  }

  void setMarketDistance(String? distance) {
    marketDistance = distance;
    _safeNotifyListeners();
  }

  void setShortAddress(String address) {
    shortAddress = address;
    _safeNotifyListeners();
  }

  void setDetailedDescription(String description) {
    detailedDescription = description;
    _safeNotifyListeners();
  }

  void setSortBy(SortBy sortBy) {
    selectedSortBy = sortBy;
    _safeNotifyListeners();
  }

  // --- Location Loading Methods ---

  Future<void> loadDivisions(AppLocalizations localizations) async {
    if (divisions.isNotEmpty) return;

    isLoadingDivisions = true;
    errorMessage = null;
    _safeNotifyListeners();

    try {
      divisions = await repository.getDivisions();
    } catch (e) {
      debugPrint('Error loading divisions: $e');
      errorMessage = localizations.divisionNoLoadPrompt;
    } finally {
      isLoadingDivisions = false;
      _safeNotifyListeners();
    }
  }

  Future<void> selectDivision(DivisionModel? division, AppLocalizations localizations) async {
    selectedDivision = division;
    selectedDistrict = null;
    selectedUpazila = null;
    selectedArea = null;
    districts = [];
    upazilas = [];
    areas = [];
    _safeNotifyListeners();

    if (division == null) return;

    isLoadingDistricts = true;
    errorMessage = null;
    _safeNotifyListeners();

    try {
      districts = await repository.getDistrictsByDivision(division.id);
    } catch (e) {
      debugPrint('Error loading districts: $e');
      errorMessage = localizations.districtNoLoadPrompt;
    } finally {
      isLoadingDistricts = false;
      _safeNotifyListeners();
    }
  }

  Future<void> selectDistrict(DistrictModel? district, AppLocalizations localizations) async {
    selectedDistrict = district;
    selectedUpazila = null;
    selectedArea = null;
    upazilas = [];
    areas = [];
    _safeNotifyListeners();

    if (district == null) return;

    isLoadingUpazilas = true;
    errorMessage = null;
    _safeNotifyListeners();

    try {
      upazilas = await repository.getUpazilasByDistrict(district.id);
    } catch (e) {
      debugPrint('Error loading upazilas: $e');
      errorMessage = localizations.upazilaNoLoadPrompt;
    } finally {
      isLoadingUpazilas = false;
      _safeNotifyListeners();
    }
  }

  Future<void> selectUpazila(UpazilaModel? upazila, AppLocalizations localizations) async {
    selectedUpazila = upazila;
    selectedArea = null;
    areas = [];
    _safeNotifyListeners();

    if (upazila == null) return;

    isLoadingAreas = true;
    errorMessage = null;
    _safeNotifyListeners();

    try {
      areas = await repository.getUnionsByUpazila(upazila.id);
    } catch (e) {
      debugPrint('Error loading areas: $e');
      errorMessage = 'Could not load areas';
    } finally {
      isLoadingAreas = false;
      _safeNotifyListeners();
    }
  }

  void selectArea(UnionModel? area) {
    selectedArea = area;
    _safeNotifyListeners();
  }

  bool isPosting = false;

  bool get isSearchValid => isDemandValid;

  bool get isDemandValid {
    final hasMonth = selectedMonth != null && selectedMonth!.isNotEmpty;
    final hasHouseType = selectedHouseType != null;
    final hasDivision = selectedDivision != null;
    final hasDistrict = selectedDistrict != null;
    final hasUpazila = selectedUpazila != null;
    final hasBudget = selectedBudgetRange != null && selectedBudgetRange!.isNotEmpty;
    final hasTenantType = selectedTenantType != null;
    final hasRoomOrSeat = selectedRoomOrSeat != null && selectedRoomOrSeat!.isNotEmpty;
    final isNameValid = Validators.validateName(userName) == null;
    final isPhoneValid = Validators.validatePhoneNumber(userMobile) == null;
    final isWhatsAppValid = Validators.validateWhatsAppNumber(userWhatsApp) == null;

    return hasMonth &&
        hasHouseType &&
        hasDivision &&
        hasDistrict &&
        hasUpazila &&
        hasBudget &&
        hasTenantType &&
        hasRoomOrSeat &&
        isNameValid &&
        isPhoneValid &&
        isWhatsAppValid;
  }

  Future<String> submitDemand({
    required String tenantId,
    required String tenantEmail,
  }) async {
    assert(isDemandValid, 'submitDemand called when form is invalid');
    isPosting = true;
    _safeNotifyListeners();

    try {
      final demand = TenantDemandModel(
        id: '',
        tenantId: tenantId,
        tenantEmail: tenantEmail,
        month: selectedMonth!,
        houseType: selectedHouseType!,
        roomOrSeat: selectedRoomOrSeat!,
        division: selectedDivision!,
        district: selectedDistrict!,
        area: selectedUpazila!,
        subArea: selectedArea,
        budgetRange: selectedBudgetRange,
        tenantType: selectedTenantType,
        bathrooms: selectedBathrooms,
        attachedBathrooms: attachedBathrooms,
        kitchenCount: kitchenCount,
        balconies: selectedBalconies,
        floorNumber: selectedFloorNumber,
        electricityBillType: electricityBillType,
        hasCctv: hasCctv,
        hasWifi: hasWifi,
        hasGenerator: hasGenerator,
        hasSecurityGuard: hasSecurityGuard,
        hasLift: hasLift,
        hasParking: hasParking,
        hasGivenNotice: hasGivenNotice,
        marketDistance: marketDistance,
        userName: userName.trim(),
        userMobile: userMobile.trim(),
        userWhatsApp: userWhatsApp.trim(),
        shortAddress: shortAddress.trim(),
        detailedDescription: detailedDescription.trim(),
        postDate: DateTime.now(),
      );

      final docId = await TenantDemandFirestoreService().createDemand(demand);
      return docId;
    } finally {
      isPosting = false;
      _safeNotifyListeners();
    }
  }

  SearchFilterModel buildFilter() {
    assert(isSearchValid, 'buildFilter() called before all fields are set');
    return SearchFilterModel(
      month: selectedMonth!,
      houseType: selectedHouseType!,
      division: selectedDivision!,
      district: selectedDistrict!,
      upazila: selectedUpazila!,
      area: selectedArea,
      roomOrSeat: selectedRoomOrSeat!,
      budgetRange: selectedBudgetRange,
      tenantType: selectedTenantType,
      bathrooms: selectedBathrooms,
      balconies: selectedBalconies,
      floorNumber: selectedFloorNumber,
      hasLift: hasLift,
      hasParking: hasParking,
      sortBy: selectedSortBy,
    );
  }

  void resetFilters() {
    selectedMonth = null;
    selectedHouseType = null;
    selectedDivision = null;
    selectedDistrict = null;
    selectedUpazila = null;
    selectedArea = null;
    selectedRoomOrSeat = null;
    selectedBudgetRange = null;
    selectedTenantType = null;
    selectedBathrooms = null;
    attachedBathrooms = null;
    selectedBalconies = null;
    selectedFloorNumber = null;
    kitchenCount = null;
    hasLift = null;
    hasParking = null;
    hasGivenNotice = null;
    userName = '';
    userMobile = '';
    userWhatsApp = '';
    electricityBillType = null;
    hasCctv = null;
    hasWifi = null;
    hasGenerator = null;
    hasSecurityGuard = null;
    marketDistance = null;
    shortAddress = '';
    detailedDescription = '';
    selectedSortBy = SortBy.newest;
    errorMessage = null;
    isLoadingDivisions = false;
    isLoadingDistricts = false;
    isLoadingUpazilas = false;
    isLoadingAreas = false;
    districts = [];
    upazilas = [];
    areas = [];
    _safeNotifyListeners();
  }
}
