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
  final int radiusSearchCount;            // radius search uses for free tier
  final String subscriptionPlanId;        // plan id if active
  final String subscriptionExpiryDate;    // ISO string

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
    this.radiusSearchCount = 0,
    this.subscriptionPlanId = '',
    this.subscriptionExpiryDate = '',
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

  /// Parsed expiry date
  DateTime? get expiryDateTime {
    if (subscriptionExpiryDate.isEmpty) return null;
    try {
      return DateTime.parse(subscriptionExpiryDate);
    } catch (_) {
      return null;
    }
  }

  /// Check if user has an active premium subscription
  bool get isSubscribed {
    final expiry = expiryDateTime;
    if (expiry == null) return false;
    return expiry.isAfter(DateTime.now());
  }

  /// Free property unlocks remaining (5 max for free tenant)
  int get freePropertyUnlocksRemaining {
    if (isSubscribed) return 999;
    return (5 - unlockedPropertyIds.length).clamp(0, 5);
  }

  /// Free demand unlocks remaining (2 max for free owner)
  int get freeDemandUnlocksRemaining {
    if (isSubscribed) return 999;
    return (2 - unlockedDemandIds.length).clamp(0, 2);
  }

  /// Verification getters
  bool get isVerified => verificationStatus.toLowerCase() == 'verified';
  bool get isVerificationPending => verificationStatus.toLowerCase() == 'pending';
  bool get isVerificationRejected => verificationStatus.toLowerCase() == 'rejected';

  /// Free radius searches remaining (3 max for free tenant)
  int get freeRadiusSearchesRemaining {
    if (isSubscribed) return 999;
    return (3 - radiusSearchCount).clamp(0, 3);
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
      'radiusSearchCount': radiusSearchCount,
      'subscriptionPlanId': subscriptionPlanId,
      'subscriptionExpiryDate': subscriptionExpiryDate,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Determine verification status from verificationStatus or fallback to nidVerificationStatus / isVerified
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
      radiusSearchCount: (map['radiusSearchCount'] as num?)?.toInt() ?? 0,
      subscriptionPlanId: map['subscriptionPlanId'] ?? '',
      subscriptionExpiryDate: map['subscriptionExpiryDate'] ?? '',
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
    int? radiusSearchCount,
    String? subscriptionPlanId,
    String? subscriptionExpiryDate,
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
      radiusSearchCount: radiusSearchCount ?? this.radiusSearchCount,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
    );
  }
}
