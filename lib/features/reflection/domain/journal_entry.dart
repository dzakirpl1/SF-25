class JournalEntry {
  final String id;
  final String userId;
  final DateTime entryDate; // Tanggal yyyy-MM-dd
  final String? prompt;
  final String content;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.entryDate,
    this.prompt,
    required this.content,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      entryDate: DateTime.parse(json['entry_date'] as String),
      prompt: json['prompt'] as String?,
      content: json['content'] as String,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final dateStr =
        '${entryDate.year.toString().padLeft(4, '0')}-${entryDate.month.toString().padLeft(2, '0')}-${entryDate.day.toString().padLeft(2, '0')}';
    return {
      'id': id,
      'user_id': userId,
      'entry_date': dateStr,
      'prompt': prompt,
      'content': content,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  JournalEntry copyWith({
    String? prompt,
    String? content,
  }) {
    return JournalEntry(
      id: id,
      userId: userId,
      entryDate: entryDate,
      prompt: prompt ?? this.prompt,
      content: content ?? this.content,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
