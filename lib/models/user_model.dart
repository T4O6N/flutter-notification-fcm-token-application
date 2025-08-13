class User {
  final int id;
  final String uuid;
  final String email;
  final String username;
  final String? phoneNumber;
  final String? bio;
  final String? dateOfBirth;
  final int? age;
  final Map<String, dynamic>? profileImage;
  final DateTime? lastLogin;
  final String? gender;
  final int tokenExpirationDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firebaseUid;
  final String? photoUrl;
  final String authProvider;
  final bool isEmailVerified;

  User({
    required this.id,
    required this.uuid,
    required this.email,
    required this.username,
    this.phoneNumber,
    this.bio,
    this.dateOfBirth,
    this.age,
    this.profileImage,
    this.lastLogin,
    this.gender,
    required this.tokenExpirationDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseUid,
    this.photoUrl,
    required this.authProvider,
    required this.isEmailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      uuid: json['uuid'],
      email: json['email'],
      username: json['username'],
      phoneNumber: json['phone_number'],
      bio: json['bio'],
      dateOfBirth: json['date_of_birth'],
      age: json['age'],
      profileImage: json['profile_image'],
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      gender: json['gender'],
      tokenExpirationDays: json['token_expiration_days'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      firebaseUid: json['firebase_uid'],
      photoUrl: json['photo_url'],
      authProvider: json['auth_provider'],
      isEmailVerified: json['is_email_verified'],
    );
  }
}
