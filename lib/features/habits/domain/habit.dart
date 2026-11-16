class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final String frequencyType; // daily, specific_days, weekly_target
  final Map<String, dynamic> frequencyConfig;
  final int targetPerPeriod;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color = '#4CAF50',
    this.icon = 'check_circle',
    this.frequencyType = 'daily',
    this.frequencyConfig = const {},
    this.targetPerPeriod = 1,
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isArchived => archivedAt != null;

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#4CAF50',
      icon: json['icon'] as String? ?? 'check_circle',
      frequencyType: json['frequency_type'] as String? ?? 'daily',
      frequencyConfig: json['frequency_config'] != null
          ? Map<String, dynamic>.from(json['frequency_config'] as Map)
          : const {},
      targetPerPeriod: json['target_per_period'] as int? ?? 1,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
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
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'frequency_type': frequencyType,
      'frequency_config': frequencyConfig,
      'target_per_period': targetPerPeriod,
      'archived_at': archivedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Habit copyWith({
    String? name,
    String? description,
    String? color,
    String? icon,
    String? frequencyType,
    Map<String, dynamic>? frequencyConfig,
    int? targetPerPeriod,
    DateTime? archivedAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyConfig: frequencyConfig ?? this.frequencyConfig,
      targetPerPeriod: targetPerPeriod ?? this.targetPerPeriod,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
