class UserProfile {
  final int id;
  final String email;
  final String name;
  final String role;
  final String userType;
  final bool isVerified;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.userType,
    required this.isVerified,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'basic',
      userType: json['user_type'] as String? ?? 'basic',
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'user_type': userType,
      'is_verified': isVerified,
    };
  }
}
