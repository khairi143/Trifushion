class UserModel {
  final String name;
  final String email;
  final String contactNo;
  final String height;
  final String weight;
  final String gender;
  final String userId;
  final String userType;
  final bool isBanned;

  UserModel({
    required this.name,
    required this.email,
    required this.contactNo,
    required this.height,
    required this.weight,
    required this.gender,
    required this.userId,
    this.userType = 'user',
    this.isBanned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'contactno': contactNo,
      'height': height,
      'weight': weight,
      'gender': gender,
      'userID': userId,
      'usertype': userType,
      'isBanned': isBanned,
    };
  }
}
