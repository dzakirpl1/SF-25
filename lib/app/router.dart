import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/notes/domain/note.dart';
import '../features/notes/presentation/note_list_screen.dart';
import '../features/notes/presentation/note_editor_screen.dart';
import '../features/categories/presentation/category_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks_placeholder_screen.dart';
import '../features/calendar_placeholder_screen.dart';
import '../features/modules_grid_screen.dart';
import 'shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final session = authState.value?.session ?? ref.read(authRepositoryProvider).currentUser;
      final isLoggedIn = session != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NoteListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/modules',
                builder: (context, state) => const ModulesGridScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/notes/edit',
        builder: (context, state) {
          final note = state.extra as Note?;
          return NoteEditorScreen(initialNote: note);
        },
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
