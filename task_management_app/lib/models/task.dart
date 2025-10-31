class Task {
  final int id;
  final String title;
  final String? description;
  final String? status;
  final String? priority;
  final String? dueDate;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.priority,
    this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String?,
      priority: json['priority'] as String?,
      dueDate: json['due_date'] as String?,
    );
  }
}
