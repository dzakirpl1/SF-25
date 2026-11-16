class Reminder {
  final String id;
  final String userId;
  final String title;
  final String? body;
  final String targetType; // task, event, medicine, document, day, custom
  final String? targetId;
  final DateTime remindAt;
  final String status; // scheduled, sent, snoozed, dismissed
  final DateTime? snoozedUntil;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.targetType = 'custom',
    this.targetId,
    required this.remindAt,
    this.status = 'scheduled',
    this.snoozedUntil,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isScheduled => status == 'scheduled';
  bool get isSnoozed => status == 'snoozed';
  bool get isDismissed => status == 'dismissed';

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      targetType: json['target_type'] as String? ?? 'custom',
      targetId: json['target_id'] as String?,
      remindAt: DateTime.parse(json['remind_at'] as String),
      status: json['status'] as String? ?? 'scheduled',
      snoozedUntil: json['snoozed_until'] != null
          ? DateTime.parse(json['snoozed_until'] as String)
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
      'body': body,
      'target_type': targetType,
      'target_id': targetId,
      'remind_at': remindAt.toUtc().toIso8601String(),
      'status': status,
      'snoozed_until': snoozedUntil?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
