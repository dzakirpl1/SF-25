class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final BigInt targetAmount;
  final DateTime? targetDate;
  final String? walletId;
  final String color;
  final String icon;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Properti dinamis yang dihitung dari total kontribusi/setoran
  final BigInt currentAmount;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.targetDate,
    this.walletId,
    this.color = '#00897B',
    this.icon = 'savings',
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    BigInt? currentAmount,
  }) : currentAmount = currentAmount ?? BigInt.zero;

  /// Persentase progres pencapaian target (0.0 sampai 1.0)
  double get progress {
    if (targetAmount <= BigInt.zero) return 0.0;
    final p = currentAmount.toDouble() / targetAmount.toDouble();
    return p > 1.0 ? 1.0 : p;
  }

  /// Sisa nominal yang dibutuhkan untuk mencapai target
  BigInt get remainingAmount {
    final rem = targetAmount - currentAmount;
    return rem < BigInt.zero ? BigInt.zero : rem;
  }

  /// Apakah target tabungan sudah tercapai penuh
  bool get isCompleted => currentAmount >= targetAmount;

  factory SavingsGoal.fromJson(
    Map<String, dynamic> json, {
    BigInt? computedCurrent,
  }) {
    return SavingsGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      targetAmount: BigInt.from(json['target_amount'] as num),
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      walletId: json['wallet_id'] as String?,
      color: json['color'] as String? ?? '#00897B',
      icon: json['icon'] as String? ?? 'savings',
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      currentAmount: computedCurrent ?? BigInt.zero,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount.toInt(),
      'target_date': targetDate?.toIso8601String().split('T').first,
      'wallet_id': walletId,
      'color': color,
      'icon': icon,
      'archived_at': archivedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  SavingsGoal copyWith({
    String? name,
    BigInt? targetAmount,
    DateTime? targetDate,
    String? walletId,
    String? color,
    String? icon,
    DateTime? archivedAt,
    BigInt? currentAmount,
  }) {
    return SavingsGoal(
      id: id,
      userId: userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      walletId: walletId ?? this.walletId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      currentAmount: currentAmount ?? this.currentAmount,
    );
  }
}

class SavingsContribution {
  final String id;
  final String userId;
  final String goalId;
  final BigInt amount;
  final DateTime contributedAt;
  final String? transactionId;
  final String? note;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsContribution({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.amount,
    required this.contributedAt,
    this.transactionId,
    this.note,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavingsContribution.fromJson(Map<String, dynamic> json) {
    return SavingsContribution(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalId: json['goal_id'] as String,
      amount: BigInt.from(json['amount'] as num),
      contributedAt: DateTime.parse(json['contributed_at'] as String),
      transactionId: json['transaction_id'] as String?,
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
      'goal_id': goalId,
      'amount': amount.toInt(),
      'contributed_at': contributedAt.toUtc().toIso8601String(),
      'transaction_id': transactionId,
      'note': note,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
