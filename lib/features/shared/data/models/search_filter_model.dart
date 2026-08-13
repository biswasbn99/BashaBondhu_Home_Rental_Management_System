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

enum SortBy { lowestRent, highestRent, newest, oldest }

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
    }
  }
}

class SearchFilterModel {
  const SearchFilterModel({
    required this.month,
    required this.houseType,
    required this.division,
    required this.district,
    required this.upazila,
    this.area,
    required this.roomOrSeat,
    this.budgetRange,
    this.tenantType,
    this.bathrooms,
    this.balconies,
    this.floorNumber,
    this.hasLift,
    this.hasParking,
    this.sortBy = SortBy.newest,
  });

  final String month;
  final HouseType houseType;
  final DivisionModel division;
  final DistrictModel district;
  final UpazilaModel upazila;
  final UnionModel? area;
  final String roomOrSeat;
  final String? budgetRange;
  final TenantType? tenantType;
  final int? bathrooms;
  final int? balconies;
  final int? floorNumber;
  final bool? hasLift;
  final bool? hasParking;
  final SortBy sortBy;

  Map<String, dynamic> toQueryParams() {
    return {
      'month': month,
      'house_type': houseType.name,
      'division_id': division.id,
      'district_id': district.id,
      'upazila_id': upazila.id,
      if (area != null) 'area_id': area!.id,
      'room_or_seat': roomOrSeat,
      if (budgetRange != null) 'budget': budgetRange,
      if (tenantType != null) 'tenant_type': tenantType!.name,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (balconies != null) 'balconies': balconies,
      if (floorNumber != null) 'floor': floorNumber,
      if (hasLift != null) 'lift': hasLift,
      if (hasParking != null) 'parking': hasParking,
      'sort_by': sortBy.name,
    };
  }
}