import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/sub_area_model.dart';

export 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';

class TenantDemandModel {
  final String id;
  final String tenantId;
  final String tenantEmail;
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
    this.tenantId = '',
    this.tenantEmail = '',
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
    this.userWhatsApp = '',
    this.shortAddress = '',
    this.detailedDescription = '',
    required this.postDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'tenantEmail': tenantEmail,
      'month': month,
      'houseType': houseType.name,
      'roomOrSeat': roomOrSeat,
      'division': division.toMap(),
      'district': district.toMap(),
      'area': area.toMap(),
      'subArea': subArea?.toMap(),
      'budgetRange': budgetRange,
      'tenantType': tenantType?.name,
      'bathrooms': bathrooms,
      'attachedBathrooms': attachedBathrooms,
      'kitchenCount': kitchenCount,
      'balconies': balconies,
      'floorNumber': floorNumber,
      'electricityBillType': electricityBillType,
      'hasCctv': hasCctv,
      'hasWifi': hasWifi,
      'hasGenerator': hasGenerator,
      'hasSecurityGuard': hasSecurityGuard,
      'hasLift': hasLift,
      'hasParking': hasParking,
      'hasGivenNotice': hasGivenNotice,
      'marketDistance': marketDistance,
      'userName': userName,
      'userMobile': userMobile,
      'userWhatsApp': userWhatsApp,
      'shortAddress': shortAddress,
      'detailedDescription': detailedDescription,
      'postDate': Timestamp.fromDate(postDate),
    };
  }

  factory TenantDemandModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    HouseType parseHouseType(dynamic val) {
      if (val == null) return HouseType.flat;
      return HouseType.values.firstWhere(
        (e) => e.name.toLowerCase() == val.toString().toLowerCase(),
        orElse: () => HouseType.flat,
      );
    }

    TenantType? parseTenantType(dynamic val) {
      if (val == null) return null;
      try {
        return TenantType.values.firstWhere(
          (e) => e.name.toLowerCase() == val.toString().toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }

    DivisionModel parseDivision(dynamic d) {
      if (d is Map<String, dynamic>) return DivisionModel.fromJson(d);
      if (d is Map) return DivisionModel.fromJson(Map<String, dynamic>.from(d));
      return const DivisionModel(id: '', name: '', bnName: '');
    }

    DistrictModel parseDistrict(dynamic d) {
      if (d is Map<String, dynamic>) return DistrictModel.fromJson(d);
      if (d is Map) return DistrictModel.fromJson(Map<String, dynamic>.from(d));
      return const DistrictModel(id: '', divisionId: '', name: '', bnName: '');
    }

    UpazilaModel parseArea(dynamic a) {
      if (a is Map<String, dynamic>) return UpazilaModel.fromJson(a);
      if (a is Map) return UpazilaModel.fromJson(Map<String, dynamic>.from(a));
      return const UpazilaModel(id: '', districtId: '', name: '', bnName: '');
    }

    UnionModel? parseSubArea(dynamic s) {
      if (s is Map<String, dynamic>) return UnionModel.fromJson(s);
      if (s is Map) return UnionModel.fromJson(Map<String, dynamic>.from(s));
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      if (v is num) return v != 0;
      return null;
    }

    return TenantDemandModel(
      id: docId,
      tenantId: map['tenantId']?.toString() ?? '',
      tenantEmail: map['tenantEmail']?.toString() ?? '',
      month: map['month']?.toString() ?? '',
      houseType: parseHouseType(map['houseType']),
      roomOrSeat: map['roomOrSeat']?.toString() ?? '',
      division: parseDivision(map['division']),
      district: parseDistrict(map['district']),
      area: parseArea(map['area']),
      subArea: parseSubArea(map['subArea']),
      budgetRange: map['budgetRange']?.toString(),
      tenantType: parseTenantType(map['tenantType']),
      bathrooms: parseInt(map['bathrooms']),
      attachedBathrooms: parseInt(map['attachedBathrooms']),
      kitchenCount: parseInt(map['kitchenCount']),
      balconies: parseInt(map['balconies']),
      floorNumber: parseInt(map['floorNumber']),
      electricityBillType: map['electricityBillType']?.toString(),
      hasCctv: parseBool(map['hasCctv']),
      hasWifi: parseBool(map['hasWifi']),
      hasGenerator: parseBool(map['hasGenerator']),
      hasSecurityGuard: parseBool(map['hasSecurityGuard']),
      hasLift: parseBool(map['hasLift']),
      hasParking: parseBool(map['hasParking']),
      hasGivenNotice: parseBool(map['hasGivenNotice']),
      marketDistance: map['marketDistance']?.toString(),
      userName: map['userName']?.toString() ?? '',
      userMobile: map['userMobile']?.toString() ?? '',
      userWhatsApp: map['userWhatsApp']?.toString() ?? '',
      shortAddress: map['shortAddress']?.toString() ?? '',
      detailedDescription: map['detailedDescription']?.toString() ?? '',
      postDate: parseDate(map['postDate']),
    );
  }

  TenantDemandModel copyWith({
    String? id,
    String? tenantId,
    String? tenantEmail,
    String? month,
    HouseType? houseType,
    String? roomOrSeat,
    DivisionModel? division,
    DistrictModel? district,
    UpazilaModel? area,
    UnionModel? subArea,
    String? budgetRange,
    TenantType? tenantType,
    int? bathrooms,
    int? attachedBathrooms,
    int? kitchenCount,
    int? balconies,
    int? floorNumber,
    String? electricityBillType,
    bool? hasCctv,
    bool? hasWifi,
    bool? hasGenerator,
    bool? hasSecurityGuard,
    bool? hasLift,
    bool? hasParking,
    bool? hasGivenNotice,
    String? marketDistance,
    String? userName,
    String? userMobile,
    String? userWhatsApp,
    String? shortAddress,
    String? detailedDescription,
    DateTime? postDate,
  }) {
    return TenantDemandModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tenantEmail: tenantEmail ?? this.tenantEmail,
      month: month ?? this.month,
      houseType: houseType ?? this.houseType,
      roomOrSeat: roomOrSeat ?? this.roomOrSeat,
      division: division ?? this.division,
      district: district ?? this.district,
      area: area ?? this.area,
      subArea: subArea ?? this.subArea,
      budgetRange: budgetRange ?? this.budgetRange,
      tenantType: tenantType ?? this.tenantType,
      bathrooms: bathrooms ?? this.bathrooms,
      attachedBathrooms: attachedBathrooms ?? this.attachedBathrooms,
      kitchenCount: kitchenCount ?? this.kitchenCount,
      balconies: balconies ?? this.balconies,
      floorNumber: floorNumber ?? this.floorNumber,
      electricityBillType: electricityBillType ?? this.electricityBillType,
      hasCctv: hasCctv ?? this.hasCctv,
      hasWifi: hasWifi ?? this.hasWifi,
      hasGenerator: hasGenerator ?? this.hasGenerator,
      hasSecurityGuard: hasSecurityGuard ?? this.hasSecurityGuard,
      hasLift: hasLift ?? this.hasLift,
      hasParking: hasParking ?? this.hasParking,
      hasGivenNotice: hasGivenNotice ?? this.hasGivenNotice,
      marketDistance: marketDistance ?? this.marketDistance,
      userName: userName ?? this.userName,
      userMobile: userMobile ?? this.userMobile,
      userWhatsApp: userWhatsApp ?? this.userWhatsApp,
      shortAddress: shortAddress ?? this.shortAddress,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      postDate: postDate ?? this.postDate,
    );
  }
}

