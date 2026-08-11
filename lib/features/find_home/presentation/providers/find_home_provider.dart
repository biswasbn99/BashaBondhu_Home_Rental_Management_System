import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/upazila_model.dart';
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

  String? errorMessage;

  List<DivisionModel> divisions = [];
  List<DistrictModel> districts = [];
  List<UpazilaModel> upazilas = [];

  DivisionModel? selectedDivision;
  DistrictModel? selectedDistrict;
  UpazilaModel? selectedUpazila;

  Future<void> loadDivisions(AppLocalizations localizations) async {
    isLoadingDistricts = false;
    isLoadingUpazilas = false;
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
    districts = [];
    upazilas = [];
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
    upazilas = [];
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

  void selectUpazila(UpazilaModel? upazila) {
    selectedUpazila = upazila;
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
      roomOrSeat: selectedRoomOrSeat!,
    );
  }

  void resetFilters() {
    selectedMonth = null;
    selectedHouseType = null;
    selectedDivision = null;
    selectedDistrict = null;
    selectedUpazila = null;
    selectedRoomOrSeat = null;
    errorMessage = null;
    isLoadingDivisions = false;
    isLoadingDistricts = false;
    isLoadingUpazilas = false;
    districts = [];
    upazilas = [];
    notifyListeners();
  }
}
