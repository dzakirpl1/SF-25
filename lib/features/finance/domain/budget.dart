class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final DateTime month; // format yyyy-MM-01
  final BigInt limitAmount;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Properti dinamis yang dihitung dari total pengeluaran kategori di bulan terkait
  final BigInt spentAmount;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.month,
    required this.limitAmount,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    BigInt? spentAmount,
  }) : spentAmount = spentAmount ?? BigInt.zero;

  /// Persentase pemakaian anggaran (0.0 sampai >1.0)
  double get progress {
    if (limitAmount <= BigInt.zero) return 0.0;
    return spentAmount.toDouble() / limitAmount.toDouble();
  }

  /// Sisa nominal anggaran yang masih boleh dibelanjakan
  BigInt get remainingAmount {
    final rem = limitAmount - spentAmount;
    return rem < BigInt.zero ? BigInt.zero : rem;
  }

  /// Nominal kelebihan anggaran bila terlampaui
  BigInt get overAmount {
    final over = spentAmount - limitAmount;
    return over > BigInt.zero ? over : BigInt.zero;
  }

  /// Status peringatan anggaran: 'safe' (<80%), 'warning' (80-99%), 'exceeded' (>=100%)
  String get status {
    if (progress >= 1.0) return 'exceeded';
    if (progress >= 0.8) return 'warning';
    return 'safe';
  }

  bool get isExceeded => status == 'exceeded';
  bool get isWarning => status == 'warning';

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    BigInt? computedSpent,
  }) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      month: DateTime.parse(json['month'] as String),
      limitAmount: BigInt.from(json['limit_amount'] as num),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      spentAmount: computedSpent ?? BigInt.zero,
    );
  }

  Map<String, dynamic> toJson() {
    final monthStr =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01';
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'month': monthStr,
      'limit_amount': limitAmount.toInt(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Budget copyWith({
    String? categoryId,
    DateTime? month,
    BigInt? limitAmount,
    BigInt? spentAmount,
  }) {
    return Budget(
      id: id,
      userId: userId,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      limitAmount: limitAmount ?? this.limitAmount,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }
}
