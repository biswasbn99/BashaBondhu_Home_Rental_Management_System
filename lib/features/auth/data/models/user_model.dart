import '../../../subscription/data/models/free_tier_policy_model.dart';
import '../../../subscription/data/models/subscription_model.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String mobile;
  final String city;
  final String userType; // 'House Owner' or 'Tenant'
  final String profileImageUrl;
  final String gender;
  final String dateOfBirth;
  final String nidFrontImageUrl;
  final String nidBackImageUrl;
  final String createdAt;

  // Verification Fields
  final String verificationStatus; // 'verified', 'pending', 'unverified', 'rejected'
  final String verificationFeedback; // Feedback reason if rejected / correction needed

  // Block & Appeal Fields
  final bool isBlocked;
  final String blockReason;
  final String blockedAt;
  final String appealStatus; // 'none', 'pending', 'approved', 'rejected'
  final String appealNote;
  final String appealContact;
  final String appealAt;
  final String appealFeedback;

  // Subscription & Gating Fields
  final List<String> unlockedPropertyIds; // properties unlocked by tenant
  final List<String> unlockedDemandIds;   // demands unlocked by house owner
  final List<String> unlockedPropertySubAreaIds; // property sub-areas unlocked by tenant
  final List<String> unlockedDemandSubAreaIds;   // demand sub-areas unlocked by house owner
  final List<String> unlockedPhotoPropertyIds;   // properties whose full photo gallery is unlocked by tenant
  final int radiusSearchCount;            // radius search uses for free tier
  final String subscriptionPlanId;        // legacy plan id if active
  final String subscriptionExpiryDate;    // legacy ISO string

  // Dynamic Subscription Quota Tracking & Snapshots (Legacy single-plan support)
  final int subscriptionPostsCount;
  final int subscriptionUnlocksCount;
  final int subscriptionNearbySearchCount;
  final int subscriptionMapDirectionsCount;
  final int aiAssistantQueryCount;

  final int subscriptionMaxPosts;
  final int subscriptionMaxUnlocks;
  final bool subscriptionCanAccessPhotos;
  final int subscriptionMaxNearbySearches;
  final int subscriptionMaxMapDirections;
  final int subscriptionMaxAiQueries;

  // Multi-Plan Support (Plan 1, Plan 2, etc.)
  final List<UserSubscriptionPlan> activeSubscriptionPlans;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    required this.mobile,
    required this.city,
    required this.userType,
    this.profileImageUrl = '',
    this.gender = '',
    this.dateOfBirth = '',
    this.nidFrontImageUrl = '',
    this.nidBackImageUrl = '',
    String? createdAt,
    this.verificationStatus = 'unverified',
    this.verificationFeedback = '',
    this.isBlocked = false,
    this.blockReason = '',
    this.blockedAt = '',
    this.appealStatus = 'none',
    this.appealNote = '',
    this.appealContact = '',
    this.appealAt = '',
    this.appealFeedback = '',
    this.unlockedPropertyIds = const [],
    this.unlockedDemandIds = const [],
    this.unlockedPropertySubAreaIds = const [],
    this.unlockedDemandSubAreaIds = const [],
    this.unlockedPhotoPropertyIds = const [],
    this.radiusSearchCount = 0,
    this.subscriptionPlanId = '',
    this.subscriptionExpiryDate = '',
    this.subscriptionPostsCount = 0,
    this.subscriptionUnlocksCount = 0,
    this.subscriptionNearbySearchCount = 0,
    this.subscriptionMapDirectionsCount = 0,
    this.aiAssistantQueryCount = 0,
    this.subscriptionMaxPosts = 1,
    this.subscriptionMaxUnlocks = -1,
    this.subscriptionCanAccessPhotos = false,
    this.subscriptionMaxNearbySearches = 3,
    this.subscriptionMaxMapDirections = 2,
    this.subscriptionMaxAiQueries = 2,
    this.activeSubscriptionPlans = const [],
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  String get fullName {
    final parts = [firstName, if (middleName.trim().isNotEmpty) middleName, lastName]
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return parts.join(' ').trim();
  }

  String get initials {
    final f = firstName.trim().isNotEmpty ? firstName.trim()[0].toUpperCase() : '';
    final l = lastName.trim().isNotEmpty ? lastName.trim()[0].toUpperCase() : '';
    final res = '$f$l';
    if (res.isNotEmpty) return res;
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  /// Calculates profile completion percentage (0 - 100)
  int get profileCompletionPercentage {
    int score = 0;
    if (firstName.trim().isNotEmpty) score += 15;
    if (lastName.trim().isNotEmpty) score += 15;
    if (mobile.trim().isNotEmpty) score += 15;
    if (profileImageUrl.trim().isNotEmpty) score += 15;
    if (gender.trim().isNotEmpty) score += 10;
    if (dateOfBirth.trim().isNotEmpty) score += 10;
    if (nidFrontImageUrl.trim().isNotEmpty) score += 10;
    if (nidBackImageUrl.trim().isNotEmpty) score += 10;
    return score.clamp(0, 100);
  }

  /// Profile is complete only when 100% of fields are filled
  bool get isProfileComplete => profileCompletionPercentage >= 100;

  /// Check if user is an admin
  bool get isAdmin =>
      userType.toLowerCase().contains('admin') || email.toLowerCase().contains('admin');

  /// Check if user is a house owner
  bool get isHouseOwner =>
      !isAdmin &&
      userType.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').contains('owner');

  /// Check if user is a tenant
  bool get isTenant => !isAdmin && !isHouseOwner;

  /// Parsed legacy expiry date
  DateTime? get expiryDateTime {
    if (subscriptionExpiryDate.isEmpty) return null;
    try {
      return DateTime.parse(subscriptionExpiryDate);
    } catch (_) {
      return null;
    }
  }

  /// Filter active, unexpired subscription plans (Plan 1, Plan 2, etc.)
  List<UserSubscriptionPlan> get activePlans =>
      activeSubscriptionPlans.where((p) => p.isPlanActive).toList();

  /// Check if user has at least one active premium subscription
  bool get isSubscribed {
    if (activePlans.isNotEmpty) return true;
    final expiry = expiryDateTime;
    if (expiry == null) return false;
    return expiry.isAfter(DateTime.now());
  }

  /// Free property unlocks remaining (dynamically supports FreeTierPolicyModel)
  int freePropertyUnlocksRemainingForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      return remainingContactUnlocks;
    }
    final max = policy?.tenantUnlockNumbers ?? 5;
    if (max == -1) return 999;
    if (max <= 0) return 0;
    return (max - unlockedPropertyIds.length).clamp(0, max);
  }

  int get freePropertyUnlocksRemaining => freePropertyUnlocksRemainingForPolicy();

  /// Free demand unlocks remaining (dynamically supports FreeTierPolicyModel)
  int freeDemandUnlocksRemainingForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      return remainingContactUnlocks;
    }
    final max = policy?.ownerUnlockNumbers ?? 2;
    if (max == -1) return 999;
    if (max <= 0) return 0;
    return (max - unlockedDemandIds.length).clamp(0, max);
  }

  int get freeDemandUnlocksRemaining => freeDemandUnlocksRemainingForPolicy();

  /// Verification getters
  bool get isVerified => verificationStatus.toLowerCase() == 'verified';
  bool get isVerificationPending => verificationStatus.toLowerCase() == 'pending';
  bool get isVerificationRejected => verificationStatus.toLowerCase() == 'rejected';

  /// Free radius searches remaining (dynamically supports FreeTierPolicyModel)
  int freeRadiusSearchesRemainingForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      return remainingNearbySearchesForPolicy(policy: policy);
    }
    final max = policy?.tenantNearbySearches ?? 3;
    if (max == -1) return 999;
    if (max <= 0) return 0;
    return (max - radiusSearchCount).clamp(0, max);
  }

  int get freeRadiusSearchesRemaining => freeRadiusSearchesRemainingForPolicy();

  // --- Multi-Plan Dynamic Quota & Facility Helper Getters ---

  /// Can post rental listing / tenant demand (supports active plans and dynamic free tier policy)
  bool canCreatePostForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.isPlanActive && p.hasPostQuota);
      }
      if (subscriptionMaxPosts == -1) return true;
      return subscriptionPostsCount < subscriptionMaxPosts;
    }
    final int freeLimit = isHouseOwner
        ? (policy?.ownerMaxListings ?? 1)
        : (policy?.tenantMaxDemands ?? 1);
    if (freeLimit == -1) return true;
    if (freeLimit <= 0) return false;
    return subscriptionPostsCount < freeLimit;
  }

  bool get canCreatePost => canCreatePostForPolicy();

  int remainingPostsForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        final activeList = activePlans.where((p) => p.isPlanActive).toList();
        if (activeList.isEmpty) return 0;
        if (activeList.any((p) => p.maxPostsLimit == -1)) return 999;
        return activeList.fold<int>(0, (total, p) => total + p.remainingPosts);
      }
      if (subscriptionMaxPosts == -1) return 999;
      return (subscriptionMaxPosts - subscriptionPostsCount).clamp(0, subscriptionMaxPosts);
    }
    final int freeLimit = isHouseOwner
        ? (policy?.ownerMaxListings ?? 1)
        : (policy?.tenantMaxDemands ?? 1);
    if (freeLimit == -1) return 999;
    if (freeLimit <= 0) return 0;
    return (freeLimit - subscriptionPostsCount).clamp(0, freeLimit);
  }

  int get remainingPosts => remainingPostsForPolicy();

  /// Can unlock contact number (property landlord or tenant demand)
  bool canUnlockContactForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.hasUnlockQuota);
      }
      if (subscriptionMaxUnlocks == -1) return true;
      return subscriptionUnlocksCount < subscriptionMaxUnlocks;
    }
    if (isHouseOwner) return freeDemandUnlocksRemainingForPolicy(policy: policy) > 0;
    return freePropertyUnlocksRemainingForPolicy(policy: policy) > 0;
  }

  bool get canUnlockContact => canUnlockContactForPolicy();

  int remainingContactUnlocksForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        if (activePlans.any((p) => p.unlockNumbersLimit == -1)) return 999;
        return activePlans.fold<int>(0, (total, p) => total + p.remainingUnlocks);
      }
      if (subscriptionMaxUnlocks == -1) return 999;
      return (subscriptionMaxUnlocks - subscriptionUnlocksCount).clamp(0, subscriptionMaxUnlocks);
    }
    if (isHouseOwner) return freeDemandUnlocksRemainingForPolicy(policy: policy);
    return freePropertyUnlocksRemainingForPolicy(policy: policy);
  }

  int get remainingContactUnlocks => remainingContactUnlocksForPolicy();

  /// Sub-area unlock quota (general helper)
  bool get canUnlockSubArea {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.hasSubAreaQuota);
      }
      return true;
    }
    return false; // Free accounts default locked unless policy passed
  }

  int get remainingSubAreaUnlocks {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        if (activePlans.any((p) => p.subAreaUnlockLimit == -1)) return 999;
        return activePlans.fold<int>(0, (total, p) => total + p.remainingSubAreaUnlocks);
      }
      return 999;
    }
    return 0;
  }

  /// Check if a property's sub-area is unlocked for the tenant
  bool isPropertySubAreaUnlocked(String propertyId, {FreeTierPolicyModel? policy, String? landlordId}) {
    if (landlordId != null && uid == landlordId) return true;
    return unlockedPropertySubAreaIds.contains(propertyId);
  }

  /// Check if a demand's sub-area is unlocked for the house owner
  bool isDemandSubAreaUnlocked(String demandId, {FreeTierPolicyModel? policy, String? tenantId}) {
    if (tenantId != null && uid == tenantId) return true;
    return unlockedDemandSubAreaIds.contains(demandId);
  }

  /// Can tenant unlock a property's sub-area
  bool canUnlockSubAreaForTenant({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.hasSubAreaQuota);
      }
      return true;
    }
    final max = policy?.tenantSubAreaUnlocks ?? 0;
    if (max == -1) return true;
    if (max <= 0) return false;
    return unlockedPropertySubAreaIds.length < max;
  }

  /// Remaining tenant sub-area unlocks
  int remainingTenantSubAreaUnlocks({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        if (activePlans.any((p) => p.subAreaUnlockLimit == -1)) return 999;
        return activePlans.fold<int>(0, (sum, p) => sum + p.remainingSubAreaUnlocks);
      }
      return 999;
    }
    final max = policy?.tenantSubAreaUnlocks ?? 0;
    if (max == -1) return 999;
    if (max <= 0) return 0;
    return (max - unlockedPropertySubAreaIds.length).clamp(0, max);
  }

  /// Can house owner unlock a demand's sub-area
  bool canUnlockSubAreaForOwner({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.hasSubAreaQuota);
      }
      return true;
    }
    final max = policy?.ownerSubAreaUnlocks ?? 0;
    if (max == -1) return true;
    if (max <= 0) return false;
    return unlockedDemandSubAreaIds.length < max;
  }

  /// Remaining house owner sub-area unlocks
  int remainingOwnerSubAreaUnlocks({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        if (activePlans.any((p) => p.subAreaUnlockLimit == -1)) return 999;
        return activePlans.fold<int>(0, (sum, p) => sum + p.remainingSubAreaUnlocks);
      }
      return 999;
    }
    final max = policy?.ownerSubAreaUnlocks ?? 0;
    if (max == -1) return 999;
    if (max <= 0) return 0;
    return (max - unlockedDemandSubAreaIds.length).clamp(0, max);
  }

  /// Can view full additional photos (subscribers with photo access OR unlocked for this property)
  bool isPhotoGalleryUnlockedForProperty(String propertyId, {FreeTierPolicyModel? policy}) {
    if (unlockedPhotoPropertyIds.contains(propertyId)) return true;
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        // If unlimited in any active plan, all properties are accessible
        if (activePlans.any((p) => p.isPlanActive && p.fullPhotoGalleryLimit == -1)) return true;
        // If numeric limit (> 0), requires unlocking this property ID
        return unlockedPhotoPropertyIds.contains(propertyId);
      } else if (subscriptionCanAccessPhotos) {
        return true;
      }
    }
    // Free tier unlimited if set to -1
    if (policy != null && policy.tenantFullPhotoGallery == -1) return true;
    return unlockedPhotoPropertyIds.contains(propertyId);
  }

  bool canUnlockPhotoGallery({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.isPlanActive && p.hasPhotoGalleryQuota);
      }
      return subscriptionCanAccessPhotos;
    }
    final max = policy?.tenantFullPhotoGallery ?? 0;
    if (max == -1) return true;
    if (max <= 0) return false;
    return unlockedPhotoPropertyIds.length < max;
  }

  int remainingPhotoGalleryUnlocks({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        final activeList = activePlans.where((p) => p.isPlanActive).toList();
        if (activeList.isEmpty) return 0;
        if (activeList.any((p) => p.fullPhotoGalleryLimit == -1)) return 999;
        return activeList.fold<int>(0, (total, p) => total + p.remainingPhotoGallery);
      }
      if (subscriptionCanAccessPhotos) return 999;
      return 0;
    }
    final max = policy?.tenantFullPhotoGallery ?? 0;
    if (max == -1) return 999;
    if (max <= 0) return 0;
    return (max - unlockedPhotoPropertyIds.length).clamp(0, max);
  }

  bool get canViewAdditionalPhotos {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.isPlanActive && p.hasPhotoGalleryAccess);
      }
      return subscriptionCanAccessPhotos;
    }
    return false;
  }

  /// Can perform nearby / radius search (supports Admin, Active Subscription Plans, and Role-specific Free Tier Policy)
  bool canPerformNearbySearchForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.isPlanActive && p.hasNearbyQuota);
      }
      if (subscriptionMaxNearbySearches == -1) return true;
      if (subscriptionMaxNearbySearches > 0) {
        return subscriptionNearbySearchCount < subscriptionMaxNearbySearches;
      }
      return false;
    }
    final max = policy?.tenantNearbySearches ?? 3;
    if (max == -1) return true;
    if (max <= 0) return false;
    return radiusSearchCount < max;
  }

  bool get canPerformNearbySearch => canPerformNearbySearchForPolicy();

  int remainingNearbySearchesForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        final activeList = activePlans.where((p) => p.isPlanActive).toList();
        if (activeList.isEmpty) return 0;
        if (activeList.any((p) => p.nearbySearchLimit == -1)) return 999;
        return activeList.fold<int>(0, (total, p) => total + p.remainingNearby);
      }
      if (subscriptionMaxNearbySearches == -1) return 999;
      if (subscriptionMaxNearbySearches > 0) {
        return (subscriptionMaxNearbySearches - subscriptionNearbySearchCount).clamp(0, subscriptionMaxNearbySearches);
      }
      return 0;
    }
    final max = policy?.tenantNearbySearches ?? 3;
    if (max == -1) return 999;
    if (max <= 0) return 0;
    return (max - radiusSearchCount).clamp(0, max);
  }

  int get remainingNearbySearches => remainingNearbySearchesForPolicy();

  /// Can open Google Maps navigation directions
  bool canOpenMapDirectionsForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.hasMapDirectionsQuota);
      }
      if (subscriptionMaxMapDirections == -1) return true;
      return subscriptionMapDirectionsCount < subscriptionMaxMapDirections;
    }
    final max = policy?.tenantMapDirections ?? 2;
    if (max == -1) return true;
    if (max <= 0) return false;
    return subscriptionMapDirectionsCount < max;
  }

  bool get canOpenMapDirections => canOpenMapDirectionsForPolicy();

  int remainingMapDirectionsForPolicy({FreeTierPolicyModel? policy}) {
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        if (activePlans.any((p) => p.mapDirectionsLimit == -1)) return 999;
        return activePlans.fold<int>(0, (total, p) => total + p.remainingMapDirections);
      }
      if (subscriptionMaxMapDirections == -1) return 999;
      return (subscriptionMaxMapDirections - subscriptionMapDirectionsCount).clamp(0, subscriptionMaxMapDirections);
    }
    final max = policy?.tenantMapDirections ?? 2;
    if (max == -1) return 999;
    if (max <= 0) return 0;
    return (max - subscriptionMapDirectionsCount).clamp(0, max);
  }

  int get remainingMapDirections => remainingMapDirectionsForPolicy();

  /// Can use AI Assistant (supports Admin, Active Subscription Plans, and Role-specific Free Tier Policy)
  bool canUseAiAssistantForRole({FreeTierPolicyModel? policy}) {
    if (isAdmin) return true;
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        return activePlans.any((p) => p.isPlanActive && p.hasAiQuota);
      }
      if (subscriptionMaxAiQueries == -1) return true;
      if (subscriptionMaxAiQueries > 0) {
        return aiAssistantQueryCount < subscriptionMaxAiQueries;
      }
      return false;
    }
    final int freeLimit = isHouseOwner
        ? (policy?.ownerAiAssistant ?? 2)
        : (policy?.tenantAiAssistant ?? 2);
    if (freeLimit == -1) return true;
    if (freeLimit <= 0) return false;
    return aiAssistantQueryCount < freeLimit;
  }

  /// Default getter for backward compatibility
  bool get canUseAiAssistant => canUseAiAssistantForRole();

  /// Remaining AI Assistant queries
  int remainingAiQueriesForRole({FreeTierPolicyModel? policy}) {
    if (isAdmin) return 999;
    if (isSubscribed) {
      if (activePlans.isNotEmpty) {
        final activeList = activePlans.where((p) => p.isPlanActive).toList();
        if (activeList.isEmpty) return 0;
        if (activeList.any((p) => p.aiAssistantLimit == -1)) return 999;
        return activeList.fold<int>(0, (total, p) => total + p.remainingAi);
      }
      if (subscriptionMaxAiQueries == -1) return 999;
      if (subscriptionMaxAiQueries > 0) {
        return (subscriptionMaxAiQueries - aiAssistantQueryCount).clamp(0, subscriptionMaxAiQueries);
      }
      return 0;
    }
    final int freeLimit = isHouseOwner
        ? (policy?.ownerAiAssistant ?? 2)
        : (policy?.tenantAiAssistant ?? 2);
    if (freeLimit == -1) return 999;
    if (freeLimit <= 0) return 0;
    return (freeLimit - aiAssistantQueryCount).clamp(0, freeLimit);
  }

  /// Default getter for backward compatibility
  int get remainingAiQueries => remainingAiQueriesForRole();

  /// Whether the user can upgrade or add a new subscription plan:
  /// - Free accounts can always purchase a plan.
  /// - Active subscribers can upgrade if AT LEAST ONE quota is exhausted (remaining == 0).
  /// - If ALL quotas across active plans are positive (> 0 or unlimited), upgrading is locked.
  bool canUpgradeOrAddPlan({FreeTierPolicyModel? policy}) {
    if (!isSubscribed) return true;
    if (activePlans.isEmpty) return true;

    if (isHouseOwner) {
      final postsLeft = remainingPostsForPolicy(policy: policy);
      final contactsLeft = remainingContactUnlocksForPolicy(policy: policy);
      final subAreasLeft = remainingOwnerSubAreaUnlocks(policy: policy);
      final aiLeft = remainingAiQueriesForRole(policy: policy);

      // If any of the 4 facilities has 0 remaining, allowed to upgrade!
      return postsLeft == 0 || contactsLeft == 0 || subAreasLeft == 0 || aiLeft == 0;
    } else {
      // Tenant: 7 facilities
      final demandsLeft = remainingPostsForPolicy(policy: policy);
      final contactsLeft = remainingContactUnlocksForPolicy(policy: policy);
      final subAreasLeft = remainingTenantSubAreaUnlocks(policy: policy);
      final photoLeft = remainingPhotoGalleryUnlocks(policy: policy);
      final nearbyLeft = remainingNearbySearchesForPolicy(policy: policy);
      final directionsLeft = remainingMapDirectionsForPolicy(policy: policy);
      final aiLeft = remainingAiQueriesForRole(policy: policy);

      // If any of the 7 facilities has 0 remaining, allowed to upgrade!
      return demandsLeft == 0 ||
          contactsLeft == 0 ||
          subAreasLeft == 0 ||
          photoLeft == 0 ||
          nearbyLeft == 0 ||
          directionsLeft == 0 ||
          aiLeft == 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'mobile': mobile,
      'city': city,
      'userType': userType,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'nidFrontImageUrl': nidFrontImageUrl,
      'nidBackImageUrl': nidBackImageUrl,
      'createdAt': createdAt,
      'verificationStatus': verificationStatus,
      'verificationFeedback': verificationFeedback,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'blockReason': blockReason,
      'blockedAt': blockedAt,
      'appealStatus': appealStatus,
      'appealNote': appealNote,
      'appealContact': appealContact,
      'appealAt': appealAt,
      'appealFeedback': appealFeedback,
      'unlockedPropertyIds': unlockedPropertyIds,
      'unlockedDemandIds': unlockedDemandIds,
      'unlockedPropertySubAreaIds': unlockedPropertySubAreaIds,
      'unlockedDemandSubAreaIds': unlockedDemandSubAreaIds,
      'unlockedPhotoPropertyIds': unlockedPhotoPropertyIds,
      'radiusSearchCount': radiusSearchCount,
      'subscriptionPlanId': subscriptionPlanId,
      'subscriptionExpiryDate': subscriptionExpiryDate,
      'subscriptionPostsCount': subscriptionPostsCount,
      'subscriptionUnlocksCount': subscriptionUnlocksCount,
      'subscriptionNearbySearchCount': subscriptionNearbySearchCount,
      'subscriptionMapDirectionsCount': subscriptionMapDirectionsCount,
      'aiAssistantQueryCount': aiAssistantQueryCount,
      'subscriptionMaxPosts': subscriptionMaxPosts,
      'subscriptionMaxUnlocks': subscriptionMaxUnlocks,
      'subscriptionCanAccessPhotos': subscriptionCanAccessPhotos,
      'subscriptionMaxNearbySearches': subscriptionMaxNearbySearches,
      'subscriptionMaxMapDirections': subscriptionMaxMapDirections,
      'subscriptionMaxAiQueries': subscriptionMaxAiQueries,
      'activeSubscriptionPlans': activeSubscriptionPlans.map((p) => p.toMap()).toList(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    String status = (map['verificationStatus'] as String?) ??
        (map['nidVerificationStatus'] as String?) ??
        '';
    if (status.isEmpty) {
      if (map['isVerified'] == true) {
        status = 'verified';
      } else {
        status = 'unverified';
      }
    }

    final feedback = (map['verificationFeedback'] as String?) ??
        (map['nidRejectionReason'] as String?) ??
        '';

    final legacyExpiryStr = map['subscriptionExpiryDate'] as String? ?? '';
    DateTime? legacyExpiry;
    if (legacyExpiryStr.isNotEmpty) {
      try {
        legacyExpiry = DateTime.parse(legacyExpiryStr);
      } catch (_) {}
    }

    final List<UserSubscriptionPlan> plans = [];
    if (map['activeSubscriptionPlans'] != null && map['activeSubscriptionPlans'] is List) {
      for (final item in map['activeSubscriptionPlans']) {
        if (item is Map<String, dynamic>) {
          plans.add(UserSubscriptionPlan.fromMap(item));
        } else if (item is Map) {
          plans.add(UserSubscriptionPlan.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Synthesize active plan from legacy fields if unexpired and activeSubscriptionPlans was empty
    if (plans.isEmpty && legacyExpiry != null && legacyExpiry.isAfter(DateTime.now())) {
      final photoAccess = map['subscriptionCanAccessPhotos'] == true;
      final planTitleBn = (map['subscriptionPlanTitleBn'] as String?)?.isNotEmpty == true
          ? map['subscriptionPlanTitleBn']!
          : ((map['subscriptionPlanTitle'] as String?)?.isNotEmpty == true
              ? map['subscriptionPlanTitle']!
              : 'সক্রিয় প্যাকেজ');
      final planTitleEn = (map['subscriptionPlanTitleEn'] as String?)?.isNotEmpty == true
          ? map['subscriptionPlanTitleEn']!
          : 'Active Package';

      plans.add(UserSubscriptionPlan(
        id: map['subscriptionPlanId'] ?? 'plan_legacy',
        planId: map['subscriptionPlanId'] ?? 'plan_legacy',
        titleBn: planTitleBn,
        titleEn: planTitleEn,
        purchasedAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: legacyExpiry,
        amountPaid: 0,
        durationDays: 30,
        maxPostsLimit: (map['subscriptionMaxPosts'] as num?)?.toInt() ?? (map['subscriptionPlanMaxPosts'] as num?)?.toInt() ?? 3,
        postsUsed: (map['subscriptionPostsCount'] as num?)?.toInt() ?? 0,
        unlockNumbersLimit: (map['subscriptionMaxUnlocks'] as num?)?.toInt() ?? (map['subscriptionPlanMaxUnlocks'] as num?)?.toInt() ?? 3,
        unlocksUsed: (map['subscriptionUnlocksCount'] as num?)?.toInt() ?? 0,
        subAreaUnlockLimit: (map['subscriptionSubAreaUnlocks'] as num?)?.toInt() ?? 3,
        subAreaUnlocksUsed: (map['subscriptionSubAreaUnlocksUsed'] as num?)?.toInt() ?? 0,
        fullPhotoGalleryLimit: (map['subscriptionFullPhotoGallery'] as num?)?.toInt() ?? (photoAccess ? -1 : 3),
        photoGalleryUsed: (map['subscriptionPhotoGalleryUsed'] as num?)?.toInt() ?? 0,
        nearbySearchLimit: (map['subscriptionMaxNearbySearches'] as num?)?.toInt() ?? 3,
        nearbySearchUsed: (map['subscriptionNearbySearchCount'] as num?)?.toInt() ?? 0,
        mapDirectionsLimit: (map['subscriptionMaxMapDirections'] as num?)?.toInt() ?? 3,
        mapDirectionsUsed: (map['subscriptionMapDirectionsCount'] as num?)?.toInt() ?? 0,
        aiAssistantLimit: (map['subscriptionMaxAiQueries'] as num?)?.toInt() ?? 3,
        aiAssistantUsed: (map['aiAssistantQueryCount'] as num?)?.toInt() ?? 0,
      ));
    }

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'] ?? '',
      lastName: map['lastName'] ?? '',
      mobile: map['mobile'] ?? '',
      city: map['city'] ?? '',
      userType: map['userType'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      gender: map['gender'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      nidFrontImageUrl: map['nidFrontImageUrl'] ?? '',
      nidBackImageUrl: map['nidBackImageUrl'] ?? '',
      createdAt: map['createdAt'] ?? '',
      verificationStatus: status,
      verificationFeedback: feedback,
      isBlocked: map['isBlocked'] == true,
      blockReason: map['blockReason'] ?? '',
      blockedAt: map['blockedAt'] ?? '',
      appealStatus: map['appealStatus'] ?? 'none',
      appealNote: map['appealNote'] ?? '',
      appealContact: map['appealContact'] ?? '',
      appealAt: map['appealAt'] ?? '',
      appealFeedback: map['appealFeedback'] ?? '',
      unlockedPropertyIds: List<String>.from(map['unlockedPropertyIds'] ?? []),
      unlockedDemandIds: List<String>.from(map['unlockedDemandIds'] ?? []),
      unlockedPropertySubAreaIds: List<String>.from(map['unlockedPropertySubAreaIds'] ?? map['unlockedSubAreaIds'] ?? []),
      unlockedDemandSubAreaIds: List<String>.from(map['unlockedDemandSubAreaIds'] ?? []),
      unlockedPhotoPropertyIds: List<String>.from(map['unlockedPhotoPropertyIds'] ?? []),
      radiusSearchCount: (map['radiusSearchCount'] as num?)?.toInt() ?? 0,
      subscriptionPlanId: map['subscriptionPlanId'] ?? '',
      subscriptionExpiryDate: legacyExpiryStr,
      subscriptionPostsCount: (map['subscriptionPostsCount'] as num?)?.toInt() ?? 0,
      subscriptionUnlocksCount: (map['subscriptionUnlocksCount'] as num?)?.toInt() ?? 0,
      subscriptionNearbySearchCount: (map['subscriptionNearbySearchCount'] as num?)?.toInt() ?? 0,
      subscriptionMapDirectionsCount: (map['subscriptionMapDirectionsCount'] as num?)?.toInt() ?? 0,
      aiAssistantQueryCount: (map['aiAssistantQueryCount'] as num?)?.toInt() ?? 0,
      subscriptionMaxPosts: (map['subscriptionMaxPosts'] as num?)?.toInt() ?? 1,
      subscriptionMaxUnlocks: (map['subscriptionMaxUnlocks'] as num?)?.toInt() ?? -1,
      subscriptionCanAccessPhotos: map['subscriptionCanAccessPhotos'] ?? false,
      subscriptionMaxNearbySearches: (map['subscriptionMaxNearbySearches'] as num?)?.toInt() ?? 3,
      subscriptionMaxMapDirections: (map['subscriptionMaxMapDirections'] as num?)?.toInt() ?? 2,
      subscriptionMaxAiQueries: (map['subscriptionMaxAiQueries'] as num?)?.toInt() ?? 2,
      activeSubscriptionPlans: plans,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? middleName,
    String? lastName,
    String? mobile,
    String? city,
    String? userType,
    String? profileImageUrl,
    String? gender,
    String? dateOfBirth,
    String? nidFrontImageUrl,
    String? nidBackImageUrl,
    String? createdAt,
    String? verificationStatus,
    String? verificationFeedback,
    bool? isBlocked,
    String? blockReason,
    String? blockedAt,
    String? appealStatus,
    String? appealNote,
    String? appealContact,
    String? appealAt,
    String? appealFeedback,
    List<String>? unlockedPropertyIds,
    List<String>? unlockedDemandIds,
    List<String>? unlockedPropertySubAreaIds,
    List<String>? unlockedDemandSubAreaIds,
    List<String>? unlockedPhotoPropertyIds,
    int? radiusSearchCount,
    String? subscriptionPlanId,
    String? subscriptionExpiryDate,
    int? subscriptionPostsCount,
    int? subscriptionUnlocksCount,
    int? subscriptionNearbySearchCount,
    int? subscriptionMapDirectionsCount,
    int? aiAssistantQueryCount,
    int? subscriptionMaxPosts,
    int? subscriptionMaxUnlocks,
    bool? subscriptionCanAccessPhotos,
    int? subscriptionMaxNearbySearches,
    int? subscriptionMaxMapDirections,
    int? subscriptionMaxAiQueries,
    List<UserSubscriptionPlan>? activeSubscriptionPlans,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      mobile: mobile ?? this.mobile,
      city: city ?? this.city,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nidFrontImageUrl: nidFrontImageUrl ?? this.nidFrontImageUrl,
      nidBackImageUrl: nidBackImageUrl ?? this.nidBackImageUrl,
      createdAt: createdAt ?? this.createdAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationFeedback: verificationFeedback ?? this.verificationFeedback,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: blockReason ?? this.blockReason,
      blockedAt: blockedAt ?? this.blockedAt,
      appealStatus: appealStatus ?? this.appealStatus,
      appealNote: appealNote ?? this.appealNote,
      appealContact: appealContact ?? this.appealContact,
      appealAt: appealAt ?? this.appealAt,
      appealFeedback: appealFeedback ?? this.appealFeedback,
      unlockedPropertyIds: unlockedPropertyIds ?? this.unlockedPropertyIds,
      unlockedDemandIds: unlockedDemandIds ?? this.unlockedDemandIds,
      unlockedPropertySubAreaIds: unlockedPropertySubAreaIds ?? this.unlockedPropertySubAreaIds,
      unlockedDemandSubAreaIds: unlockedDemandSubAreaIds ?? this.unlockedDemandSubAreaIds,
      unlockedPhotoPropertyIds: unlockedPhotoPropertyIds ?? this.unlockedPhotoPropertyIds,
      radiusSearchCount: radiusSearchCount ?? this.radiusSearchCount,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      subscriptionPostsCount: subscriptionPostsCount ?? this.subscriptionPostsCount,
      subscriptionUnlocksCount: subscriptionUnlocksCount ?? this.subscriptionUnlocksCount,
      subscriptionNearbySearchCount: subscriptionNearbySearchCount ?? this.subscriptionNearbySearchCount,
      subscriptionMapDirectionsCount: subscriptionMapDirectionsCount ?? this.subscriptionMapDirectionsCount,
      aiAssistantQueryCount: aiAssistantQueryCount ?? this.aiAssistantQueryCount,
      subscriptionMaxPosts: subscriptionMaxPosts ?? this.subscriptionMaxPosts,
      subscriptionMaxUnlocks: subscriptionMaxUnlocks ?? this.subscriptionMaxUnlocks,
      subscriptionCanAccessPhotos: subscriptionCanAccessPhotos ?? this.subscriptionCanAccessPhotos,
      subscriptionMaxNearbySearches: subscriptionMaxNearbySearches ?? this.subscriptionMaxNearbySearches,
      subscriptionMaxMapDirections: subscriptionMaxMapDirections ?? this.subscriptionMaxMapDirections,
      subscriptionMaxAiQueries: subscriptionMaxAiQueries ?? this.subscriptionMaxAiQueries,
      activeSubscriptionPlans: activeSubscriptionPlans ?? this.activeSubscriptionPlans,
    );
  }
}
