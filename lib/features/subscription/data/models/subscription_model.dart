import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTargetRole {
  tenant,
  houseOwner,
}

class SubscriptionPlanModel {
  final String id;
  final String titleEn;
  final String titleBn;
  final String descriptionEn;
  final String descriptionBn;
  final double regularPrice;
  final double? offerPrice;
  final String offerBadgeTextEn;
  final String offerBadgeTextBn;
  final bool hasActiveOffer;
  final int durationDays;
  final int durationValue;
  final String durationUnit; // 'day', 'month', 'year'
  final String durationEn;
  final String durationBn;
  final SubscriptionTargetRole targetRole;
  final List<String> perksEn;
  final List<String> perksBn;
  final bool isPopular;
  final bool isUnlimited;
  final int displayOrder;

  // Structured Quota & Facilities
  // Values: 0 = Disabled/OFF, -1 = Unlimited, >0 = Exact Numeric Limit
  final int maxPostsLimit;
  final int unlockNumbersLimit;
  final int subAreaUnlockLimit;
  final int fullPhotoGalleryLimit;
  final bool canAccessAdditionalPhotos; // backward compatibility
  final int nearbySearchLimit;
  final int mapDirectionsLimit;
  final int aiAssistantLimit;

  const SubscriptionPlanModel({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.descriptionEn,
    required this.descriptionBn,
    required this.regularPrice,
    this.offerPrice,
    this.offerBadgeTextEn = '',
    this.offerBadgeTextBn = '',
    this.hasActiveOffer = false,
    required this.durationDays,
    this.durationValue = 0,
    this.durationUnit = 'day',
    this.durationEn = '',
    this.durationBn = '',
    required this.targetRole,
    required this.perksEn,
    required this.perksBn,
    this.isPopular = false,
    this.isUnlimited = false,
    this.displayOrder = 0,
    this.maxPostsLimit = 5,
    this.unlockNumbersLimit = -1,
    this.subAreaUnlockLimit = -1,
    this.fullPhotoGalleryLimit = -1,
    this.canAccessAdditionalPhotos = true,
    this.nearbySearchLimit = 10,
    this.mapDirectionsLimit = 10,
    this.aiAssistantLimit = -1,
  });

  double get effectivePrice => (hasActiveOffer && offerPrice != null) ? offerPrice! : regularPrice;

  bool get isMaxPostsEnabled => maxPostsLimit != 0;
  bool get isUnlockNumbersEnabled => unlockNumbersLimit != 0;
  bool get isSubAreaUnlockEnabled => subAreaUnlockLimit != 0;
  bool get isFullPhotoGalleryEnabled => fullPhotoGalleryLimit != 0;
  bool get isNearbySearchEnabled => nearbySearchLimit != 0;
  bool get isMapDirectionsEnabled => mapDirectionsLimit != 0;
  bool get isAiAssistantEnabled => aiAssistantLimit != 0;

