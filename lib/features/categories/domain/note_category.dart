class NoteCategory {
  final String id;
  final String userId;
  final String name;
  final String? color;
  final DateTime createdAt;

  NoteCategory({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    required this.createdAt,
  });

  factory NoteCategory.fromJson(Map<String, dynamic> json) {
    return NoteCategory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
