class SupabaseConfig {
  static const String defaultUrl = 'https://zvbixisduvvadtvnhzla.supabase.co';
  static const String defaultAnonKey = 'sb_publishable_eYjEwW2R3dj2cHDbIl9G_g_sYGUvTcx';

  static String get url {
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    return fromEnv.isNotEmpty ? fromEnv : defaultUrl;
  }

  static String get anonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    return fromEnv.isNotEmpty ? fromEnv : defaultAnonKey;
  }
}