  /// Helper to automatically generate Bengali and English perks based on enabled facilities
  static Map<String, List<String>> generateBilingualPerks({
    required SubscriptionTargetRole targetRole,
    required int maxPostsLimit,
    required int unlockNumbersLimit,
    required int subAreaUnlockLimit,
    required int fullPhotoGalleryLimit,
    required int nearbySearchLimit,
    required int mapDirectionsLimit,
    required int aiAssistantLimit,
  }) {
    final List<String> bnPerks = [];
    final List<String> enPerks = [];

    if (targetRole == SubscriptionTargetRole.tenant) {
      // 1. Max Demands
      if (maxPostsLimit == -1) {
        bnPerks.add('আনলিমিটেড ভাড়ার চাহিদা (Demand) পোস্ট');
        enPerks.add('Unlimited rental demands posting');
      } else if (maxPostsLimit > 0) {
        bnPerks.add('$maxPostsLimitটি ভাড়ার চাহিদা (Demand) পোস্ট');
        enPerks.add('Post up to $maxPostsLimit rental demands');
      }

      // 2. Unlock Numbers
      if (unlockNumbersLimit == -1) {
        bnPerks.add('বাড়িওয়ালার আনলিমিটেড কন্টাক্ট নম্বর আনলক');
        enPerks.add('Unlock unlimited landlord contact numbers');
      } else if (unlockNumbersLimit > 0) {
        bnPerks.add('$unlockNumbersLimitটি বাড়িওয়ালার নম্বর আনলক');
        enPerks.add('Unlock up to $unlockNumbersLimit landlord contacts');
      }

      // 3. Sub-area Access
      if (subAreaUnlockLimit == -1) {
        bnPerks.add('সকল বাসার সাব-এরিয়া লোকেশন উন্মুক্ত');
        enPerks.add('Unlimited sub-area location access');
      } else if (subAreaUnlockLimit > 0) {
        bnPerks.add('$subAreaUnlockLimitটি বাসার সাব-এরিয়া লোকেশন আনলক');
        enPerks.add('Unlock up to $subAreaUnlockLimit sub-area locations');
      }

      // 4. Photo Gallery
      if (fullPhotoGalleryLimit == -1) {
        bnPerks.add('সকল অতিরিক্ত ছবি ও ফুল ফটো গ্যালারি এক্সেস');
        enPerks.add('Full photo gallery access for all properties');
      } else if (fullPhotoGalleryLimit > 0) {
        bnPerks.add('$fullPhotoGalleryLimitটি বাসার সম্পূর্ণ ফটো গ্যালারি এক্সেস');
        enPerks.add('Full photo gallery access for $fullPhotoGalleryLimit homes');
      }

      // 5. Nearby Search
      if (nearbySearchLimit == -1) {
        bnPerks.add('আনলিমিটেড কাছাকাছি (রেডিয়াস) সার্চ');
        enPerks.add('Unlimited nearby & radius search');
      } else if (nearbySearchLimit > 0) {
        bnPerks.add('$nearbySearchLimitটি কাছাকাছি (রেডিয়াস) সার্চ');
        enPerks.add('Up to $nearbySearchLimit nearby radius searches');
      }

      // 6. Map Directions
      if (mapDirectionsLimit == -1) {
        bnPerks.add('আনলিমিটেড গুগল ম্যাপস দিকনির্দেশনা ও নেভিগেশন');
        enPerks.add('Unlimited Google Maps navigation & directions');
      } else if (mapDirectionsLimit > 0) {
        bnPerks.add('$mapDirectionsLimitটি গুগল ম্যাপস দিকনির্দেশনা');
        enPerks.add('Up to $mapDirectionsLimit Google Maps directions');
      }

      // 7. AI Assistant
      if (aiAssistantLimit == -1) {
        bnPerks.add('আনলিমিটেড এআই সহকারী (AI Assistant) সার্চ');
        enPerks.add('Unlimited AI Assistant rental queries');
      } else if (aiAssistantLimit > 0) {
        bnPerks.add('$aiAssistantLimitটি এআই সহকারী সার্চ');
        enPerks.add('Up to $aiAssistantLimit AI Assistant queries');
      }
    } else {
      // House Owner Facilities
      // 1. Max Listings
      if (maxPostsLimit == -1) {
        bnPerks.add('আনলিমিটেড বাসাভাড়া বিজ্ঞাপন পোস্ট');
        enPerks.add('Publish unlimited rental listings');
      } else if (maxPostsLimit > 0) {
        bnPerks.add('$maxPostsLimitটি বাসাভাড়া বিজ্ঞাপন পোস্ট');
        enPerks.add('Publish up to $maxPostsLimit rental listings');
      }

      // 2. Tenant Numbers Unlock
      if (unlockNumbersLimit == -1) {
        bnPerks.add('ভাড়াটিয়াদের আনলিমিটেড ফোন নম্বর আনলক');
        enPerks.add('Unlock unlimited tenant contact numbers');
      } else if (unlockNumbersLimit > 0) {
        bnPerks.add('$unlockNumbersLimitটি ভাড়াটিয়ার নম্বর আনলক');
        enPerks.add('Unlock up to $unlockNumbersLimit tenant contacts');
      }

      // 3. Sub-area Unlock
      if (subAreaUnlockLimit == -1) {
        bnPerks.add('ভাড়াটিয়াদের চাহিদার সকল সাব-এরিয়া উন্মুক্ত');
        enPerks.add('Full access to tenant demand sub-areas');
      } else if (subAreaUnlockLimit > 0) {
        bnPerks.add('$subAreaUnlockLimitটি চাহিদার সাব-এরিয়া লোকেশন আনলক');
        enPerks.add('Unlock up to $subAreaUnlockLimit demand sub-areas');
      }

      // 4. AI Assistant
      if (aiAssistantLimit == -1) {
        bnPerks.add('আনলিমিটেড এআই সহকারী (AI Assistant) সার্চ');
        enPerks.add('Unlimited AI Assistant property queries');
      } else if (aiAssistantLimit > 0) {
        bnPerks.add('$aiAssistantLimitটি এআই সহকারী সার্চ');
        enPerks.add('Up to $aiAssistantLimit AI Assistant queries');
      }
    }

    return {
      'bn': bnPerks,
      'en': enPerks,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titleEn': titleEn,
      'titleBn': titleBn,
      'descriptionEn': descriptionEn,
      'descriptionBn': descriptionBn,
      'regularPrice': regularPrice,
      'offerPrice': offerPrice,
      'offerBadgeTextEn': offerBadgeTextEn,
      'offerBadgeTextBn': offerBadgeTextBn,
      'hasActiveOffer': hasActiveOffer,
      'durationDays': durationDays,
      'durationValue': durationValue > 0 ? durationValue : durationDays,
      'durationUnit': durationUnit,
      'durationEn': durationEn.isNotEmpty ? durationEn : '$durationDays Days',
      'durationBn': durationBn.isNotEmpty ? durationBn : '$durationDays দিন',
      'targetRole': targetRole == SubscriptionTargetRole.tenant ? 'tenant' : 'houseOwner',
      'perksEn': perksEn,
      'perksBn': perksBn,
      'isPopular': isPopular,
      'isUnlimited': isUnlimited,
      'displayOrder': displayOrder,
      'maxPostsLimit': maxPostsLimit,
      'unlockNumbersLimit': unlockNumbersLimit,
      'subAreaUnlockLimit': subAreaUnlockLimit,
      'fullPhotoGalleryLimit': fullPhotoGalleryLimit,
      'canAccessAdditionalPhotos': canAccessAdditionalPhotos,
      'nearbySearchLimit': nearbySearchLimit,
      'mapDirectionsLimit': mapDirectionsLimit,
      'aiAssistantLimit': aiAssistantLimit,
    };
  }

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map, String docId) {
    final days = (map['durationDays'] as num?)?.toInt() ?? 30;
    final val = (map['durationValue'] as num?)?.toInt() ?? days;
    final unit = map['durationUnit'] as String? ?? 'day';
    final photoAccess = map['canAccessAdditionalPhotos'] ?? true;
    final galleryLimit = (map['fullPhotoGalleryLimit'] as num?)?.toInt() ?? (photoAccess ? -1 : 0);

    return SubscriptionPlanModel(
      id: docId,
      titleEn: map['titleEn'] ?? '',
      titleBn: map['titleBn'] ?? '',
      descriptionEn: map['descriptionEn'] ?? '',
      descriptionBn: map['descriptionBn'] ?? '',
      regularPrice: (map['regularPrice'] as num?)?.toDouble() ?? 0.0,
      offerPrice: (map['offerPrice'] as num?)?.toDouble(),
      offerBadgeTextEn: map['offerBadgeTextEn'] ?? '',
      offerBadgeTextBn: map['offerBadgeTextBn'] ?? '',
      hasActiveOffer: map['hasActiveOffer'] ?? false,
      durationDays: days,
      durationValue: val,
      durationUnit: unit,
      durationEn: map['durationEn'] ?? '$days Days',
      durationBn: map['durationBn'] ?? '$days দিন',
      targetRole: (map['targetRole']?.toString().toLowerCase().contains('tenant') ?? false)
          ? SubscriptionTargetRole.tenant
          : SubscriptionTargetRole.houseOwner,
      perksEn: List<String>.from(map['perksEn'] ?? []),
      perksBn: List<String>.from(map['perksBn'] ?? []),
      isPopular: map['isPopular'] ?? false,
      isUnlimited: map['isUnlimited'] ?? false,
      displayOrder: (map['displayOrder'] as num?)?.toInt() ?? 0,
      maxPostsLimit: (map['maxPostsLimit'] as num?)?.toInt() ?? 5,
      unlockNumbersLimit: (map['unlockNumbersLimit'] as num?)?.toInt() ?? -1,
      subAreaUnlockLimit: (map['subAreaUnlockLimit'] as num?)?.toInt() ?? -1,
      fullPhotoGalleryLimit: galleryLimit,
      canAccessAdditionalPhotos: galleryLimit != 0,
      nearbySearchLimit: (map['nearbySearchLimit'] as num?)?.toInt() ?? 10,
      mapDirectionsLimit: (map['mapDirectionsLimit'] as num?)?.toInt() ?? 10,
      aiAssistantLimit: (map['aiAssistantLimit'] as num?)?.toInt() ?? -1,
    );
  }

  SubscriptionPlanModel copyWith({
    String? id,
    String? titleEn,
    String? titleBn,
    String? descriptionEn,
    String? descriptionBn,
    double? regularPrice,
    double? offerPrice,
    String? offerBadgeTextEn,
    String? offerBadgeTextBn,
    bool? hasActiveOffer,
    int? durationDays,
    int? durationValue,
    String? durationUnit,
    String? durationEn,
    String? durationBn,
    SubscriptionTargetRole? targetRole,
    List<String>? perksEn,
    List<String>? perksBn,
    bool? isPopular,
    bool? isUnlimited,
    int? displayOrder,
    int? maxPostsLimit,
    int? unlockNumbersLimit,
    int? subAreaUnlockLimit,
    int? fullPhotoGalleryLimit,
    bool? canAccessAdditionalPhotos,
    int? nearbySearchLimit,
    int? mapDirectionsLimit,
    int? aiAssistantLimit,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleBn: titleBn ?? this.titleBn,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionBn: descriptionBn ?? this.descriptionBn,
      regularPrice: regularPrice ?? this.regularPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      offerBadgeTextEn: offerBadgeTextEn ?? this.offerBadgeTextEn,
      offerBadgeTextBn: offerBadgeTextBn ?? this.offerBadgeTextBn,
      hasActiveOffer: hasActiveOffer ?? this.hasActiveOffer,
      durationDays: durationDays ?? this.durationDays,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
      durationEn: durationEn ?? this.durationEn,
      durationBn: durationBn ?? this.durationBn,
      targetRole: targetRole ?? this.targetRole,
      perksEn: perksEn ?? this.perksEn,
      perksBn: perksBn ?? this.perksBn,
      isPopular: isPopular ?? this.isPopular,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      displayOrder: displayOrder ?? this.displayOrder,
      maxPostsLimit: maxPostsLimit ?? this.maxPostsLimit,
      unlockNumbersLimit: unlockNumbersLimit ?? this.unlockNumbersLimit,
      subAreaUnlockLimit: subAreaUnlockLimit ?? this.subAreaUnlockLimit,
      fullPhotoGalleryLimit: fullPhotoGalleryLimit ?? this.fullPhotoGalleryLimit,
      canAccessAdditionalPhotos: canAccessAdditionalPhotos ?? this.canAccessAdditionalPhotos,
      nearbySearchLimit: nearbySearchLimit ?? this.nearbySearchLimit,
      mapDirectionsLimit: mapDirectionsLimit ?? this.mapDirectionsLimit,
      aiAssistantLimit: aiAssistantLimit ?? this.aiAssistantLimit,
    );
  }
}

