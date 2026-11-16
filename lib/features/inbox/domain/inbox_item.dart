class InboxItem {
  final String id;
  final String userId;
  final String content;
  final String source; // manual, share, voice, widget
  final DateTime? processedAt;
  final String? convertedType; // note, task, event, transaction
  final String? convertedId;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  InboxItem({
    required this.id,
    required this.userId,
    required this.content,
    this.source = 'manual',
    this.processedAt,
    this.convertedType,
    this.convertedId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isProcessed => processedAt != null;

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    return InboxItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      source: json['source'] as String? ?? 'manual',
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      convertedType: json['converted_type'] as String?,
      convertedId: json['converted_id'] as String?,
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
      'content': content,
      'source': source,
      'processed_at': processedAt?.toIso8601String(),
      'converted_type': convertedType,
      'converted_id': convertedId,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
