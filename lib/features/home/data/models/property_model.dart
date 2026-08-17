import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/sub_area_model.dart';

class PropertyModel {
  final String id;
  final List<String> images;
  final String month;
  final HouseType houseType;
  final String roomOrSeat;
  final String contactName;
  final String amount;
  final String userMobile;
  final String userWhatsApp;
  final DivisionModel division;
  final DistrictModel district;
  final UpazilaModel area;
  final UnionModel? subArea;
  final String shortAddress;
  final String detailedDescription;
  final int? commonBathrooms;
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
  final String? marketDistance;
  final DateTime postDate;

  PropertyModel({
    required this.id,
    required this.images,
    required this.month,
    required this.houseType,
    required this.roomOrSeat,
    required this.contactName,
    required this.amount,
    required this.userMobile,
    required this.userWhatsApp,
    required this.division,
    required this.district,
    required this.area,
    this.subArea,
    required this.shortAddress,
    required this.detailedDescription,
    this.commonBathrooms,
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
    this.marketDistance,
    required this.postDate,
  });

  // Future fromJson/toJson for Firebase can be added here
}
