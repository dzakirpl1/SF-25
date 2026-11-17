class PeriodicReview {
  final String id;
  final String userId;
  final String period; // 'daily', 'weekly', 'monthly'
  final DateTime periodStart;
  final Map<String, dynamic> answers; // Pertanyaan & jawaban refleksi
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PeriodicReview({
    required this.id,
    required this.userId,
    required this.period,
    required this.periodStart,
    this.answers = const {},
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get periodLabel {
    switch (period) {
      case 'daily':
        return 'Review Harian';
      case 'weekly':
        return 'Review Mingguan';
      case 'monthly':
        return 'Review Bulanan';
      default:
        return 'Review';
    }
  }

  factory PeriodicReview.fromJson(Map<String, dynamic> json) {
    return PeriodicReview(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      period: json['period'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      answers: (json['answers'] as Map<String, dynamic>?) ?? const {},
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final dateStr =
        '${periodStart.year.toString().padLeft(4, '0')}-${periodStart.month.toString().padLeft(2, '0')}-${periodStart.day.toString().padLeft(2, '0')}';
    return {
      'id': id,
      'user_id': userId,
      'period': period,
      'period_start': dateStr,
      'answers': answers,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
