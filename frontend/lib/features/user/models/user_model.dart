class UserModel {
  final int? id;
  final String username;
  final String firstName;
  final String lastName;
  final String? dob;
  final String email;
  final String? address;
  final String? avatar; // URL của ảnh
  final String? phoneNumber;
  final String? userType;
  final int? followCount;

  UserModel({
    this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.dob,
    required this.email,
    this.address,
    this.avatar,
    this.phoneNumber,
    this.userType,
    this.followCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      username: json['username'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      dob: json['dob'] as String?,
      email: json['email'] as String,
      address: json['address'] as String?,
      avatar: json['avatar'] as String?, // lấy URL từ API
      phoneNumber: json['phone_number'] as String?,
      userType: json['user_type'] as String?,
      followCount: json['follow_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'dob': dob,
      'email': email,
      'address': address,
      'avatar': avatar,
      'phone_number': phoneNumber,
      'user_type': userType,
      'follow_count': followCount,
    };
  }
}
