class TransactionItem {
  final String id;
  final String userId;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final String type; // income, expense, transfer
  final BigInt amount;
  final DateTime occurredAt;
  final String? note;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionItem({
    required this.id,
    required this.userId,
    required this.walletId,
    this.toWalletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.occurredAt,
    this.note,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isTransfer => type == 'transfer';

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      walletId: json['wallet_id'] as String,
      toWalletId: json['to_wallet_id'] as String?,
      categoryId: json['category_id'] as String?,
      type: json['type'] as String,
      amount: BigInt.from(json['amount'] as num),
      occurredAt: DateTime.parse(json['occurred_at'] as String),
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
      'wallet_id': walletId,
      'to_wallet_id': toWalletId,
      'category_id': categoryId,
      'type': type,
      'amount': amount.toInt(),
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'note': note,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
