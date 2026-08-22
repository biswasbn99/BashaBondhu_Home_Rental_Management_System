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
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
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
    );
  }
}
