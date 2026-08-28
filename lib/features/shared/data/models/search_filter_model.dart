import 'division_model.dart';
import 'district_model.dart';
import 'area_model.dart';
import 'sub_area_model.dart';
import '../../../../l10n/app_localizations.dart';

enum HouseType { flat, room, seat, unit }

extension HouseTypeLabel on HouseType {
  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case HouseType.flat:
        return l10n.flat;
      case HouseType.room:
        return l10n.room;
      case HouseType.seat:
        return l10n.emptySeat;
      case HouseType.unit:
        return l10n.unit;
    }
  }
}

enum TenantType { family, bachelorMale, bachelorFemale, subLet }

extension TenantTypeLabel on TenantType {
  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case TenantType.family:
        return l10n.family;
      case TenantType.bachelorMale:
        return l10n.bachelorMale;
      case TenantType.bachelorFemale:
        return l10n.bachelorFemale;
      case TenantType.subLet:
        return l10n.subLet;
    }
  }
}

enum SortBy { lowestRent, highestRent, newest, oldest, nearest }

extension SortByLabel on SortBy {
  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case SortBy.lowestRent:
        return l10n.lowestRent;
      case SortBy.highestRent:
        return l10n.highestRent;
      case SortBy.newest:
        return l10n.newest;
      case SortBy.oldest:
        return l10n.oldest;
      case SortBy.nearest:
        return 'Nearest First';
    }
  }
}

class SearchFilterModel {
  const SearchFilterModel({
    this.month,
    this.houseType,
    this.division,
    this.district,
    this.upazila,
    this.area,
    this.budgetRange,
    this.tenantType,
    this.roomOrSeat,
    this.bathrooms,
    this.balconies,
    this.floorNumber,
    this.hasLift,
    this.hasParking,
    this.sortBy = SortBy.newest,
    this.isRadiusSearch = false,
    this.searchLatitude,
    this.searchLongitude,
    this.searchRadiusKm = 5.0,
    this.searchCenterAddress,
  });

  final String? month;
  final HouseType? houseType;
  final DivisionModel? division;
  final DistrictModel? district;
  final UpazilaModel? upazila;
  final UnionModel? area;
  final String? budgetRange;
  final TenantType? tenantType;
  final String? roomOrSeat;
  final int? bathrooms;
  final int? balconies;
  final int? floorNumber;
  final bool? hasLift;
  final bool? hasParking;
  final SortBy sortBy;

  // Radius Search Parameters
  final bool isRadiusSearch;
  final double? searchLatitude;
  final double? searchLongitude;
  final double? searchRadiusKm;
  final String? searchCenterAddress;

  SearchFilterModel copyWith({
    String? month,
    HouseType? houseType,
    DivisionModel? division,
    DistrictModel? district,
    UpazilaModel? upazila,
    UnionModel? area,
    String? budgetRange,
    TenantType? tenantType,
    String? roomOrSeat,
    int? bathrooms,
    int? balconies,
    int? floorNumber,
    bool? hasLift,
    bool? hasParking,
    SortBy? sortBy,
    bool? isRadiusSearch,
    double? searchLatitude,
    double? searchLongitude,
    double? searchRadiusKm,
    String? searchCenterAddress,
  }) {
    return SearchFilterModel(
      month: month ?? this.month,
      houseType: houseType ?? this.houseType,
      division: division ?? this.division,
      district: district ?? this.district,
      upazila: upazila ?? this.upazila,
      area: area ?? this.area,
      budgetRange: budgetRange ?? this.budgetRange,
      tenantType: tenantType ?? this.tenantType,
      roomOrSeat: roomOrSeat ?? this.roomOrSeat,
      bathrooms: bathrooms ?? this.bathrooms,
      balconies: balconies ?? this.balconies,
      floorNumber: floorNumber ?? this.floorNumber,
      hasLift: hasLift ?? this.hasLift,
      hasParking: hasParking ?? this.hasParking,
      sortBy: sortBy ?? this.sortBy,
      isRadiusSearch: isRadiusSearch ?? this.isRadiusSearch,
      searchLatitude: searchLatitude ?? this.searchLatitude,
      searchLongitude: searchLongitude ?? this.searchLongitude,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      searchCenterAddress: searchCenterAddress ?? this.searchCenterAddress,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (month != null) 'month': month,
      if (houseType != null) 'house_type': houseType!.name,
      if (division != null) 'division_id': division!.id,
      if (district != null) 'district_id': district!.id,
      if (upazila != null) 'upazila_id': upazila!.id,
      if (area != null) 'area_id': area!.id,
      if (budgetRange != null) 'budget': budgetRange,
      if (tenantType != null) 'tenant_type': tenantType!.name,
      if (roomOrSeat != null) 'room_or_seat': roomOrSeat,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (balconies != null) 'balconies': balconies,
      if (floorNumber != null) 'floor': floorNumber,
      if (hasLift != null) 'lift': hasLift,
      if (hasParking != null) 'parking': hasParking,
      'sort_by': sortBy.name,
      'is_radius_search': isRadiusSearch,
      if (searchLatitude != null) 'latitude': searchLatitude,
      if (searchLongitude != null) 'longitude': searchLongitude,
      if (searchRadiusKm != null) 'radius_km': searchRadiusKm,
      if (searchCenterAddress != null) 'center_address': searchCenterAddress,
    };
  }
}