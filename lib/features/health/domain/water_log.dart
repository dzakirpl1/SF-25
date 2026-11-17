class WaterLog {
  final String id;
  final String userId;
  final DateTime loggedAt;
  final int amountMl;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WaterLog({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.amountMl,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WaterLog.fromJson(Map<String, dynamic> json) {
    return WaterLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      amountMl: json['amount_ml'] as int? ?? 0,
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
      'logged_at': loggedAt.toUtc().toIso8601String(),
      'amount_ml': amountMl,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
