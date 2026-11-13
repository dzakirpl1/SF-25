class Note {
  final String id;
  final String userId;
  final String? categoryId;
  final String? title;
  final String content;
  final bool isPinned;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    this.categoryId,
    this.title,
    required this.content,
    this.isPinned = false,
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isArchived => archivedAt != null;
  bool get isDeleted => deletedAt != null;

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    // Jika tanpa judul (Quick Capture), ambil baris pertama isi
    final lines = content.trim().split('\n');
    if (lines.isNotEmpty && lines.first.trim().isNotEmpty) {
      final firstLine = lines.first.trim();
      return firstLine.length > 40 ? '${firstLine.substring(0, 40)}...' : firstLine;
    }
    return 'Catatan Tanpa Judul';
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
      archivedAt: json['archived_at'] != null ? DateTime.parse(json['archived_at'] as String) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      'archived_at': archivedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Note copyWith({
    String? categoryId,
    String? title,
    String? content,
    bool? isPinned,
    DateTime? archivedAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      userId: userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
