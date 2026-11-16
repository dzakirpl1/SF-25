class Subtask {
  final String id;
  final String userId;
  final String taskId;
  final String title;
  final bool isDone;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subtask({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.title,
    this.isDone = false,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskId: json['task_id'] as String,
      title: json['title'] as String,
      isDone: json['is_done'] as bool? ?? false,
      position: json['position'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'title': title,
      'is_done': isDone,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Subtask copyWith({
    String? title,
    bool? isDone,
    int? position,
    DateTime? updatedAt,
  }) {
    return Subtask(
      id: id,
      userId: userId,
      taskId: taskId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
