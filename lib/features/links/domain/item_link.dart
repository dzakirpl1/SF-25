class ItemLink {
  final String id;
  final String userId;
  final String sourceType;
  final String sourceId;
  final String targetType;
  final String targetId;
  final DateTime createdAt;

  ItemLink({
    required this.id,
    required this.userId,
    required this.sourceType,
    required this.sourceId,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  factory ItemLink.fromJson(Map<String, dynamic> json) {
    return ItemLink(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceType: json['source_type'] as String,
      sourceId: json['source_id'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'source_type': sourceType,
      'source_id': sourceId,
      'target_type': targetType,
      'target_id': targetId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
