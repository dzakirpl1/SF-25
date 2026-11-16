import 'routine_step.dart';

class Routine {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String timeOfDay; // morning, evening, custom
  final List<int> activeDays; // 1 = Senin s.d. 7 = Minggu
  final List<RoutineStep> steps;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Routine({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.timeOfDay = 'morning',
    this.activeDays = const [1, 2, 3, 4, 5, 6, 7],
    this.steps = const [],
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isArchived => archivedAt != null;

  factory Routine.fromJson(Map<String, dynamic> json,
      {List<RoutineStep> steps = const []}) {
    List<int> days = [1, 2, 3, 4, 5, 6, 7];
    if (json['active_days'] != null) {
      days = (json['active_days'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 1)
          .toList();
    }

    return Routine(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      timeOfDay: json['time_of_day'] as String? ?? 'morning',
      activeDays: days,
      steps: steps,
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
      'time_of_day': timeOfDay,
      'active_days': activeDays,
      'archived_at': archivedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Routine copyWith({
    String? name,
    String? description,
    String? timeOfDay,
    List<int>? activeDays,
    List<RoutineStep>? steps,
    DateTime? archivedAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      activeDays: activeDays ?? this.activeDays,
      steps: steps ?? this.steps,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
