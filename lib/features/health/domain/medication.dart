class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final List<String> schedule; // ["08:00", "20:00"]
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    this.schedule = const [],
    this.startDate,
    this.endDate,
    this.active = true,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      schedule: (json['schedule'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      active: json['active'] as bool? ?? true,
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
      'dosage': dosage,
      'schedule': schedule,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'active': active,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Medication copyWith({
    String? name,
    String? dosage,
    List<String>? schedule,
    bool? active,
  }) {
    return Medication(
      id: id,
      userId: userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      schedule: schedule ?? this.schedule,
      startDate: startDate,
      endDate: endDate,
      active: active ?? this.active,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}

class MedicationLog {
  final String id;
  final String userId;
  final String medicationId;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final String status; // 'taken', 'skipped', 'missed'
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationLog({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.scheduledAt,
    this.takenAt,
    this.status = 'taken',
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTaken => status == 'taken';

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      medicationId: json['medication_id'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      takenAt: json['taken_at'] != null
          ? DateTime.parse(json['taken_at'] as String)
          : null,
      status: json['status'] as String? ?? 'taken',
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
      'medication_id': medicationId,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'taken_at': takenAt?.toUtc().toIso8601String(),
      'status': status,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
