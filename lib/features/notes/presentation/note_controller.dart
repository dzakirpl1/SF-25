import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/note_repository.dart';
import '../domain/note.dart';

class NoteFilter {
  final String? categoryId;
  final String? searchQuery;
  final bool includeArchived;

  const NoteFilter({
    this.categoryId,
    this.searchQuery,
    this.includeArchived = false,
  });

  NoteFilter copyWith({
    String? categoryId,
    String? searchQuery,
    bool? includeArchived,
    bool clearCategory = false,
  }) {
    return NoteFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      includeArchived: includeArchived ?? this.includeArchived,
    );
  }
}

final noteFilterProvider = StateProvider<NoteFilter>((ref) {
  return const NoteFilter();
});

final noteListProvider = FutureProvider<List<Note>>((ref) async {
  final filter = ref.watch(noteFilterProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.fetchNotes(
    categoryId: filter.categoryId,
    searchQuery: filter.searchQuery,
    includeArchived: filter.includeArchived,
  );
});

final recentNotesProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  final all = await repo.fetchNotes();
  return all.take(5).toList();
});

class NoteActionsController extends StateNotifier<AsyncValue<void>> {
  final NoteRepository _repo;
  final Ref _ref;

  NoteActionsController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> createNote({
    String? title,
    required String content,
    String? categoryId,
    bool isPinned = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createNote(
        title: title,
        content: content,
        categoryId: categoryId,
        isPinned: isPinned,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(noteListProvider);
      _ref.invalidate(recentNotesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateNote({
    required String id,
    String? title,
    required String content,
    String? categoryId,
    bool? isPinned,
    required DateTime lastKnownUpdatedAt,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateNote(
        id: id,
        title: title,
        content: content,
        categoryId: categoryId,
        isPinned: isPinned,
        lastKnownUpdatedAt: lastKnownUpdatedAt,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(noteListProvider);
      _ref.invalidate(recentNotesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> togglePin(String id, bool currentPin) async {
    try {
      await _repo.togglePin(id, currentPin);
      _ref.invalidate(noteListProvider);
      _ref.invalidate(recentNotesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleArchive(String id, bool currentlyArchived) async {
    try {
      await _repo.toggleArchive(id, currentlyArchived);
      _ref.invalidate(noteListProvider);
      _ref.invalidate(recentNotesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await _repo.softDelete(id);
      _ref.invalidate(noteListProvider);
      _ref.invalidate(recentNotesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final noteActionsProvider = StateNotifierProvider<NoteActionsController, AsyncValue<void>>((ref) {
  return NoteActionsController(ref.watch(noteRepositoryProvider), ref);
});
