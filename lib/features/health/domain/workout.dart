class Workout {
  final String id;
  final String userId;
  final String type; // Lari, Gym, Renang, Sepeda, Jalan Kaki, dll
  final DateTime startedAt;
  final int durationMinutes;
  final int? caloriesBurned;
  final String? note;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Workout({
    required this.id,
    required this.userId,
    required this.type,
    required this.startedAt,
    required this.durationMinutes,
    this.caloriesBurned,
    this.note,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      caloriesBurned: json['calories_burned'] as int?,
      note: json['note'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'started_at': startedAt.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'note': note,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
