import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/sub_area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/repository/location_repository.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FindHomeProvider extends ChangeNotifier {
  FindHomeProvider({LocationRepository? repository})
      : repository = repository ?? LocationRepository();

  final LocationRepository repository;

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
    notifyListeners();
  }

  static const List<HouseType> houseTypes = HouseType.values;

  HouseType? selectedHouseType;

  void selectHouseType(HouseType? value) {
    selectedHouseType = value;
    selectedRoomOrSeat = null; // options depend on house type
    notifyListeners();
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
    notifyListeners();
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
  SortBy selectedSortBy = SortBy.newest;

  static List<String> budgetRanges = [
    '1000 - 5000',
    '5000 - 10000',
    '10000 - 20000',
    '20000 - 30000',
    '30000 - 50000',
    '50000+',
  ];

  void selectBudget(String? value) {
    selectedBudgetRange = value;
    notifyListeners();
  }

  void selectTenantType(TenantType? value) {
    selectedTenantType = value;
    notifyListeners();
  }

  void selectBathrooms(int? value) {
    selectedBathrooms = value;
    notifyListeners();
  }

  void selectBalconies(int? value) {
    selectedBalconies = value;
    notifyListeners();
  }

  void selectFloor(int? value) {
    selectedFloorNumber = value;
    notifyListeners();
  }

  void selectLift(bool? value) {
    hasLift = value;
    notifyListeners();
  }

  void selectParking(bool? value) {
    hasParking = value;
    notifyListeners();
  }

  void selectSortBy(SortBy value) {
    selectedSortBy = value;
    notifyListeners();
  }

  Future<void> loadDivisions(AppLocalizations localizations) async {
    isLoadingDistricts = false;
    isLoadingUpazilas = false;
    isLoadingAreas = false;
    isLoadingDivisions = true;
    errorMessage = null;
    notifyListeners();

    try {
      divisions = await repository.getDivisions();
    } catch (_) {
      errorMessage = localizations.divisionNoLoadPrompt;
    } finally {
      isLoadingDivisions = false;
      notifyListeners();
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
    notifyListeners();

    if (division == null) return;

    isLoadingDistricts = true;
    errorMessage = null;
    notifyListeners();

    try {
      districts = await repository.getDistrictsByDivision(division.id);
    } catch (_) {
      errorMessage = localizations.districtNoLoadPrompt;
    } finally {
      isLoadingDistricts = false;
      notifyListeners();
    }
  }

  Future<void> selectDistrict(DistrictModel? district, AppLocalizations localizations) async {
    selectedDistrict = district;
    selectedUpazila = null;
    selectedArea = null;
    upazilas = [];
    areas = [];
    notifyListeners();

    if (district == null) return;

    isLoadingUpazilas = true;
    errorMessage = null;
    notifyListeners();

    try {
      upazilas = await repository.getUpazilasByDistrict(district.id);
    } catch (_) {
      errorMessage = localizations.upazilaNoLoadPrompt;
    } finally {
      isLoadingUpazilas = false;
      notifyListeners();
    }
  }

  Future<void> selectUpazila(UpazilaModel? upazila, AppLocalizations localizations) async {
    selectedUpazila = upazila;
    selectedArea = null;
    areas = [];
    notifyListeners();

    if (upazila == null) return;

    isLoadingAreas = true;
    errorMessage = null;
    notifyListeners();

    try {
      areas = await repository.getUnionsByUpazila(upazila.id);
    } catch (_) {
      errorMessage = 'Could not load areas';
    } finally {
      isLoadingAreas = false;
      notifyListeners();
    }
  }

  void selectArea(UnionModel? area) {
    selectedArea = area;
    notifyListeners();
  }

  bool get isSearchValid =>
      selectedMonth != null &&
      selectedHouseType != null &&
      selectedDivision != null &&
      selectedDistrict != null &&
      selectedUpazila != null &&
      selectedRoomOrSeat != null;

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
    selectedSortBy = SortBy.newest;
    errorMessage = null;
    isLoadingDivisions = false;
    isLoadingDistricts = false;
    isLoadingUpazilas = false;
    isLoadingAreas = false;
    districts = [];
    upazilas = [];
    areas = [];
    notifyListeners();
  }
}
