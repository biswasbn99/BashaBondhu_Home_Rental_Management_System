import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/home/data/models/property_model.dart';
import '../../../../features/shared/data/models/area_model.dart';
import '../../../../features/shared/data/models/district_model.dart';
import '../../../../features/shared/data/models/division_model.dart';
import '../../../../features/shared/data/models/search_filter_model.dart';
import '../../../../features/shared/data/models/sub_area_model.dart';
import '../../../../features/shared/data/repository/location_repository.dart';
import '../../../../features/shared/data/services/property_firestore_service.dart';
import '../../../../l10n/app_localizations.dart';

class HomeRentPostProvider extends ChangeNotifier {
  HomeRentPostProvider({LocationRepository? repository})
      : repository = repository ?? LocationRepository();

  final LocationRepository repository;
  final PropertyFirestoreService _firestoreService = PropertyFirestoreService();

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

  static const List<HouseType> houseTypes = HouseType.values;

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

  // --- Photos ---
  final List<File> _images = [];
  List<File> get images => _images;

  File? get thumbnail => _images.isNotEmpty ? _images.first : null;
  List<File> get additionalImages => _images.length > 1 ? _images.sublist(1) : [];

  void addImage(File image) {
    if (_images.length < 10) {
      _images.add(image);
      _safeNotifyListeners();
    }
  }

  void addMultipleImages(List<File> newImages) {
    for (final img in newImages) {
      if (_images.length >= 10) break;
      _images.add(img);
    }
    _safeNotifyListeners();
  }

  void setThumbnail(File image) {
    if (_images.isEmpty) {
      _images.add(image);
    } else {
      _images[0] = image;
    }
    _safeNotifyListeners();
  }

  void replaceImage(int index, File image) {
    if (index >= 0 && index < _images.length) {
      _images[index] = image;
      _safeNotifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      _safeNotifyListeners();
    }
  }

  // --- Basic Info ---
  String? selectedMonth;
  HouseType? selectedHouseType;
  TenantType? selectedTenantType;
  String? selectedRoomOrSeat;
  String contactName = '';
  String amount = '';
  String userMobile = '';
  String userWhatsApp = '';

  // --- Location ---
  DivisionModel? selectedDivision;
  DistrictModel? selectedDistrict;
  UpazilaModel? selectedUpazila;
  UnionModel? selectedArea;
  String shortAddress = '';
  String detailedDescription = '';

  // --- Amenities & Counts ---
  int? commonBathrooms;
  int? attachedBathrooms;
  int? kitchenCount;
  int? balconies;
  int? floorNumber;
  String? electricityBillType;
  bool? hasCctv;
  bool? hasWifi;
  bool? hasGenerator;
  bool? hasSecurityGuard;
  bool? hasLift;
  bool? hasParking;
  String? marketDistance;

  // --- Form & Submit State ---
  bool isSubmitting = false;
  bool showValidationErrors = false;

  // --- Lists ---
  List<DivisionModel> divisions = [];
  List<DistrictModel> districts = [];
  List<UpazilaModel> upazilas = [];
  List<UnionModel> areas = [];

  bool isLoadingDivisions = false;
  bool isLoadingDistricts = false;
  bool isLoadingUpazilas = false;
  bool isLoadingAreas = false;
  String? errorMessage;

  // --- Setters ---
  void setContactName(String value) {
    contactName = value;
    _safeNotifyListeners();
  }

