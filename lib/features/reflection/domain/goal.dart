class Goal {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final String status; // 'active', 'completed', 'paused', 'cancelled'
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // List Key Results terkait (bila dimuat)
  final List<KeyResult> keyResults;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.targetDate,
    this.status = 'active',
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.keyResults = const [],
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  /// Rata-rata progress dari seluruh Key Results (0.0 sampai 1.0)
  double get overallProgress {
    if (keyResults.isEmpty) return isCompleted ? 1.0 : 0.0;
    double sum = 0.0;
    for (final kr in keyResults) {
      sum += kr.progress;
    }
    return sum / keyResults.length;
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {List<KeyResult>? keyResults}) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      keyResults: keyResults ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'target_date': targetDate?.toIso8601String().split('T').first,
      'status': status,
      'archived_at': archivedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Goal copyWith({
    String? title,
    String? description,
    DateTime? targetDate,
    String? status,
    List<KeyResult>? keyResults,
  }) {
    return Goal(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      archivedAt: archivedAt,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      keyResults: keyResults ?? this.keyResults,
    );
  }
}

class KeyResult {
  final String id;
  final String userId;
  final String goalId;
  final String title;
  final String metricType; // 'manual', 'tasks', 'habit'
  final double targetValue;
  final double currentValue;
  final String unit;
  final String? linkedId;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KeyResult({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.title,
    this.metricType = 'manual',
    required this.targetValue,
    this.currentValue = 0,
    this.unit = '%',
    this.linkedId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progress {
    if (targetValue <= 0) return 0.0;
    final p = currentValue / targetValue;
    return p > 1.0 ? 1.0 : p;
  }

  bool get isAchieved => progress >= 1.0;

  factory KeyResult.fromJson(Map<String, dynamic> json) {
    return KeyResult(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalId: json['goal_id'] as String,
      title: json['title'] as String,
      metricType: json['metric_type'] as String? ?? 'manual',
      targetValue: (json['target_value'] as num).toDouble(),
      currentValue: (json['current_value'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String? ?? '%',
      linkedId: json['linked_id'] as String?,
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
      'goal_id': goalId,
      'title': title,
      'metric_type': metricType,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'linked_id': linkedId,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  KeyResult copyWith({
    String? title,
    double? currentValue,
    double? targetValue,
    String? unit,
  }) {
    return KeyResult(
      id: id,
      userId: userId,
      goalId: goalId,
      title: title ?? this.title,
      metricType: metricType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      linkedId: linkedId,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
