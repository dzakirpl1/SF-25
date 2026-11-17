class FocusSession {
  final String id;
  final String userId;
  final String? taskId;
  final String? projectId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int plannedMinutes;
  final int actualMinutes;
  final bool completed;
  final String sessionType; // 'pomodoro', 'short_break', 'long_break', 'custom'
  final String? note;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FocusSession({
    required this.id,
    required this.userId,
    this.taskId,
    this.projectId,
    required this.startedAt,
    this.endedAt,
    this.plannedMinutes = 25,
    this.actualMinutes = 0,
    this.completed = true,
    this.sessionType = 'pomodoro',
    this.note,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPomodoro => sessionType == 'pomodoro';
  bool get isBreak =>
      sessionType == 'short_break' || sessionType == 'long_break';

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskId: json['task_id'] as String?,
      projectId: json['project_id'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      plannedMinutes: json['planned_minutes'] as int? ?? 25,
      actualMinutes: json['actual_minutes'] as int? ?? 0,
      completed: json['completed'] as bool? ?? true,
      sessionType: json['session_type'] as String? ?? 'pomodoro',
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
      'task_id': taskId,
      'project_id': projectId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt?.toUtc().toIso8601String(),
      'planned_minutes': plannedMinutes,
      'actual_minutes': actualMinutes,
      'completed': completed,
      'session_type': sessionType,
      'note': note,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  FocusSession copyWith({
    String? taskId,
    String? projectId,
    DateTime? endedAt,
    int? plannedMinutes,
    int? actualMinutes,
    bool? completed,
    String? sessionType,
    String? note,
  }) {
    return FocusSession(
      id: id,
      userId: userId,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      completed: completed ?? this.completed,
      sessionType: sessionType ?? this.sessionType,
      note: note ?? this.note,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