  void setAmount(String value) {
    amount = value;
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

  void setShortAddress(String value) {
    shortAddress = value;
    _safeNotifyListeners();
  }

  void setDetailedDescription(String value) {
    detailedDescription = value;
    _safeNotifyListeners();
  }

  void selectMonth(String? value) {
    selectedMonth = value;
    _safeNotifyListeners();
  }

  void selectHouseType(HouseType? value) {
    selectedHouseType = value;
    selectedRoomOrSeat = null;
    _safeNotifyListeners();
  }

  void selectTenantType(TenantType? value) {
    selectedTenantType = value;
    _safeNotifyListeners();
  }

  void selectRoomOrSeat(String? value) {
    selectedRoomOrSeat = value;
    _safeNotifyListeners();
  }

  void selectCommonBathrooms(int? value) {
    commonBathrooms = value;
    _safeNotifyListeners();
  }

  void selectAttachedBathrooms(int? value) {
    attachedBathrooms = value;
    _safeNotifyListeners();
  }

  void selectKitchenCount(int? value) {
    kitchenCount = value;
    _safeNotifyListeners();
  }

  void selectBalconies(int? value) {
    balconies = value;
    _safeNotifyListeners();
  }

  void selectFloor(int? value) {
    floorNumber = value;
    _safeNotifyListeners();
  }

  void selectElectricityBillType(String? value) {
    electricityBillType = value;
    _safeNotifyListeners();
  }

  void selectCctv(bool? value) {
    hasCctv = value;
    _safeNotifyListeners();
  }

  void selectWifi(bool? value) {
    hasWifi = value;
    _safeNotifyListeners();
  }

  void selectGenerator(bool? value) {
    hasGenerator = value;
    _safeNotifyListeners();
  }

  void selectSecurityGuard(bool? value) {
    hasSecurityGuard = value;
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

  void selectMarketDistance(String? value) {
    marketDistance = value;
    _safeNotifyListeners();
  }

  // --- Location Actions ---
  Future<void> loadDivisions(AppLocalizations localizations) async {
    isLoadingDivisions = true;
    errorMessage = null;
    _safeNotifyListeners();
    try {
      divisions = await repository.getDivisions();
    } catch (e) {
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
    try {
      districts = await repository.getDistrictsByDivision(division.id);
    } catch (e) {
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
    try {
      upazilas = await repository.getUpazilasByDistrict(district.id);
    } catch (e) {
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
    try {
      areas = await repository.getUnionsByUpazila(upazila.id);
    } catch (e) {
      errorMessage = 'Could not load sub-areas';
    } finally {
      isLoadingAreas = false;
      _safeNotifyListeners();
    }
  }

  void selectArea(UnionModel? area) {
    selectedArea = area;
    _safeNotifyListeners();
  }

  // --- Validation ---
  bool get hasThumbnail => _images.isNotEmpty;

  bool get isFormValid {
    return hasThumbnail &&
        selectedMonth != null &&
        selectedHouseType != null &&
        selectedDivision != null &&
        selectedDistrict != null &&
        selectedUpazila != null &&
        selectedRoomOrSeat != null &&
        contactName.trim().isNotEmpty &&
        amount.trim().isNotEmpty &&
        userMobile.trim().isNotEmpty &&
        shortAddress.trim().isNotEmpty &&
        detailedDescription.trim().isNotEmpty;
  }

  void triggerValidation() {
    showValidationErrors = true;
    _safeNotifyListeners();
  }

  /// Publish post to Cloud Firestore
  double? latitude;
  double? longitude;

  void setLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    _safeNotifyListeners();
  }

  void clearLocation() {
    latitude = null;
    longitude = null;
    _safeNotifyListeners();
  }

  Future<bool> publishPost(UserModel? currentUser) async {
    triggerValidation();

    if (!isFormValid) {
      return false;
    }

    isSubmitting = true;
    _safeNotifyListeners();

    try {
      final ownerFullName = (currentUser != null)
          ? "${currentUser.firstName} ${currentUser.lastName}".trim()
          : '';
      final finalContactName = ownerFullName.isNotEmpty ? ownerFullName : contactName.trim();
      final finalUserMobile = (currentUser != null && currentUser.mobile.isNotEmpty)
          ? currentUser.mobile
          : userMobile.trim();

      final newProperty = PropertyModel(
        id: '',
        ownerId: currentUser?.uid ?? 'guest_owner',
        ownerEmail: currentUser?.email ?? '',
        ownerVerificationStatus: currentUser?.verificationStatus ?? 'unverified',
        images: [],
        month: selectedMonth!,
        houseType: selectedHouseType!,
        tenantType: selectedTenantType,
        roomOrSeat: selectedRoomOrSeat!,
        contactName: finalContactName,
        amount: amount.trim(),
        userMobile: finalUserMobile,
        userWhatsApp: userWhatsApp.trim().isNotEmpty ? userWhatsApp.trim() : finalUserMobile,
        division: selectedDivision!,
        district: selectedDistrict!,
        area: selectedUpazila!,
        subArea: selectedArea,
        shortAddress: shortAddress.trim(),
        detailedDescription: detailedDescription.trim(),
        commonBathrooms: commonBathrooms,
        attachedBathrooms: attachedBathrooms,
        kitchenCount: kitchenCount,
        balconies: balconies,
        floorNumber: floorNumber,
        electricityBillType: electricityBillType,
        hasCctv: hasCctv,
        hasWifi: hasWifi,
        hasGenerator: hasGenerator,
        hasSecurityGuard: hasSecurityGuard,
        hasLift: hasLift,
        hasParking: hasParking,
        marketDistance: marketDistance,
        latitude: latitude,
        longitude: longitude,
        postDate: DateTime.now(),
        isAvailable: true,
      );

      await _firestoreService.createProperty(
        property: newProperty,
        localImages: _images,
      );

      clearForm();
      isSubmitting = false;
      showValidationErrors = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error publishing post: $e');
      isSubmitting = false;
      _safeNotifyListeners();
      return false;
    }
  }

  void clearForm() {
    _images.clear();
    selectedMonth = null;
    selectedHouseType = null;
    selectedTenantType = null;
    selectedRoomOrSeat = null;
    contactName = '';
    amount = '';
    userMobile = '';
    userWhatsApp = '';
    selectedDivision = null;
    selectedDistrict = null;
    selectedUpazila = null;
    selectedArea = null;
    shortAddress = '';
    detailedDescription = '';
    commonBathrooms = null;
    attachedBathrooms = null;
    kitchenCount = null;
    balconies = null;
    floorNumber = null;
    electricityBillType = null;
    hasCctv = null;
    hasWifi = null;
    hasGenerator = null;
    hasSecurityGuard = null;
    hasLift = null;
    hasParking = null;
    marketDistance = null;
    latitude = null;
    longitude = null;
    showValidationErrors = false;
    _safeNotifyListeners();
  }
}
