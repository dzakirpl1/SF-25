class Debt {
  final String id;
  final String userId;
  final String personName;
  final String? personId;
  final String
      direction; // 'owed_by_me' (utang saya), 'owed_to_me' (piutang saya)
  final BigInt principal;
  final DateTime? dueDate;
  final String? note;
  final DateTime? settledAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Properti dinamis yang dihitung dari total pembayaran cicilan
  final BigInt paidAmount;

  Debt({
    required this.id,
    required this.userId,
    required this.personName,
    this.personId,
    required this.direction,
    required this.principal,
    this.dueDate,
    this.note,
    this.settledAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    BigInt? paidAmount,
  }) : paidAmount = paidAmount ?? BigInt.zero;

  /// Apakah ini utang saya ke orang lain
  bool get isOwedByMe => direction == 'owed_by_me';

  /// Apakah ini piutang (orang lain berutang ke saya)
  bool get isOwedToMe => direction == 'owed_to_me';

  /// Sisa nominal yang belum dilunasi
  BigInt get remainingAmount {
    final rem = principal - paidAmount;
    return rem < BigInt.zero ? BigInt.zero : rem;
  }

  /// Apakah sudah lunas
  bool get isSettled => settledAt != null || remainingAmount <= BigInt.zero;

  /// Persentase pelunasan (0.0 sampai 1.0)
  double get progress {
    if (principal <= BigInt.zero) return 1.0;
    final p = paidAmount.toDouble() / principal.toDouble();
    return p > 1.0 ? 1.0 : p;
  }

  factory Debt.fromJson(
    Map<String, dynamic> json, {
    BigInt? computedPaid,
  }) {
    return Debt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      personName: json['person_name'] as String,
      personId: json['person_id'] as String?,
      direction: json['direction'] as String,
      principal: BigInt.from(json['principal'] as num),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      note: json['note'] as String?,
      settledAt: json['settled_at'] != null
          ? DateTime.parse(json['settled_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      paidAmount: computedPaid ?? BigInt.zero,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'person_name': personName,
      'person_id': personId,
      'direction': direction,
      'principal': principal.toInt(),
      'due_date': dueDate?.toIso8601String().split('T').first,
      'note': note,
      'settled_at': settledAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Debt copyWith({
    String? personName,
    String? personId,
    String? direction,
    BigInt? principal,
    DateTime? dueDate,
    String? note,
    DateTime? settledAt,
    BigInt? paidAmount,
  }) {
    return Debt(
      id: id,
      userId: userId,
      personName: personName ?? this.personName,
      personId: personId ?? this.personId,
      direction: direction ?? this.direction,
      principal: principal ?? this.principal,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      settledAt: settledAt ?? this.settledAt,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }
}

class DebtPayment {
  final String id;
  final String userId;
  final String debtId;
  final BigInt amount;
  final DateTime paidAt;
  final String? transactionId;
  final String? note;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DebtPayment({
    required this.id,
    required this.userId,
    required this.debtId,
    required this.amount,
    required this.paidAt,
    this.transactionId,
    this.note,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      debtId: json['debt_id'] as String,
      amount: BigInt.from(json['amount'] as num),
      paidAt: DateTime.parse(json['paid_at'] as String),
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
      'debt_id': debtId,
      'amount': amount.toInt(),
      'paid_at': paidAt.toUtc().toIso8601String(),
      'transaction_id': transactionId,
      'note': note,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
