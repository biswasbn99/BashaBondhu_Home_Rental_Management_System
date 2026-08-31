import '../../../../features/home/data/models/property_model.dart';
import '../../../../features/tenant/data/models/tenant_demand_model.dart';

enum AIMessageSender { user, ai, system }

enum AIActionCardType {
  none,
  demandDraft,
  propertyDraft,
  subscriptionHistory,
  subscriptionPackages,
  myProfile,
  adminStats,
}

/// Draft for conversational Tenant Demand creation (17 steps)
class DemandDraftModel {
  final String? month;
  final String? houseType;
  final String? division;
  final String? district;
  final String? area;
  final String? subArea;
  final String? budgetRange;
  final String? tenantType;
  final String? roomOrSeat;
  final int? bathrooms;
  final int? balconies;
  final int? floorNumber;
  final bool? hasLift;
  final bool? hasParking;
  final bool? hasGivenNotice;
  final String? userName;
  final String? userMobile;
  final String? userWhatsApp;

  const DemandDraftModel({
    this.month,
    this.houseType,
    this.division,
    this.district,
    this.area,
    this.subArea,
    this.budgetRange,
    this.tenantType,
    this.roomOrSeat,
    this.bathrooms,
    this.balconies,
    this.floorNumber,
    this.hasLift,
    this.hasParking,
    this.hasGivenNotice,
    this.userName,
    this.userMobile,
    this.userWhatsApp,
  });

  bool get isComplete =>
      area != null &&
      budgetRange != null &&
      roomOrSeat != null &&
      userMobile != null &&
      userMobile!.isNotEmpty;

  DemandDraftModel copyWith({
    String? month,
    String? houseType,
    String? division,
    String? district,
    String? area,
    String? subArea,
    String? budgetRange,
    String? tenantType,
    String? roomOrSeat,
    int? bathrooms,
    int? balconies,
    int? floorNumber,
    bool? hasLift,
    bool? hasParking,
    bool? hasGivenNotice,
    String? userName,
    String? userMobile,
    String? userWhatsApp,
  }) {
    return DemandDraftModel(
      month: month ?? this.month,
      houseType: houseType ?? this.houseType,
      division: division ?? this.division,
      district: district ?? this.district,
      area: area ?? this.area,
      subArea: subArea ?? this.subArea,
      budgetRange: budgetRange ?? this.budgetRange,
      tenantType: tenantType ?? this.tenantType,
      roomOrSeat: roomOrSeat ?? this.roomOrSeat,
      bathrooms: bathrooms ?? this.bathrooms,
      balconies: balconies ?? this.balconies,
      floorNumber: floorNumber ?? this.floorNumber,
      hasLift: hasLift ?? this.hasLift,
      hasParking: hasParking ?? this.hasParking,
      hasGivenNotice: hasGivenNotice ?? this.hasGivenNotice,
      userName: userName ?? this.userName,
      userMobile: userMobile ?? this.userMobile,
      userWhatsApp: userWhatsApp ?? this.userWhatsApp,
    );
  }
}

/// Draft for conversational Search / Filter state
class SearchDraftModel {
  final String? month;
  final String? houseType;
  final String? division;
  final String? district;
  final String? area;
  final String? subArea;
  final String? budgetRange;
  final String? tenantType;
  final String? roomOrSeat;
  final int? bathrooms;
  final int? balconies;
  final int? floorNumber;
  final bool? hasLift;
  final bool? hasParking;

  const SearchDraftModel({
    this.month,
    this.houseType,
    this.division,
    this.district,
    this.area,
    this.subArea,
    this.budgetRange,
    this.tenantType,
    this.roomOrSeat,
    this.bathrooms,
    this.balconies,
    this.floorNumber,
    this.hasLift,
    this.hasParking,
  });

  SearchDraftModel copyWith({
    String? month,
    String? houseType,
    String? division,
    String? district,
    String? area,
    String? subArea,
    String? budgetRange,
    String? tenantType,
    String? roomOrSeat,
    int? bathrooms,
    int? balconies,
    int? floorNumber,
    bool? hasLift,
    bool? hasParking,
  }) {
    return SearchDraftModel(
      month: month ?? this.month,
      houseType: houseType ?? this.houseType,
      division: division ?? this.division,
      district: district ?? this.district,
      area: area ?? this.area,
      subArea: subArea ?? this.subArea,
      budgetRange: budgetRange ?? this.budgetRange,
      tenantType: tenantType ?? this.tenantType,
      roomOrSeat: roomOrSeat ?? this.roomOrSeat,
      bathrooms: bathrooms ?? this.bathrooms,
      balconies: balconies ?? this.balconies,
      floorNumber: floorNumber ?? this.floorNumber,
      hasLift: hasLift ?? this.hasLift,
      hasParking: hasParking ?? this.hasParking,
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

/// Complete AI chat message model with interactive chips and action cards
class AIMessageModel {
  final String id;
  final String text;
  final AIMessageSender sender;
  final DateTime timestamp;
  final List<String>? interactiveChips; // 1-tap selectable options inside bubble
  final AIActionCardType actionCardType;
  final List<PropertyModel>? properties;
  final List<MatchingDemandItem>? matchingDemands;
  final List<TenantDemandModel>? rawDemands;
  final DemandDraftModel? demandDraft;
  final SearchDraftModel? searchDraft;
  final AdminStatsModel? adminStats;
  final List<String>? quickActions; // bottom bar quick prompts
  final bool isGenerating;
  final bool isPlayingVoice;

  AIMessageModel({
    required this.id,
    required this.text,
    required this.sender,
    DateTime? timestamp,
    this.interactiveChips,
    this.actionCardType = AIActionCardType.none,
    this.properties,
    this.matchingDemands,
    this.rawDemands,
    this.demandDraft,
    this.searchDraft,
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
    List<String>? interactiveChips,
    AIActionCardType? actionCardType,
    List<PropertyModel>? properties,
    List<MatchingDemandItem>? matchingDemands,
    List<TenantDemandModel>? rawDemands,
    DemandDraftModel? demandDraft,
    SearchDraftModel? searchDraft,
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
      interactiveChips: interactiveChips ?? this.interactiveChips,
      actionCardType: actionCardType ?? this.actionCardType,
      properties: properties ?? this.properties,
      matchingDemands: matchingDemands ?? this.matchingDemands,
      rawDemands: rawDemands ?? this.rawDemands,
      demandDraft: demandDraft ?? this.demandDraft,
      searchDraft: searchDraft ?? this.searchDraft,
      adminStats: adminStats ?? this.adminStats,
      quickActions: quickActions ?? this.quickActions,
      isGenerating: isGenerating ?? this.isGenerating,
      isPlayingVoice: isPlayingVoice ?? this.isPlayingVoice,
    );
  }
}
