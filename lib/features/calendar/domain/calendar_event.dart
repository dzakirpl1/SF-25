import '../../../core/recurrence/recurrence_engine.dart';

class CalendarEvent {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool allDay;
  final String? location;
  final String color;
  final String? recurrenceRule;
  final String? linkedTaskId;
  final bool isTimeBlock;
  final String? externalId;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
    this.allDay = false,
    this.location,
    this.color = '#1976D2',
    this.recurrenceRule,
    this.linkedTaskId,
    this.isTimeBlock = false,
    this.externalId,
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isArchived => archivedAt != null;
  bool get hasRecurrence =>
      recurrenceRule != null && recurrenceRule!.trim().isNotEmpty;

  /// Durasi acara
  Duration get duration => endsAt.difference(startsAt);

  /// Menghasilkan daftar kemunculan (instances) yang jatuh dalam rentang [rangeStart] s.d. [rangeEnd]
  List<EventOccurrence> expandForRange(DateTime rangeStart, DateTime rangeEnd) {
    return RecurrenceEngine.expandEventOccurrences(
      id: id,
      title: title,
      description: description,
      startsAt: startsAt,
      endsAt: endsAt,
      allDay: allDay,
      location: location,
      color: color,
      recurrenceRule: recurrenceRule,
      isTimeBlock: isTimeBlock,
      linkedTaskId: linkedTaskId,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      allDay: json['all_day'] as bool? ?? false,
      location: json['location'] as String?,
      color: json['color'] as String? ?? '#1976D2',
      recurrenceRule: json['recurrence_rule'] as String?,
      linkedTaskId: json['linked_task_id'] as String?,
      isTimeBlock: json['is_time_block'] as bool? ?? false,
      externalId: json['external_id'] as String?,
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
      'title': title,
      'description': description,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'all_day': allDay,
      'location': location,
      'color': color,
      'recurrence_rule': recurrenceRule,
      'linked_task_id': linkedTaskId,
      'is_time_block': isTimeBlock,
      'external_id': externalId,
      'archived_at': archivedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  CalendarEvent copyWith({
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? allDay,
    String? location,
    String? color,
    String? recurrenceRule,
    String? linkedTaskId,
    bool? isTimeBlock,
    String? externalId,
    DateTime? archivedAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      color: color ?? this.color,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      isTimeBlock: isTimeBlock ?? this.isTimeBlock,
      externalId: externalId ?? this.externalId,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