/// Snapshot of an individual active subscription plan on the user account (Plan 1, Plan 2, etc.)
class UserSubscriptionPlan {
  final String id;
  final String planId;
  final String titleBn;
  final String titleEn;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final double amountPaid;
  final int durationDays;

  // Quotas & Usage for this specific plan
  final int maxPostsLimit;
  final int postsUsed;
  final int unlockNumbersLimit;
  final int unlocksUsed;
  final int subAreaUnlockLimit;
  final int subAreaUnlocksUsed;
  final int fullPhotoGalleryLimit;
  final int photoGalleryUsed;
  final int nearbySearchLimit;
  final int nearbySearchUsed;
  final int mapDirectionsLimit;
  final int mapDirectionsUsed;
  final int aiAssistantLimit;
  final int aiAssistantUsed;

  const UserSubscriptionPlan({
    required this.id,
    required this.planId,
    required this.titleBn,
    required this.titleEn,
    required this.purchasedAt,
    required this.expiresAt,
    required this.amountPaid,
    required this.durationDays,
    this.maxPostsLimit = 5,
    this.postsUsed = 0,
    this.unlockNumbersLimit = -1,
    this.unlocksUsed = 0,
    this.subAreaUnlockLimit = -1,
    this.subAreaUnlocksUsed = 0,
    this.fullPhotoGalleryLimit = -1,
    this.photoGalleryUsed = 0,
    this.nearbySearchLimit = 10,
    this.nearbySearchUsed = 0,
    this.mapDirectionsLimit = 10,
    this.mapDirectionsUsed = 0,
    this.aiAssistantLimit = -1,
    this.aiAssistantUsed = 0,
  });

