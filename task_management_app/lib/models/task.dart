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
