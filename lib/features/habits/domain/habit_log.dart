class HabitLog {
  final String id;
  final String userId;
  final String habitId;
  final DateTime logDate; // yyyy-MM-dd
  final bool done;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitLog({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.logDate,
    this.done = true,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      habitId: json['habit_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      done: json['done'] as bool? ?? true,
      note: json['note'] as String?,
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
      'habit_id': habitId,
      'log_date': dateStr,
      'done': done,
      'note': note,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
