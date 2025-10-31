class AppNotification {
  final int id;
  final String message;
  final bool isRead;
  final String createdAt;

  AppNotification({required this.id, required this.message, required this.isRead, required this.createdAt});

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      message: json['message'] as String? ?? '',
      isRead: (json['read_status'] as bool?) ?? (json['read'] as bool? ?? false),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
