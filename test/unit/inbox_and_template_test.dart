import 'package:personal_os/features/inbox/domain/inbox_item.dart';
import 'package:personal_os/features/links/domain/item_link.dart';
import 'package:personal_os/features/templates/domain/template_item.dart';
import 'package:test/test.dart';

void main() {
  group('InboxItem Domain Tests', () {
    test('Serialisasi JSON dan status isProcessed', () {
      final now = DateTime.utc(2026, 11, 13, 12, 0);
      final item = InboxItem(
        id: 'inbox-1',
        userId: 'user-1',
        content: 'Beli buku arsitektur',
        source: 'quick_capture',
        createdAt: now,
        updatedAt: now,
      );

      expect(item.isProcessed, isFalse);
      expect(item.source, 'quick_capture');

      final json = item.toJson();
      final revived = InboxItem.fromJson(json);

      expect(revived.id, 'inbox-1');
      expect(revived.content, 'Beli buku arsitektur');
    });

    test('Item yang sudah dipilah terdeteksi isProcessed', () {
      final now = DateTime.now();
      final item = InboxItem(
        id: 'inbox-2',
        userId: 'user-1',
        content: 'Selesaikan sprint',
        processedAt: now,
        convertedType: 'task',
        convertedId: 'task-123',
        createdAt: now,
        updatedAt: now,
      );

      expect(item.isProcessed, isTrue);
      expect(item.convertedType, 'task');
      expect(item.convertedId, 'task-123');
    });
  });

  group('TemplateItem Domain Tests', () {
    test('Template dengan payload jsonb tervaluasi dengan benar', () {
      final now = DateTime.utc(2026, 11, 13, 12, 0);
      final template = TemplateItem(
        id: 'tpl-1',
        userId: 'user-1',
        type: 'note',
        name: 'Catatan Rapat',
        payload: {
          'title': 'Rapat Proyek',
          'content': '### Agenda\n- [ ] Pembahasan',
        },
        createdAt: now,
        updatedAt: now,
      );

      expect(template.payload['title'], 'Rapat Proyek');
      expect(template.type, 'note');

      final json = template.toJson();
      final revived = TemplateItem.fromJson(json);

      expect(revived.name, 'Catatan Rapat');
      expect(revived.payload['content'], contains('Agenda'));
    });
  });

  group('ItemLink Domain Tests', () {
    test('Relasi polimorfik serialisasi tepat', () {
      final now = DateTime.utc(2026, 11, 13, 12, 0);
      final link = ItemLink(
        id: 'lnk-1',
        userId: 'user-1',
        sourceType: 'note',
        sourceId: 'note-100',
        targetType: 'task',
        targetId: 'task-200',
        createdAt: now,
      );

      expect(link.sourceType, 'note');
      expect(link.targetType, 'task');

      final json = link.toJson();
      final revived = ItemLink.fromJson(json);
      expect(revived.sourceId, 'note-100');
      expect(revived.targetId, 'task-200');
    });
  });
}
