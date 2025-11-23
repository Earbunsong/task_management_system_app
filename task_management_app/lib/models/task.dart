import 'package:task_management_app/services/media_service.dart';

class AssignedUser {
  final int id;
  final String username;
  final String email;
  final String role;

  AssignedUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'basic',
    );
  }
}

class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final int? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<MediaFile> mediaFiles;
  final List<AssignedUser> assignedUsers;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
    this.mediaFiles = const [],
    this.assignedUsers = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Map Django API status to Flutter status
    String mapStatus(String? status) {
      switch (status) {
        case 'todo':
          return 'pending';
        case 'done':
          return 'completed';
        default:
          return status ?? 'pending'; // 'in_progress' stays the same
      }
    }

    // Parse media files if present
    List<MediaFile> parseMediaFiles(dynamic mediaData) {
      if (mediaData == null) return [];
      if (mediaData is! List) return [];
      return mediaData
          .map((e) => e is Map<String, dynamic> ? MediaFile.fromJson(e) : null)
          .whereType<MediaFile>()
          .toList();
    }

    // Parse assigned users if present
    List<AssignedUser> parseAssignedUsers(dynamic userData) {
      if (userData == null) return [];
      if (userData is! List) return [];
      return userData
          .map((e) => e is Map<String, dynamic> ? AssignedUser.fromJson(e) : null)
          .whereType<AssignedUser>()
          .toList();
    }

    return Task(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: mapStatus(json['status'] as String?),
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      ownerId: json['owner_id'] as int? ?? json['owner'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      mediaFiles: parseMediaFiles(json['media_files']),
      assignedUsers: parseAssignedUsers(json['assigned_users']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'owner_id': ownerId,
    };
  }
}
