import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final ephemeralDraftServiceProvider = Provider<EphemeralDraftService>((ref) {
  return EphemeralDraftService(const FlutterSecureStorage());
});

class EphemeralDraftService {
  final FlutterSecureStorage _storage;
  static const _draftPrefix = 'draft_temp_';

  EphemeralDraftService(this._storage);

  Future<void> saveDraft(String key, Map<String, dynamic> data) async {
    try {
      final jsonStr = jsonEncode(data);
      await _storage.write(key: '$_draftPrefix$key', value: jsonStr);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getDraft(String key) async {
    try {
      final jsonStr = await _storage.read(key: '$_draftPrefix$key');
      if (jsonStr == null || jsonStr.isEmpty) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft(String key) async {
    try {
      await _storage.delete(key: '$_draftPrefix$key');
    } catch (_) {}
  }
}
