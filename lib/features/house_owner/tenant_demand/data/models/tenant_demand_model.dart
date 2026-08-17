import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/sub_area_model.dart';

export 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';

class TenantDemandModel {
  final String id;
  final String month;
  final HouseType houseType;
  final String roomOrSeat;
  final DivisionModel division;
  final DistrictModel district;
  final UpazilaModel area;
  final UnionModel? subArea;
  final String? budgetRange;
  final TenantType? tenantType;
  final int? bathrooms;
  final int? attachedBathrooms;
  final int? kitchenCount;
  final int? balconies;
  final int? floorNumber;
  final String? electricityBillType;
  final bool? hasCctv;
  final bool? hasWifi;
  final bool? hasGenerator;
  final bool? hasSecurityGuard;
  final bool? hasLift;
  final bool? hasParking;
  final bool? hasGivenNotice;
  final String? marketDistance;
  final String userName;
  final String userMobile;
  final String userWhatsApp;
  final String shortAddress;
  final String detailedDescription;
  final DateTime postDate;

  TenantDemandModel({
    required this.id,
    required this.month,
    required this.houseType,
    required this.roomOrSeat,
    required this.division,
    required this.district,
    required this.area,
    this.subArea,
    this.budgetRange,
    this.tenantType,
    this.bathrooms,
    this.attachedBathrooms,
    this.kitchenCount,
    this.balconies,
    this.floorNumber,
    this.electricityBillType,
    this.hasCctv,
    this.hasWifi,
    this.hasGenerator,
    this.hasSecurityGuard,
    this.hasLift,
    this.hasParking,
    this.hasGivenNotice,
    this.marketDistance,
    required this.userName,
    required this.userMobile,
    required this.userWhatsApp,
    required this.shortAddress,
    required this.detailedDescription,
    required this.postDate,
  });
}
