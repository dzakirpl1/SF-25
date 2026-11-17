class MoodLog {
  final String id;
  final String userId;
  final DateTime logDate; // yyyy-MM-dd
  final int score; // 1 s.d. 5
  final List<String> tags;
  final String? note;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MoodLog({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.score,
    this.tags = const [],
    this.note,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get moodLabel {
    switch (score) {
      case 5:
        return 'Luar Biasa';
      case 4:
        return 'Baik';
      case 3:
        return 'Biasa Saja';
      case 2:
        return 'Kurang Baik';
      case 1:
        return 'Sangat Buruk';
      default:
        return 'Netral';
    }
  }

  String get moodEmoji {
    switch (score) {
      case 5:
        return '😄';
      case 4:
        return '🙂';
      case 3:
        return '😐';
      case 2:
        return '🙁';
      case 1:
        return '😢';
      default:
        return '😐';
    }
  }

  factory MoodLog.fromJson(Map<String, dynamic> json) {
    return MoodLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      score: json['score'] as int? ?? 3,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              const [],
      note: json['note'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final dateStr =
        '${logDate.year.toString().padLeft(4, '0')}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';
    return {
      'id': id,
      'user_id': userId,
      'log_date': dateStr,
      'score': score,
      'tags': tags,
      'note': note,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  MoodLog copyWith({
    int? score,
    List<String>? tags,
    String? note,
  }) {
    return MoodLog(
      id: id,
      userId: userId,
      logDate: logDate,
      score: score ?? this.score,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
