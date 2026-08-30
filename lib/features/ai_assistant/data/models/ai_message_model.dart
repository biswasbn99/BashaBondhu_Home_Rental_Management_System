import '../../../../features/home/data/models/property_model.dart';
import '../../../../features/tenant/data/models/tenant_demand_model.dart';

enum AIMessageSender { user, ai, system }

/// Draft for conversational Tenant Demand creation
class DemandDraftModel {
  final String? division;
  final String? district;
  final String? area;
  final String? subArea;
  final String? budgetRange;
  final String? roomOrSeat;
  final String? houseType;
  final String? tenantType;
  final String? preferredDate;

  const DemandDraftModel({
    this.division,
    this.district,
    this.area,
    this.subArea,
    this.budgetRange,
    this.roomOrSeat,
    this.houseType,
    this.tenantType,
    this.preferredDate,
  });

  bool get isComplete =>
      area != null &&
      budgetRange != null &&
      roomOrSeat != null;

  DemandDraftModel copyWith({
    String? division,
    String? district,
    String? area,
    String? subArea,
    String? budgetRange,
    String? roomOrSeat,
    String? houseType,
    String? tenantType,
    String? preferredDate,
  }) {
    return DemandDraftModel(
      division: division ?? this.division,
      district: district ?? this.district,
      area: area ?? this.area,
      subArea: subArea ?? this.subArea,
      budgetRange: budgetRange ?? this.budgetRange,
      roomOrSeat: roomOrSeat ?? this.roomOrSeat,
      houseType: houseType ?? this.houseType,
      tenantType: tenantType ?? this.tenantType,
      preferredDate: preferredDate ?? this.preferredDate,
    );
  }
}

/// Draft for conversational House Owner Property post creation
class PropertyDraftModel {
  final String? title;
  final String? division;
  final String? district;
  final String? area;
  final String? subArea;
  final String? amount;
  final String? roomOrSeat;
  final String? houseType;
  final String? tenantType;
  final String? floorNumber;
  final List<String> amenities;
  final String? description;

  const PropertyDraftModel({
    this.title,
    this.division,
    this.district,
    this.area,
    this.subArea,
    this.amount,
    this.roomOrSeat,
    this.houseType,
    this.tenantType,
    this.floorNumber,
    this.amenities = const [],
    this.description,
  });

  bool get isComplete =>
      area != null &&
      amount != null &&
      roomOrSeat != null;

  PropertyDraftModel copyWith({
    String? title,
    String? division,
    String? district,
    String? area,
    String? subArea,
    String? amount,
    String? roomOrSeat,
    String? houseType,
    String? tenantType,
    String? floorNumber,
    List<String>? amenities,
    String? description,
  }) {
    return PropertyDraftModel(
      title: title ?? this.title,
      division: division ?? this.division,
      district: district ?? this.district,
      area: area ?? this.area,
      subArea: subArea ?? this.subArea,
      amount: amount ?? this.amount,
      roomOrSeat: roomOrSeat ?? this.roomOrSeat,
      houseType: houseType ?? this.houseType,
      tenantType: tenantType ?? this.tenantType,
      floorNumber: floorNumber ?? this.floorNumber,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
    );
  }
}

/// Matched tenant demand with match score percentage
class MatchingDemandItem {
  final TenantDemandModel demand;
  final int matchPercentage;
  final String matchReason;

  const MatchingDemandItem({
    required this.demand,
    required this.matchPercentage,
    required this.matchReason,
  });
}

/// Real-time live statistics for Admin Assistant
class AdminStatsModel {
  final int totalProperties;
  final int totalUsers;
  final int totalTenants;
  final int totalOwners;
  final int totalDemands;
  final int totalSubscriptions;
  final double totalRevenue;
  final List<Map<String, dynamic>> topAreas;

  const AdminStatsModel({
    required this.totalProperties,
    required this.totalUsers,
    required this.totalTenants,
    required this.totalOwners,
    required this.totalDemands,
    required this.totalSubscriptions,
    required this.totalRevenue,
    required this.topAreas,
  });
}

/// Complete AI chat message model
class AIMessageModel {
  final String id;
  final String text;
  final AIMessageSender sender;
  final DateTime timestamp;
  final List<PropertyModel>? properties;
  final List<MatchingDemandItem>? matchingDemands;
  final List<TenantDemandModel>? rawDemands;
  final DemandDraftModel? demandDraft;
  final PropertyDraftModel? propertyDraft;
  final AdminStatsModel? adminStats;
  final List<String>? quickActions;
  final bool isGenerating;
  final bool isPlayingVoice;

  AIMessageModel({
    required this.id,
    required this.text,
    required this.sender,
    DateTime? timestamp,
    this.properties,
    this.matchingDemands,
    this.rawDemands,
    this.demandDraft,
    this.propertyDraft,
    this.adminStats,
    this.quickActions,
    this.isGenerating = false,
    this.isPlayingVoice = false,
  }) : timestamp = timestamp ?? DateTime.now();

  AIMessageModel copyWith({
    String? id,
    String? text,
    AIMessageSender? sender,
    DateTime? timestamp,
    List<PropertyModel>? properties,
    List<MatchingDemandItem>? matchingDemands,
    List<TenantDemandModel>? rawDemands,
    DemandDraftModel? demandDraft,
    PropertyDraftModel? propertyDraft,
    AdminStatsModel? adminStats,
    List<String>? quickActions,
    bool? isGenerating,
    bool? isPlayingVoice,
  }) {
    return AIMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      properties: properties ?? this.properties,
      matchingDemands: matchingDemands ?? this.matchingDemands,
      rawDemands: rawDemands ?? this.rawDemands,
      demandDraft: demandDraft ?? this.demandDraft,
      propertyDraft: propertyDraft ?? this.propertyDraft,
      adminStats: adminStats ?? this.adminStats,
      quickActions: quickActions ?? this.quickActions,
      isGenerating: isGenerating ?? this.isGenerating,
      isPlayingVoice: isPlayingVoice ?? this.isPlayingVoice,
    );
  }
}
