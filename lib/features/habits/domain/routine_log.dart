class RoutineLog {
  final String id;
  final String userId;
  final String routineId;
  final DateTime logDate; // yyyy-MM-dd
  final List<String> completedStepIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineLog({
    required this.id,
    required this.userId,
    required this.routineId,
    required this.logDate,
    this.completedStepIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoutineLog.fromJson(Map<String, dynamic> json) {
    List<String> steps = [];
    if (json['completed_step_ids'] != null) {
      steps = (json['completed_step_ids'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return RoutineLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      routineId: json['routine_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      completedStepIds: steps,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final d = logDate;
    final dateStr =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
      'id': id,
      'user_id': userId,
      'routine_id': routineId,
      'log_date': dateStr,
      'completed_step_ids': completedStepIds,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
