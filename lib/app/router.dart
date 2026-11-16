import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/services/app_lock_service.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/app_lock_screen.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/calendar/domain/calendar_event.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/calendar/presentation/event_editor_screen.dart';
import '../features/categories/presentation/category_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/modules_grid_screen.dart';
import '../features/notes/domain/note.dart';
import '../features/notes/presentation/note_editor_screen.dart';
import '../features/notes/presentation/note_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/projects/presentation/project_list_screen.dart';
import '../features/tasks/domain/task.dart';
import '../features/tasks/presentation/task_editor_screen.dart';
import '../features/tasks/presentation/task_list_screen.dart';
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/trash/presentation/trash_screen.dart';
import '../features/habits/domain/habit.dart';
import '../features/habits/domain/routine.dart';
import '../features/habits/presentation/habits_screen.dart';
import '../features/habits/presentation/habit_editor_screen.dart';
import '../features/habits/presentation/routine_editor_screen.dart';
import '../features/reminders/presentation/reminders_screen.dart';
import 'shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isLocked = ref.watch(isAppLockedProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final session = authState.value?.session ??
          ref.read(authRepositoryProvider).currentUser;
      final isLoggedIn = session != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isLockScreen = state.matchedLocation == '/app-lock';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }
      if (isLoggedIn && isLocked && !isLockScreen) {
        return '/app-lock';
      }
      if (isLoggedIn && !isLocked && isLockScreen) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/app-lock',
        builder: (context, state) => AppLockScreen(
          onUnlocked: () => context.go('/home'),
        ),
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
                builder: (context, state) => const TaskListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
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
        path: '/tasks/edit',
        builder: (context, state) {
          final task = state.extra as TaskItem?;
          return TaskEditorScreen(initialTask: task);
        },
      ),
      GoRoute(
        path: '/calendar/event/edit',
        builder: (context, state) {
          final event = state.extra as CalendarEvent?;
          return EventEditorScreen(initialEvent: event);
        },
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: '/trash',
        builder: (context, state) => const TrashScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/habits',
        builder: (context, state) => const HabitsScreen(),
      ),
      GoRoute(
        path: '/habits/edit',
        builder: (context, state) {
          final habit = state.extra as Habit?;
          return HabitEditorScreen(initialHabit: habit);
        },
      ),
      GoRoute(
        path: '/routines/edit',
        builder: (context, state) {
          final routine = state.extra as Routine?;
          return RoutineEditorScreen(initialRoutine: routine);
        },
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
    ],
  );
});
