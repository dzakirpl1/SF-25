class Wallet {
  final String id;
  final String userId;
  final String name;
  final String type; // cash, bank, ewallet, other
  final BigInt initialBalance;
  final String color;
  final String icon;
  final BigInt currentBalance;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.name,
    this.type = 'cash',
    required this.initialBalance,
    this.color = '#00796B',
    this.icon = 'account_balance_wallet',
    required this.currentBalance,
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json,
      {BigInt? computedBalance}) {
    final init = BigInt.from(json['initial_balance'] as num? ?? 0);
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'cash',
      initialBalance: init,
      color: json['color'] as String? ?? '#00796B',
      icon: json['icon'] as String? ?? 'account_balance_wallet',
      currentBalance: computedBalance ?? init,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
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
      'name': name,
      'type': type,
      'initial_balance': initialBalance.toInt(),
      'color': color,
      'icon': icon,
      'archived_at': archivedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Wallet copyWith({
    String? name,
    String? type,
    BigInt? initialBalance,
    String? color,
    String? icon,
    BigInt? currentBalance,
    DateTime? archivedAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      currentBalance: currentBalance ?? this.currentBalance,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
