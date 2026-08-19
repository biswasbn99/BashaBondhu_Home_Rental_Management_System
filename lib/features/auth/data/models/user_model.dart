class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String mobile;
  final String city;
  final String userType; // 'House Owner' or 'Tenant'

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.city,
    required this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'city': city,
      'userType': userType,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      mobile: map['mobile'] ?? '',
      city: map['city'] ?? '',
      userType: map['userType'] ?? '',
    );
  }
}
