import 'package:test/test.dart';
import 'package:personal_os/features/notes/domain/note.dart';

void main() {
  group('Note Model Tests', () {
    test('displayTitle menggunakan judul jika tersedia', () {
      final note = Note(
        id: '1',
        userId: 'u1',
        title: 'Catatan Rapat',
        content: 'Isi rapat koordinasi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.displayTitle, 'Catatan Rapat');
    });

    test('displayTitle menggunakan baris pertama konten jika judul null (Quick Capture)', () {
      final note = Note(
        id: '2',
        userId: 'u1',
        title: null,
        content: 'Beli susu di supermarket\nJangan lupa telur',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.displayTitle, 'Beli susu di supermarket');
    });

    test('isArchived dan isDeleted mengenali stempel waktu', () {
      final now = DateTime.now();
      final note = Note(
        id: '3',
        userId: 'u1',
        content: 'Catatan terhapus',
        deletedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(note.isDeleted, isTrue);
      expect(note.isArchived, isFalse);
    });

    test('Serialization JSON bolak-balik valid', () {
      final now = DateTime.utc(2026, 11, 12, 12, 0);
      final json = {
        'id': 'abc-123',
        'user_id': 'usr-456',
        'category_id': null,
        'title': 'Test Title',
        'content': 'Test Content',
        'is_pinned': true,
        'archived_at': null,
        'deleted_at': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final note = Note.fromJson(json);
      expect(note.id, 'abc-123');
      expect(note.isPinned, isTrue);
      expect(note.toJson()['title'], 'Test Title');
    });
  });
}
