class SleepLog {
  final String id;
  final String userId;
  final DateTime sleepAt;
  final DateTime wakeAt;
  final int quality; // 1 s.d. 5
  final String? note;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SleepLog({
    required this.id,
    required this.userId,
    required this.sleepAt,
    required this.wakeAt,
    required this.quality,
    this.note,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Durasi tidur dalam jam dan menit
  Duration get duration => wakeAt.difference(sleepAt);

  String get formattedDuration {
    final d = duration;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}j ${m}m';
  }

  String get qualityLabel {
    switch (quality) {
      case 5:
        return 'Sangat Nyenyak';
      case 4:
        return 'Nyenyak';
      case 3:
        return 'Cukup';
      case 2:
        return 'Kurang';
      case 1:
        return 'Buruk';
      default:
        return 'Cukup';
    }
  }

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sleepAt: DateTime.parse(json['sleep_at'] as String),
      wakeAt: DateTime.parse(json['wake_at'] as String),
      quality: json['quality'] as int? ?? 3,
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
      'sleep_at': sleepAt.toUtc().toIso8601String(),
      'wake_at': wakeAt.toUtc().toIso8601String(),
      'quality': quality,
      'note': note,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
