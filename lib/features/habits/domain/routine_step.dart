class RoutineStep {
  final String id;
  final String userId;
  final String routineId;
  final String title;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineStep({
    required this.id,
    required this.userId,
    required this.routineId,
    required this.title,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> json) {
    return RoutineStep(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      routineId: json['routine_id'] as String,
      title: json['title'] as String,
      position: json['position'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'routine_id': routineId,
      'title': title,
      'position': position,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  RoutineStep copyWith({
    String? title,
    int? position,
    DateTime? updatedAt,
  }) {
    return RoutineStep(
      id: id,
      userId: userId,
      routineId: routineId,
      title: title ?? this.title,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
