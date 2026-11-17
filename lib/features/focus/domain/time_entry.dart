class TimeEntry {
  final String id;
  final String userId;
  final String? projectId;
  final String activity;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? note;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimeEntry({
    required this.id,
    required this.userId,
    this.projectId,
    required this.activity,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.note,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Durasi dalam menit pembulatan
  int get durationMinutes => (durationSeconds / 60).round();

  /// Format durasi jam dan menit: "1j 30m" atau "45m"
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes}m';
  }

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      activity: json['activity'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
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
      'project_id': projectId,
      'activity': activity,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt?.toUtc().toIso8601String(),
      'duration_seconds': durationSeconds,
      'note': note,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  TimeEntry copyWith({
    String? projectId,
    String? activity,
    DateTime? endedAt,
    int? durationSeconds,
    String? note,
  }) {
    return TimeEntry(
      id: id,
      userId: userId,
      projectId: projectId ?? this.projectId,
      activity: activity ?? this.activity,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      note: note ?? this.note,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
