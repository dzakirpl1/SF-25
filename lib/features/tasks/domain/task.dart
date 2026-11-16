import 'subtask.dart';

enum EisenhowerQuadrant {
  q1UrgentImportant, // Mendesak & Penting (Kerjakan sekarang)
  q2ImportantNotUrgent, // Penting tapi Tidak Mendesak (Jadwalkan)
  q3UrgentNotImportant, // Mendesak tapi Tidak Penting (Tinjau/Delegasi)
  q4NotUrgentNotImportant, // Tidak Mendesak & Tidak Penting (Eliminasi)
}

class TaskItem {
  final String id;
  final String userId;
  final String? projectId;
  final String title;
  final String? description;
  final String status; // todo, in_progress, completed
  final int priority; // 1: Tinggi, 2: Sedang, 3: Rendah, 4: Tidak Ada
  final bool isImportant;
  final bool isUrgent;
  final DateTime? dueDate;
  final String? recurrenceRule;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Subtask> subtasks;

  TaskItem({
    required this.id,
    required this.userId,
    this.projectId,
    required this.title,
    this.description,
    this.status = 'todo',
    this.priority = 4,
    this.isImportant = false,
    this.isUrgent = false,
    this.dueDate,
    this.recurrenceRule,
    this.completedAt,
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
  });

  bool get isCompleted => status == 'completed';
  bool get hasRecurrence =>
      recurrenceRule != null && recurrenceRule!.trim().isNotEmpty;

  EisenhowerQuadrant get eisenhowerQuadrant {
    if (isImportant && isUrgent) {
      return EisenhowerQuadrant.q1UrgentImportant;
    }
    if (isImportant && !isUrgent) {
      return EisenhowerQuadrant.q2ImportantNotUrgent;
    }
    if (!isImportant && isUrgent) {
      return EisenhowerQuadrant.q3UrgentNotImportant;
    }
    return EisenhowerQuadrant.q4NotUrgentNotImportant;
  }

  String get quadrantLabel {
    switch (eisenhowerQuadrant) {
      case EisenhowerQuadrant.q1UrgentImportant:
        return 'Kuadran I: Mendesak & Penting';
      case EisenhowerQuadrant.q2ImportantNotUrgent:
        return 'Kuadran II: Penting (Rencanakan)';
      case EisenhowerQuadrant.q3UrgentNotImportant:
        return 'Kuadran III: Mendesak (Tinjau)';
      case EisenhowerQuadrant.q4NotUrgentNotImportant:
        return 'Kuadran IV: Santai';
    }
  }

  bool isOverdue(DateTime logicalToday) {
    if (dueDate == null || isCompleted) return false;
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today =
        DateTime(logicalToday.year, logicalToday.month, logicalToday.day);
    return due.isBefore(today);
  }

  bool isDueToday(DateTime logicalToday) {
    if (dueDate == null) return false;
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today =
        DateTime(logicalToday.year, logicalToday.month, logicalToday.day);
    return due.isAtSameMomentAs(today);
  }

  factory TaskItem.fromJson(Map<String, dynamic> json,
      {List<Subtask> subtasks = const []}) {
    return TaskItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'todo',
      priority: json['priority'] as int? ?? 4,
      isImportant: json['is_important'] as bool? ?? false,
      isUrgent: json['is_urgent'] as bool? ?? false,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      recurrenceRule: json['recurrence_rule'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      subtasks: subtasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'is_important': isImportant,
      'is_urgent': isUrgent,
      'due_date': dueDate?.toIso8601String(),
      'recurrence_rule': recurrenceRule,
      'completed_at': completedAt?.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskItem copyWith({
    String? projectId,
    String? title,
    String? description,
    String? status,
    int? priority,
    bool? isImportant,
    bool? isUrgent,
    DateTime? dueDate,
    String? recurrenceRule,
    DateTime? completedAt,
    DateTime? archivedAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
    List<Subtask>? subtasks,
  }) {
    return TaskItem(
      id: id,
      userId: userId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      isImportant: isImportant ?? this.isImportant,
      isUrgent: isUrgent ?? this.isUrgent,
      dueDate: dueDate ?? this.dueDate,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      completedAt: completedAt ?? this.completedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
