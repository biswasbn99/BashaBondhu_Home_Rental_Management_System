/// Model representing Admin-Configurable Free Tier Policy
/// for both Tenant and House Owner users.
class FreeTierPolicyModel {
  // Tenant Free Quotas (7 Facilities)
  // 0 = Disabled/OFF, -1 = Unlimited, >0 = Limit Count
  final int tenantMaxDemands;
  final int tenantUnlockNumbers;
  final int tenantSubAreaUnlocks;
  final int tenantFullPhotoGallery;
  final int tenantNearbySearches;
  final int tenantMapDirections;
  final int tenantAiAssistant;

  // House Owner Free Quotas (4 Facilities)
  final int ownerMaxListings;
  final int ownerUnlockNumbers;
  final int ownerSubAreaUnlocks;
  final int ownerAiAssistant;

  const FreeTierPolicyModel({
    this.tenantMaxDemands = 1,
    this.tenantUnlockNumbers = 5,
    this.tenantSubAreaUnlocks = 0,
    this.tenantFullPhotoGallery = 0,
    this.tenantNearbySearches = 3,
    this.tenantMapDirections = 2,
    this.tenantAiAssistant = 2,
    this.ownerMaxListings = 1,
    this.ownerUnlockNumbers = 2,
    this.ownerSubAreaUnlocks = 0,
    this.ownerAiAssistant = 2,
  });

  factory FreeTierPolicyModel.defaultPolicy() {
    return const FreeTierPolicyModel();
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantMaxDemands': tenantMaxDemands,
      'tenantUnlockNumbers': tenantUnlockNumbers,
      'tenantSubAreaUnlocks': tenantSubAreaUnlocks,
      'tenantFullPhotoGallery': tenantFullPhotoGallery,
      'tenantNearbySearches': tenantNearbySearches,
      'tenantMapDirections': tenantMapDirections,
      'tenantAiAssistant': tenantAiAssistant,
      'ownerMaxListings': ownerMaxListings,
      'ownerUnlockNumbers': ownerUnlockNumbers,
      'ownerSubAreaUnlocks': ownerSubAreaUnlocks,
      'ownerAiAssistant': ownerAiAssistant,
    };
  }

  factory FreeTierPolicyModel.fromMap(Map<String, dynamic> map) {
    return FreeTierPolicyModel(
      tenantMaxDemands: (map['tenantMaxDemands'] as num?)?.toInt() ?? 1,
      tenantUnlockNumbers: (map['tenantUnlockNumbers'] as num?)?.toInt() ?? 5,
      tenantSubAreaUnlocks: (map['tenantSubAreaUnlocks'] as num?)?.toInt() ?? 0,
      tenantFullPhotoGallery: (map['tenantFullPhotoGallery'] as num?)?.toInt() ?? 0,
      tenantNearbySearches: (map['tenantNearbySearches'] as num?)?.toInt() ?? 3,
      tenantMapDirections: (map['tenantMapDirections'] as num?)?.toInt() ?? 2,
      tenantAiAssistant: (map['tenantAiAssistant'] as num?)?.toInt() ?? 2,
      ownerMaxListings: (map['ownerMaxListings'] as num?)?.toInt() ?? 1,
      ownerUnlockNumbers: (map['ownerUnlockNumbers'] as num?)?.toInt() ?? 2,
      ownerSubAreaUnlocks: (map['ownerSubAreaUnlocks'] as num?)?.toInt() ?? 0,
      ownerAiAssistant: (map['ownerAiAssistant'] as num?)?.toInt() ?? 2,
    );
  }

  FreeTierPolicyModel copyWith({
    int? tenantMaxDemands,
    int? tenantUnlockNumbers,
    int? tenantSubAreaUnlocks,
    int? tenantFullPhotoGallery,
    int? tenantNearbySearches,
    int? tenantMapDirections,
    int? tenantAiAssistant,
    int? ownerMaxListings,
    int? ownerUnlockNumbers,
    int? ownerSubAreaUnlocks,
    int? ownerAiAssistant,
  }) {
    return FreeTierPolicyModel(
      tenantMaxDemands: tenantMaxDemands ?? this.tenantMaxDemands,
      tenantUnlockNumbers: tenantUnlockNumbers ?? this.tenantUnlockNumbers,
      tenantSubAreaUnlocks: tenantSubAreaUnlocks ?? this.tenantSubAreaUnlocks,
      tenantFullPhotoGallery: tenantFullPhotoGallery ?? this.tenantFullPhotoGallery,
      tenantNearbySearches: tenantNearbySearches ?? this.tenantNearbySearches,
      tenantMapDirections: tenantMapDirections ?? this.tenantMapDirections,
      tenantAiAssistant: tenantAiAssistant ?? this.tenantAiAssistant,
      ownerMaxListings: ownerMaxListings ?? this.ownerMaxListings,
      ownerUnlockNumbers: ownerUnlockNumbers ?? this.ownerUnlockNumbers,
      ownerSubAreaUnlocks: ownerSubAreaUnlocks ?? this.ownerSubAreaUnlocks,
      ownerAiAssistant: ownerAiAssistant ?? this.ownerAiAssistant,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreeTierPolicyModel &&
          runtimeType == other.runtimeType &&
          tenantMaxDemands == other.tenantMaxDemands &&
          tenantUnlockNumbers == other.tenantUnlockNumbers &&
          tenantSubAreaUnlocks == other.tenantSubAreaUnlocks &&
          tenantFullPhotoGallery == other.tenantFullPhotoGallery &&
          tenantNearbySearches == other.tenantNearbySearches &&
          tenantMapDirections == other.tenantMapDirections &&
          tenantAiAssistant == other.tenantAiAssistant &&
          ownerMaxListings == other.ownerMaxListings &&
          ownerUnlockNumbers == other.ownerUnlockNumbers &&
          ownerSubAreaUnlocks == other.ownerSubAreaUnlocks &&
          ownerAiAssistant == other.ownerAiAssistant;

  @override
  int get hashCode => Object.hash(
        tenantMaxDemands,
        tenantUnlockNumbers,
        tenantSubAreaUnlocks,
        tenantFullPhotoGallery,
        tenantNearbySearches,
        tenantMapDirections,
        tenantAiAssistant,
        ownerMaxListings,
        ownerUnlockNumbers,
        ownerSubAreaUnlocks,
        ownerAiAssistant,
      );
}