  bool get isPlanActive => expiresAt.isAfter(DateTime.now());
  int get remainingDays => (expiresAt.difference(DateTime.now()).inHours / 24).ceil().clamp(0, 9999);

  bool get hasPostQuota => maxPostsLimit == -1 || (maxPostsLimit > 0 && postsUsed < maxPostsLimit);
  int get remainingPosts => maxPostsLimit == -1 ? 999 : (maxPostsLimit - postsUsed).clamp(0, maxPostsLimit);

  bool get hasUnlockQuota => unlockNumbersLimit == -1 || (unlockNumbersLimit > 0 && unlocksUsed < unlockNumbersLimit);
  int get remainingUnlocks => unlockNumbersLimit == -1 ? 999 : (unlockNumbersLimit - unlocksUsed).clamp(0, unlockNumbersLimit);

  bool get hasSubAreaQuota => subAreaUnlockLimit == -1 || (subAreaUnlockLimit > 0 && subAreaUnlocksUsed < subAreaUnlockLimit);
  int get remainingSubAreaUnlocks => subAreaUnlockLimit == -1 ? 999 : (subAreaUnlockLimit - subAreaUnlocksUsed).clamp(0, subAreaUnlockLimit);

  bool get hasPhotoGalleryAccess => fullPhotoGalleryLimit != 0;
  bool get hasPhotoGalleryQuota => fullPhotoGalleryLimit == -1 || (fullPhotoGalleryLimit > 0 && photoGalleryUsed < fullPhotoGalleryLimit);
  int get remainingPhotoGallery => fullPhotoGalleryLimit == -1 ? 999 : (fullPhotoGalleryLimit - photoGalleryUsed).clamp(0, fullPhotoGalleryLimit);

