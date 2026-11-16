import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';

final projectListProvider = FutureProvider<List<Project>>((ref) async {
  return ref.watch(projectRepositoryProvider).fetchProjects();
});

class ProjectActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ProjectRepository _repo;
  final Ref _ref;

  ProjectActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> createProject({
    required String name,
    String? description,
    String? color,
    DateTime? targetDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createProject(
        name: name,
        description: description,
        color: color,
        targetDate: targetDate,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(projectListProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProject({
    required String id,
    required String name,
    String? description,
    String? status,
    String? color,
    DateTime? targetDate,
    required DateTime lastKnownUpdatedAt,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateProject(
        id: id,
        name: name,
        description: description,
        status: status,
        color: color,
        targetDate: targetDate,
        lastKnownUpdatedAt: lastKnownUpdatedAt,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(projectListProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _repo.softDeleteProject(id);
      _ref.invalidate(projectListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final projectActionsProvider =
    StateNotifierProvider<ProjectActionsNotifier, AsyncValue<void>>((ref) {
  return ProjectActionsNotifier(ref.watch(projectRepositoryProvider), ref);
});
