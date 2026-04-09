class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.enableRemoteSync,
    required this.useSupabaseAnonymousAuth,
    required this.supabaseReportsTable,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableRemoteSync;
  final bool useSupabaseAnonymousAuth;
  final String supabaseReportsTable;

  bool get canUseSupabase =>
      enableRemoteSync &&
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty;

  static AppConfig fromEnvironment() {
    return AppConfig(
      supabaseUrl: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      ),
      supabaseAnonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      ),
      enableRemoteSync: _parseBool(
        const String.fromEnvironment(
          'ENABLE_SUPABASE_SYNC',
          defaultValue: 'false',
        ),
      ),
      useSupabaseAnonymousAuth: _parseBool(
        const String.fromEnvironment(
          'ENABLE_SUPABASE_ANON_AUTH',
          defaultValue: 'true',
        ),
      ),
      supabaseReportsTable: const String.fromEnvironment(
        'SUPABASE_REPORTS_TABLE',
        defaultValue: 'maintenance_reports',
      ),
    );
  }

  static bool _parseBool(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      default:
        return false;
    }
  }
}
