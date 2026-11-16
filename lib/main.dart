import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/router.dart';
import 'core/config/supabase_config.dart';
import 'core/services/app_lock_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: PersonalOsApp()));
}

class PersonalOsApp extends ConsumerStatefulWidget {
  const PersonalOsApp({super.key});

  @override
  ConsumerState<PersonalOsApp> createState() => _PersonalOsAppState();
}

class _PersonalOsAppState extends ConsumerState<PersonalOsApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  void _checkInitialLock() async {
    final lockService = ref.read(appLockServiceProvider);
    final hasPin = await lockService.isPinSet();
    if (hasPin) {
      ref.read(isAppLockedProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final lockService = ref.read(appLockServiceProvider);
    if (state == AppLifecycleState.paused) {
      await lockService.recordAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      final settings =
          await ref.read(settingsRepositoryProvider).fetchSettings();
      if (settings != null && settings.pinEnabled) {
        final shouldLock =
            await lockService.shouldLockOnResume(settings.lockTimeoutMinutes);
        if (shouldLock) {
          ref.read(isAppLockedProvider.notifier).state = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settingsAsync = ref.watch(userSettingsProvider);
    final themeModeStr = settingsAsync.value?.theme ?? 'system';

    final themeMode = themeModeStr == 'light'
        ? ThemeMode.light
        : (themeModeStr == 'dark' ? ThemeMode.dark : ThemeMode.system);

    return MaterialApp.router(
      title: 'Personal OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      locale: const Locale('id', 'ID'),
    );
  }
}
