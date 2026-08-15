import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/sub_area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/repository/location_repository.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DemandHomeProvider extends ChangeNotifier {
  DemandHomeProvider({LocationRepository? repository})
      : repository = repository ?? LocationRepository();

  final LocationRepository repository;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  String? selectedMonth;

  void selectMonth(String? value) {
    selectedMonth = value;
    _safeNotifyListeners();
  }

  static const List<HouseType> houseTypes = HouseType.values;

  HouseType? selectedHouseType;

  void selectHouseType(HouseType? value) {
    selectedHouseType = value;
    selectedRoomOrSeat = null; // options depend on house type
    _safeNotifyListeners();
  }

  List<String> roomOrSeatOptions(AppLocalizations localizations) {
    switch (selectedHouseType) {
      case HouseType.flat:
        return List.generate(8, (i) => "${localizations.bedroom} - ${i + 1}");
      case HouseType.room:
        return List.generate(8, (i) => "${localizations.room} - ${i + 1}");
      case HouseType.seat:
        return List.generate(8, (i) => "${localizations.emptySeat} - ${i + 1}");
      case HouseType.unit:
        return List.generate(8, (i) => "${localizations.unit} - ${i + 1}");
      case null:
        return const [];
    }
  }

  String roomOrSeatHint(AppLocalizations localizations) {
    switch (selectedHouseType) {
      case HouseType.flat:
        return localizations.bedroomNo;
      case HouseType.room:
        return localizations.roomNo;
      case HouseType.seat:
        return localizations.emptySeatNo;
      case HouseType.unit:
        return localizations.unitNo;
      case null:
        return localizations.roomOrSeatNo;
    }
  }

  String? selectedRoomOrSeat;

  void selectRoomOrSeat(String? value) {
    selectedRoomOrSeat = value;
    _safeNotifyListeners();
  }

  bool isLoadingDivisions = false;
  bool isLoadingDistricts = false;
  bool isLoadingUpazilas = false;
  bool isLoadingAreas = false;

  String? errorMessage;

  List<DivisionModel> divisions = [];
  List<DistrictModel> districts = [];
  List<UpazilaModel> upazilas = [];
  List<UnionModel> areas = [];

  DivisionModel? selectedDivision;
  DistrictModel? selectedDistrict;
  UpazilaModel? selectedUpazila;
  UnionModel? selectedArea;

  // New Filters
  String? selectedBudgetRange;
  TenantType? selectedTenantType;
  int? selectedBathrooms;
  int? selectedBalconies;
  int? selectedFloorNumber;
  bool? hasLift;
  bool? hasParking;
  bool? hasGivenNotice;
  SortBy selectedSortBy = SortBy.newest;

  String userName = '';
  String userMobile = '';
  String userWhatsApp = '';

  static List<String> budgetRanges = List.generate(
    50,
    (index) => ((index + 1) * 1000).toString(),
  );

  void selectBudget(String? value) {
    selectedBudgetRange = value;
    _safeNotifyListeners();
  }

  void selectTenantType(TenantType? value) {
    selectedTenantType = value;
    _safeNotifyListeners();
  }

  void selectBathrooms(int? value) {
    selectedBathrooms = value;
    _safeNotifyListeners();
  }

  void selectBalconies(int? value) {
    selectedBalconies = value;
    _safeNotifyListeners();
  }

  void selectFloor(int? value) {
    selectedFloorNumber = value;
    _safeNotifyListeners();
  }

  void selectLift(bool? value) {
    hasLift = value;
    _safeNotifyListeners();
  }

  void selectParking(bool? value) {
    hasParking = value;
    _safeNotifyListeners();
  }

  void selectNoticeStatus(bool? value) {
    hasGivenNotice = value;
    _safeNotifyListeners();
  }

  void setUserName(String value) {
    userName = value;
    _safeNotifyListeners();
  }

  void setUserMobile(String value) {
    userMobile = value;
    _safeNotifyListeners();
  }

  void setUserWhatsApp(String value) {
    userWhatsApp = value;
    _safeNotifyListeners();
  }

  void selectSortBy(SortBy value) {
    selectedSortBy = value;
    _safeNotifyListeners();
  }

  Future<void> loadDivisions(AppLocalizations localizations) async {
    isLoadingDistricts = false;
    isLoadingUpazilas = false;
    isLoadingAreas = false;
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

  bool get isSearchValid =>
      selectedMonth != null &&
      selectedHouseType != null &&
      selectedDivision != null &&
      selectedDistrict != null &&
      selectedUpazila != null &&
      selectedRoomOrSeat != null &&
      userName.trim().isNotEmpty &&
      RegExp(r'^01[3-9]\d{8}$').hasMatch(userMobile);

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
    selectedBalconies = null;
    selectedFloorNumber = null;
    hasLift = null;
    hasParking = null;
    hasGivenNotice = null;
    userName = '';
    userMobile = '';
    userWhatsApp = '';
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
