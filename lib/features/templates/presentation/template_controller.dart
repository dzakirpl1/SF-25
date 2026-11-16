import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/template_repository.dart';
import '../domain/template_item.dart';

final templateListProvider =
    FutureProvider.family<List<TemplateItem>, String?>((ref, type) async {
  return ref.watch(templateRepositoryProvider).fetchTemplates(type: type);
});

class TemplateActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final TemplateRepository _repo;
  final Ref _ref;

  TemplateActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> createTemplate({
    required String name,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createTemplate(name: name, type: type, payload: payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(templateListProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _repo.deleteTemplate(id);
      _ref.invalidate(templateListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final templateActionsProvider =
    StateNotifierProvider<TemplateActionsNotifier, AsyncValue<void>>((ref) {
  return TemplateActionsNotifier(ref.watch(templateRepositoryProvider), ref);
});