  String localizedTitle(bool isBn) {
    if (isBn) {
      if (titleBn.isNotEmpty) return titleBn;
      return _translateToBn(titleEn);
    } else {
      if (titleEn.isNotEmpty && !_hasBengali(titleEn)) return titleEn;
      return _translateToEn(titleBn.isNotEmpty ? titleBn : titleEn);
    }
  }

  static bool _hasBengali(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x0980 && rune <= 0x09FF) return true;
    }
    return false;
  }

  static String _translateToEn(String bn) {
    if (bn.isEmpty) return 'Active Plan';
    if (bn.contains('আরামদায়ক')) return '1-Day Comfortable Package';
    if (bn.contains('সক্রিয় প্যাকেজ')) return 'Active Package';
    if (bn.contains('১ দিন') || bn.contains('১-দিন')) return '1-Day Support Package';
    if (bn.contains('৩ দিন') || bn.contains('৩-দিন')) return '3-Day Special Package';
    if (bn.contains('৭ দিন') || bn.contains('৭-দিন')) return '7-Day Super Package';
    if (bn.contains('১৫ দিন') || bn.contains('১৫-দিন')) return '15-Day Professional Package';
    if (bn.contains('৩০ দিন') || bn.contains('৩০-দিন')) return '30-Day Unlimited Package';
    if (bn.contains('মাসিক')) return 'Monthly Premium Plan';
    if (bn.contains('বাৎসরিক')) return 'Annual VIP Plan';
    return 'Active Subscription Plan';
  }

  static String _translateToBn(String en) {
    if (en.isEmpty) return 'সক্রিয় প্ল্যান';
    final lower = en.toLowerCase();
    if (lower.contains('comfortable')) return '১ দিনের আরামদায়ক প্যাকেজ';
    if (lower.contains('active package')) return 'সক্রিয় প্যাকেজ';
    if (lower.contains('1-day') || lower.contains('1 day')) return '১ দিনের সাপোর্ট প্যাকেজ';
    if (lower.contains('3-day') || lower.contains('3 day')) return '৩ দিনের স্পেশাল প্যাকেজ';
    if (lower.contains('7-day') || lower.contains('7 day')) return '৭ দিনের সুপার প্যাকেজ';
    if (lower.contains('15-day') || lower.contains('15 day')) return '১৫ দিনের প্রফেশনাল প্যাকেজ';
    if (lower.contains('30-day') || lower.contains('30 day')) return '৩০ দিনের আনলিমিটেড প্যাকেজ';
    if (lower.contains('monthly')) return 'মাসিক প্রিমিয়াম প্ল্যান';
    if (lower.contains('annual')) return 'বাৎসরিক ভিআইপি প্ল্যান';
    return 'সক্রিয় সাবস্ক্রিপশন প্ল্যান';
  }

  bool get hasNearbyQuota => nearbySearchLimit == -1 || (nearbySearchLimit > 0 && nearbySearchUsed < nearbySearchLimit);
  int get remainingNearby => nearbySearchLimit == -1 ? 999 : (nearbySearchLimit - nearbySearchUsed).clamp(0, nearbySearchLimit);

  bool get hasMapDirectionsQuota => mapDirectionsLimit == -1 || (mapDirectionsLimit > 0 && mapDirectionsUsed < mapDirectionsLimit);
  int get remainingMapDirections => mapDirectionsLimit == -1 ? 999 : (mapDirectionsLimit - mapDirectionsUsed).clamp(0, mapDirectionsLimit);

  bool get hasAiQuota => aiAssistantLimit == -1 || (aiAssistantLimit > 0 && aiAssistantUsed < aiAssistantLimit);
  int get remainingAi => aiAssistantLimit == -1 ? 999 : (aiAssistantLimit - aiAssistantUsed).clamp(0, aiAssistantLimit);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'titleBn': titleBn,
      'titleEn': titleEn,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'amountPaid': amountPaid,
      'durationDays': durationDays,
      'maxPostsLimit': maxPostsLimit,
      'postsUsed': postsUsed,
      'unlockNumbersLimit': unlockNumbersLimit,
      'unlocksUsed': unlocksUsed,
      'subAreaUnlockLimit': subAreaUnlockLimit,
      'subAreaUnlocksUsed': subAreaUnlocksUsed,
      'fullPhotoGalleryLimit': fullPhotoGalleryLimit,
      'photoGalleryUsed': photoGalleryUsed,
      'nearbySearchLimit': nearbySearchLimit,
      'nearbySearchUsed': nearbySearchUsed,
      'mapDirectionsLimit': mapDirectionsLimit,
      'mapDirectionsUsed': mapDirectionsUsed,
      'aiAssistantLimit': aiAssistantLimit,
      'aiAssistantUsed': aiAssistantUsed,
    };
  }

  factory UserSubscriptionPlan.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return UserSubscriptionPlan(
      id: map['id'] ?? '',
      planId: map['planId'] ?? '',
      titleBn: map['titleBn'] ?? '',
      titleEn: map['titleEn'] ?? '',
      purchasedAt: parseDate(map['purchasedAt']),
      expiresAt: parseDate(map['expiresAt']),
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 30,
      maxPostsLimit: (map['maxPostsLimit'] as num?)?.toInt() ?? 5,
      postsUsed: (map['postsUsed'] as num?)?.toInt() ?? 0,
      unlockNumbersLimit: (map['unlockNumbersLimit'] as num?)?.toInt() ?? -1,
      unlocksUsed: (map['unlocksUsed'] as num?)?.toInt() ?? 0,
      subAreaUnlockLimit: (map['subAreaUnlockLimit'] as num?)?.toInt() ?? -1,
      subAreaUnlocksUsed: (map['subAreaUnlocksUsed'] as num?)?.toInt() ?? 0,
      fullPhotoGalleryLimit: (map['fullPhotoGalleryLimit'] as num?)?.toInt() ?? -1,
      photoGalleryUsed: (map['photoGalleryUsed'] as num?)?.toInt() ?? 0,
      nearbySearchLimit: (map['nearbySearchLimit'] as num?)?.toInt() ?? 10,
      nearbySearchUsed: (map['nearbySearchUsed'] as num?)?.toInt() ?? 0,
      mapDirectionsLimit: (map['mapDirectionsLimit'] as num?)?.toInt() ?? 10,
      mapDirectionsUsed: (map['mapDirectionsUsed'] as num?)?.toInt() ?? 0,
      aiAssistantLimit: (map['aiAssistantLimit'] as num?)?.toInt() ?? -1,
      aiAssistantUsed: (map['aiAssistantUsed'] as num?)?.toInt() ?? 0,
    );
  }

  UserSubscriptionPlan copyWith({
    String? id,
    String? planId,
    String? titleBn,
    String? titleEn,
    DateTime? purchasedAt,
    DateTime? expiresAt,
    double? amountPaid,
    int? durationDays,
    int? maxPostsLimit,
    int? postsUsed,
    int? unlockNumbersLimit,
    int? unlocksUsed,
    int? subAreaUnlockLimit,
    int? subAreaUnlocksUsed,
    int? fullPhotoGalleryLimit,
    int? photoGalleryUsed,
    int? nearbySearchLimit,
    int? nearbySearchUsed,
    int? mapDirectionsLimit,
    int? mapDirectionsUsed,
    int? aiAssistantLimit,
    int? aiAssistantUsed,
  }) {
    return UserSubscriptionPlan(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      titleBn: titleBn ?? this.titleBn,
      titleEn: titleEn ?? this.titleEn,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      amountPaid: amountPaid ?? this.amountPaid,
      durationDays: durationDays ?? this.durationDays,
      maxPostsLimit: maxPostsLimit ?? this.maxPostsLimit,
      postsUsed: postsUsed ?? this.postsUsed,
      unlockNumbersLimit: unlockNumbersLimit ?? this.unlockNumbersLimit,
      unlocksUsed: unlocksUsed ?? this.unlocksUsed,
      subAreaUnlockLimit: subAreaUnlockLimit ?? this.subAreaUnlockLimit,
      subAreaUnlocksUsed: subAreaUnlocksUsed ?? this.subAreaUnlocksUsed,
      fullPhotoGalleryLimit: fullPhotoGalleryLimit ?? this.fullPhotoGalleryLimit,
      photoGalleryUsed: photoGalleryUsed ?? this.photoGalleryUsed,
      nearbySearchLimit: nearbySearchLimit ?? this.nearbySearchLimit,
      nearbySearchUsed: nearbySearchUsed ?? this.nearbySearchUsed,
      mapDirectionsLimit: mapDirectionsLimit ?? this.mapDirectionsLimit,
      mapDirectionsUsed: mapDirectionsUsed ?? this.mapDirectionsUsed,
      aiAssistantLimit: aiAssistantLimit ?? this.aiAssistantLimit,
      aiAssistantUsed: aiAssistantUsed ?? this.aiAssistantUsed,
    );
  }
}

class SubscriptionTransactionModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userMobile;
  final String planId;
  final String planTitle;
  final double amountPaid;
  final String paymentMethod; // e.g. bKash
  final String transactionId; // bKash TrxID
  final String senderPhone;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final String status; // active, expired, refunded

  const SubscriptionTransactionModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userMobile,
    required this.planId,
    required this.planTitle,
    required this.amountPaid,
    this.paymentMethod = 'bKash',
    required this.transactionId,
    required this.senderPhone,
    required this.purchasedAt,
    required this.expiresAt,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userMobile': userMobile,
      'planId': planId,
      'planTitle': planTitle,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'senderPhone': senderPhone,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
    };
  }

  factory SubscriptionTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return SubscriptionTransactionModel(
      id: docId,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userMobile: map['userMobile'] ?? '',
      planId: map['planId'] ?? '',
      planTitle: map['planTitle'] ?? '',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'bKash',
      transactionId: map['transactionId'] ?? '',
      senderPhone: map['senderPhone'] ?? '',
      purchasedAt: (map['purchasedAt'] is Timestamp)
          ? (map['purchasedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: (map['expiresAt'] is Timestamp)
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      status: map['status'] ?? 'active',
    );
  }
}
