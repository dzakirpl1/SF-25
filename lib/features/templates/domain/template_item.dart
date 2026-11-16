class TemplateItem {
  final String id;
  final String userId;
  final String type; // note, task_list, shopping, checklist, trip
  final String name;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;

  TemplateItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TemplateItem.fromJson(Map<String, dynamic> json) {
    return TemplateItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'note',
      name: json['name'] as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'name': name,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
