import 'package:task_management_app/services/api_client.dart';

class AdminUser {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool isVerified;
  final bool isDisabled;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.isDisabled,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isVerified: json['is_verified'] as bool,
      isDisabled: json['is_disabled'] as bool,
    );
  }
}

class AdminService {
  final _client = ApiClient();

  AdminService() {
    _client.init();
  }

  /// Get all users (admin only)
  Future<List<AdminUser>> getAllUsers() async {
    final res = await _client.dio.get('/admin/users/');
    final List data = res.data as List;
    return data.map((json) => AdminUser.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Disable a user (admin only)
  Future<void> disableUser(int userId) async {
    await _client.dio.patch('/auth/user/$userId/disable/');
  }

  /// Enable a user (admin only)
  Future<void> enableUser(int userId) async {
    await _client.dio.patch('/auth/user/$userId/enable/');
  }
}
