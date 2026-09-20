import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../features/shared/data/models/area_model.dart';
import '../../../../features/shared/data/models/district_model.dart';
import '../../../../features/shared/data/models/division_model.dart';
import '../../../../features/shared/data/models/search_filter_model.dart';
import '../../../../features/shared/data/models/sub_area_model.dart';

class PropertyModel {
  final String id;
  final String ownerId;
  final String ownerEmail;
  final List<String> images;
  final String month;
  final HouseType houseType;
  final TenantType? tenantType;
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
  final double? latitude;
  final double? longitude;
  final String ownerVerificationStatus;
  final DateTime postDate;
  final bool isAvailable;
  final String approvalStatus; // 'approved', 'pending', 'rejected'
  final String? rejectionReason;
  final DateTime? approvedAt;

  bool get isRentedOut => !isAvailable;
  bool get isOwnerVerified => ownerVerificationStatus.toLowerCase() == 'verified';
  bool get isOwnerPending => ownerVerificationStatus.toLowerCase() == 'pending';
  bool get isOwnerUnverified => !isOwnerVerified && !isOwnerPending;
  bool get isApproved => approvalStatus == 'approved';
  bool get isPendingApproval => approvalStatus == 'pending';
  bool get isRejected => approvalStatus == 'rejected';

  /// Effective latitude with fallback to sub-area, upazila, district, and regional coordinates
  double? get effectiveLatitude {
    if (latitude != null && latitude != 0) return latitude;
    if (subArea?.coordinates != null && subArea!.coordinates!.isNotEmpty) {
      final parts = subArea!.coordinates!.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        if (lat != null && lat != 0) return lat;
      }
    }
    if (area.coordinates != null && area.coordinates!.isNotEmpty) {
      final parts = area.coordinates!.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        if (lat != null && lat != 0) return lat;
      }
    }
    if (district.coordinates != null && district.coordinates!.isNotEmpty) {
      final parts = district.coordinates!.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        if (lat != null && lat != 0) return lat;
      }
    }
    return resolveFallbackLat(district.name, division.name);
  }

  /// Effective longitude with fallback to sub-area, upazila, district, and regional coordinates
  double? get effectiveLongitude {
    if (longitude != null && longitude != 0) return longitude;
    if (subArea?.coordinates != null && subArea!.coordinates!.isNotEmpty) {
      final parts = subArea!.coordinates!.split(',');
      if (parts.length >= 2) {
        final lng = double.tryParse(parts[1].trim());
        if (lng != null && lng != 0) return lng;
      }
    }
    if (area.coordinates != null && area.coordinates!.isNotEmpty) {
      final parts = area.coordinates!.split(',');
      if (parts.length >= 2) {
        final lng = double.tryParse(parts[1].trim());
        if (lng != null && lng != 0) return lng;
      }
    }
    if (district.coordinates != null && district.coordinates!.isNotEmpty) {
      final parts = district.coordinates!.split(',');
      if (parts.length >= 2) {
        final lng = double.tryParse(parts[1].trim());
        if (lng != null && lng != 0) return lng;
      }
    }
    return resolveFallbackLng(district.name, division.name);
  }

  static double? resolveFallbackLat(String distName, String divName) {
    final d = distName.toLowerCase();
    final v = divName.toLowerCase();
    if (d.contains('dhaka') || v.contains('dhaka')) return 23.8103;
    if (d.contains('chattogram') || d.contains('chittagong') || v.contains('chattogram')) return 22.3569;
    if (d.contains('sylhet') || v.contains('sylhet')) return 24.8949;
    if (d.contains('rajshahi') || v.contains('rajshahi')) return 24.3636;
    if (d.contains('khulna') || v.contains('khulna')) return 22.8456;
    if (d.contains('barishal') || d.contains('barisal') || v.contains('barishal')) return 22.7010;
    if (d.contains('rangpur') || v.contains('rangpur')) return 25.7439;
    if (d.contains('mymensingh') || v.contains('mymensingh')) return 24.7471;
    if (d.contains('gazipur')) return 23.9999;
    if (d.contains('narayanganj')) return 23.6238;
    if (d.contains('cumilla') || d.contains('comilla')) return 23.4682;
    if (d.contains('bogura') || d.contains('bogra')) return 24.8465;
    return null;
  }

  static double? resolveFallbackLng(String distName, String divName) {
    final d = distName.toLowerCase();
    final v = divName.toLowerCase();
    if (d.contains('dhaka') || v.contains('dhaka')) return 90.4125;
    if (d.contains('chattogram') || d.contains('chittagong') || v.contains('chattogram')) return 91.7832;
    if (d.contains('sylhet') || v.contains('sylhet')) return 91.8687;
    if (d.contains('rajshahi') || v.contains('rajshahi')) return 88.6241;
    if (d.contains('khulna') || v.contains('khulna')) return 89.5403;
    if (d.contains('barishal') || d.contains('barisal') || v.contains('barishal')) return 90.3535;
    if (d.contains('rangpur') || v.contains('rangpur')) return 89.2752;
    if (d.contains('mymensingh') || v.contains('mymensingh')) return 90.4203;
    if (d.contains('gazipur')) return 90.4203;
    if (d.contains('narayanganj')) return 90.5000;
    if (d.contains('cumilla') || d.contains('comilla')) return 91.1788;
    if (d.contains('bogura') || d.contains('bogra')) return 89.3777;
    return null;
  }

  PropertyModel({
    required this.id,
    this.ownerId = '',
    this.ownerEmail = '',
    this.ownerVerificationStatus = 'unverified',
    required this.images,
    required this.month,
    required this.houseType,
    this.tenantType,
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
    this.latitude,
    this.longitude,
    required this.postDate,
    this.isAvailable = true,
    this.approvalStatus = 'approved',
    this.rejectionReason,
    this.approvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'ownerVerificationStatus': ownerVerificationStatus,
      'images': images,
      'month': month,
      'houseType': houseType.name,
      'tenantType': tenantType?.name,
      'roomOrSeat': roomOrSeat,
      'contactName': contactName,
      'amount': amount,
      'userMobile': userMobile,
      'userWhatsApp': userWhatsApp,
      'division': division.toMap(),
      'district': district.toMap(),
      'area': area.toMap(),
      'subArea': subArea?.toMap(),
      'shortAddress': shortAddress,
      'detailedDescription': detailedDescription,
      'commonBathrooms': commonBathrooms,
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
      'marketDistance': marketDistance,
      'latitude': latitude,
      'longitude': longitude,
      'postDate': postDate.toIso8601String(),
      'isAvailable': isAvailable,
      'approvalStatus': approvalStatus,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    HouseType parseHouseType(dynamic type) {
      if (type is String) {
        for (final val in HouseType.values) {
          if (val.name.toLowerCase() == type.toLowerCase()) {
            return val;
          }
        }
      }
      return HouseType.flat;
    }

    TenantType? parseTenantType(dynamic type) {
      if (type is String) {
        for (final val in TenantType.values) {
          if (val.name.toLowerCase() == type.toLowerCase()) {
            return val;
          }
        }
      }
      return null;
    }

    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is int) return DateTime.fromMillisecondsSinceEpoch(d);
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    DivisionModel parseDivision(dynamic d) {
      if (d is Map<String, dynamic>) return DivisionModel.fromJson(d);
      if (d is Map) return DivisionModel.fromJson(Map<String, dynamic>.from(d));
      return DivisionModel(id: '', name: 'Dhaka', bnName: 'ঢাকা');
    }

    DistrictModel parseDistrict(dynamic d) {
      if (d is Map<String, dynamic>) return DistrictModel.fromJson(d);
      if (d is Map) return DistrictModel.fromJson(Map<String, dynamic>.from(d));
      return DistrictModel(id: '', divisionId: '', name: 'Dhaka', bnName: 'ঢাকা');
    }

    UpazilaModel parseArea(dynamic a) {
      if (a is Map<String, dynamic>) return UpazilaModel.fromJson(a);
      if (a is Map) return UpazilaModel.fromJson(Map<String, dynamic>.from(a));
      return UpazilaModel(id: '', districtId: '', name: 'Area', bnName: 'এলাকা');
    }

    UnionModel? parseSubArea(dynamic s) {
      if (s is Map<String, dynamic>) return UnionModel.fromJson(s);
      if (s is Map) return UnionModel.fromJson(Map<String, dynamic>.from(s));
      return null;
    }

    List<String> parseImages(dynamic imgs) {
      if (imgs is List) {
        return imgs.map((e) => e.toString()).toList();
      }
      return [];
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return null;
    }

    return PropertyModel(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      ownerEmail: map['ownerEmail']?.toString() ?? '',
      ownerVerificationStatus: map['ownerVerificationStatus']?.toString() ??
          (map['isVerified'] == true ? 'verified' : 'unverified'),
      images: parseImages(map['images']),
      month: map['month']?.toString() ?? 'January',
      houseType: parseHouseType(map['houseType']),
      tenantType: parseTenantType(map['tenantType']),
      roomOrSeat: map['roomOrSeat']?.toString() ?? '',
      contactName: map['contactName']?.toString() ?? '',
      amount: map['amount']?.toString() ?? '',
      userMobile: map['userMobile']?.toString() ?? '',
      userWhatsApp: map['userWhatsApp']?.toString() ?? '',
      division: parseDivision(map['division']),
      district: parseDistrict(map['district']),
      area: parseArea(map['area']),
      subArea: parseSubArea(map['subArea']),
      shortAddress: map['shortAddress']?.toString() ?? '',
      detailedDescription: map['detailedDescription']?.toString() ?? '',
      commonBathrooms: parseInt(map['commonBathrooms']),
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
      longitude: parseDouble(map['longitude']),
      postDate: parseDate(map['postDate'] ?? map['createdAt'] ?? map['timestamp']),
      isAvailable: parseBool(map['isAvailable']) ?? true,
      approvalStatus: map['approvalStatus']?.toString() ??
          (map['isApproved'] == false ? 'pending' : (parseBool(map['isAvailable']) == false && map['approvalStatus'] == null ? 'approved' : 'approved')),
      rejectionReason: map['rejectionReason']?.toString(),
      approvedAt: map['approvedAt'] != null ? parseDate(map['approvedAt']) : null,
    );
  }

  PropertyModel copyWith({
    String? id,
    String? ownerId,
    String? ownerEmail,
    String? ownerVerificationStatus,
    List<String>? images,
    String? month,
    HouseType? houseType,
    TenantType? tenantType,
    String? roomOrSeat,
    String? contactName,
    String? amount,
    String? userMobile,
    String? userWhatsApp,
    DivisionModel? division,
    DistrictModel? district,
    UpazilaModel? area,
    UnionModel? subArea,
    String? shortAddress,
    String? detailedDescription,
    int? commonBathrooms,
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
    String? marketDistance,
    double? latitude,
    double? longitude,
    DateTime? postDate,
    bool? isAvailable,
    String? approvalStatus,
    String? rejectionReason,
    DateTime? approvedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerVerificationStatus: ownerVerificationStatus ?? this.ownerVerificationStatus,
      images: images ?? this.images,
      month: month ?? this.month,
      houseType: houseType ?? this.houseType,
      tenantType: tenantType ?? this.tenantType,
      roomOrSeat: roomOrSeat ?? this.roomOrSeat,
      contactName: contactName ?? this.contactName,
      amount: amount ?? this.amount,
      userMobile: userMobile ?? this.userMobile,
      userWhatsApp: userWhatsApp ?? this.userWhatsApp,
      division: division ?? this.division,
      district: district ?? this.district,
      area: area ?? this.area,
      subArea: subArea ?? this.subArea,
      shortAddress: shortAddress ?? this.shortAddress,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      commonBathrooms: commonBathrooms ?? this.commonBathrooms,
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
      marketDistance: marketDistance ?? this.marketDistance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      postDate: postDate ?? this.postDate,
      isAvailable: isAvailable ?? this.isAvailable,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
