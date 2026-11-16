class FinCategory {
  final String id;
  final String userId;
  final String? parentId;
  final String name;
  final String kind; // income, expense
  final String icon;
  final String color;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinCategory({
    required this.id,
    required this.userId,
    this.parentId,
    required this.name,
    this.kind = 'expense',
    this.icon = 'category',
    this.color = '#E53935',
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isIncome => kind == 'income';
  bool get isExpense => kind == 'expense';

  factory FinCategory.fromJson(Map<String, dynamic> json) {
    return FinCategory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      kind: json['kind'] as String? ?? 'expense',
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '#E53935',
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
      'parent_id': parentId,
      'name': name,
      'kind': kind,
      'icon': icon,
      'color': color,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
