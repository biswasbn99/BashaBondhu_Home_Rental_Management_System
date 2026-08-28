import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/sub_area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/repository/location_repository.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FindHomeProvider extends ChangeNotifier {
  FindHomeProvider({LocationRepository? repository})
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

  // --- Search Mode ---
  bool isRadiusSearchMode = true; // Default: Nearby Radius Search (e.g. 5km)
  double searchRadiusKm = 5.0;
  double searchLatitude = 23.8103; // Default center (Dhaka)
  double searchLongitude = 90.4125;
  String? searchLocationName;
  bool isFetchingGps = false;

  void setSearchMode(bool isRadius) {
    isRadiusSearchMode = isRadius;
    _safeNotifyListeners();
  }

  void setRadiusKm(double km) {
    searchRadiusKm = km;
    _safeNotifyListeners();
  }

  void setCenterLocation(double lat, double lng, [String? name]) {
    searchLatitude = lat;
    searchLongitude = lng;
    searchLocationName = name;
    _safeNotifyListeners();
  }

  bool _hasAttemptedAutoLocation = false;

  Future<void> initLocationOnOpen(AppLocalizations l10n) async {
    if (_hasAttemptedAutoLocation) return;
    _hasAttemptedAutoLocation = true;

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position? position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.medium,
            forceLocationManager: true,
            timeLimit: const Duration(seconds: 4),
          ),
        );
        searchLatitude = position.latitude;
        searchLongitude = position.longitude;
        searchLocationName = l10n.useMyGps;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Auto location acquisition failed gracefully: $e');
    }
  }

  Future<bool> fetchCurrentGps(AppLocalizations l10n, [BuildContext? context]) async {
    isFetchingGps = true;
    _safeNotifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationServiceDisabled)),
          );
        }
        isFetchingGps = false;
        _safeNotifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.locationPermissionDenied)),
            );
          }
          isFetchingGps = false;
          _safeNotifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionDenied)),
          );
        }
        isFetchingGps = false;
        _safeNotifyListeners();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      searchLatitude = position.latitude;
      searchLongitude = position.longitude;
      searchLocationName = l10n.useMyGps;
      isFetchingGps = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error getting GPS in FindHomeProvider: $e');
      isFetchingGps = false;
      _safeNotifyListeners();
      return false;
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
  SortBy selectedSortBy = SortBy.newest;

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

  bool get isSearchValid {
    if (isRadiusSearchMode) {
      return true;
    } else {
      return selectedMonth != null &&
          selectedHouseType != null &&
          selectedDivision != null &&
          selectedDistrict != null &&
          selectedUpazila != null &&
          selectedArea != null &&
          selectedBudgetRange != null &&
          selectedTenantType != null;
    }
  }

  SearchFilterModel buildFilter() {
    if (isRadiusSearchMode) {
      return SearchFilterModel(
        isRadiusSearch: true,
        searchLatitude: searchLatitude,
        searchLongitude: searchLongitude,
        searchRadiusKm: searchRadiusKm,
        searchCenterAddress: searchLocationName,
        month: selectedMonth,
        houseType: selectedHouseType,
        budgetRange: selectedBudgetRange,
        tenantType: selectedTenantType,
        roomOrSeat: selectedRoomOrSeat,
        bathrooms: selectedBathrooms,
        balconies: selectedBalconies,
        floorNumber: selectedFloorNumber,
        hasLift: hasLift,
        hasParking: hasParking,
        sortBy: SortBy.nearest,
      );
    } else {
      return SearchFilterModel(
        isRadiusSearch: false,
        month: selectedMonth!,
        houseType: selectedHouseType!,
        division: selectedDivision!,
        district: selectedDistrict!,
        upazila: selectedUpazila!,
        area: selectedArea,
        budgetRange: selectedBudgetRange!,
        tenantType: selectedTenantType!,
        roomOrSeat: selectedRoomOrSeat,
        bathrooms: selectedBathrooms,
        balconies: selectedBalconies,
        floorNumber: selectedFloorNumber,
        hasLift: hasLift,
        hasParking: hasParking,
        sortBy: selectedSortBy,
      );
    }
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
    _safeNotifyListeners();
  }
}
