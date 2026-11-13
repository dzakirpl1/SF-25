import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_repository.dart';
import '../domain/note_category.dart';

final categoryListProvider = AsyncNotifierProvider<CategoryNotifier, List<NoteCategory>>(() {
  return CategoryNotifier();
});

class CategoryNotifier extends AsyncNotifier<List<NoteCategory>> {
  @override
  Future<List<NoteCategory>> build() async {
    return ref.watch(categoryRepositoryProvider).fetchCategories();
  }

  Future<void> addCategory(String name, {String? color}) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(categoryRepositoryProvider).createCategory(name: name, color: color);
      state = AsyncValue.data(await ref.read(categoryRepositoryProvider).fetchCategories());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCategory(String id, String name, {String? color}) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(categoryRepositoryProvider).updateCategory(id: id, name: name, color: color);
      state = AsyncValue.data(await ref.read(categoryRepositoryProvider).fetchCategories());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(id);
      state = AsyncValue.data(await ref.read(categoryRepositoryProvider).fetchCategories());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
