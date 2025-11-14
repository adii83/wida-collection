import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static const _defaultUrl = 'https://your-project.supabase.co';
  static const _defaultAnonKey = 'public-anon-key';

  static String get supabaseUrl {
    final envValue = dotenv.env['SUPABASE_URL'];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }
    const dartDefineValue = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: _defaultUrl,
    );
    return dartDefineValue;
  }

  static String get supabaseAnonKey {
    final envValue = dotenv.env['SUPABASE_ANON_KEY'];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }
    const dartDefineValue = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: _defaultAnonKey,
    );
    return dartDefineValue;
  }

  static bool get isConfigured =>
      !supabaseUrl.contains('your-project') &&
      !supabaseAnonKey.contains('public-anon-key');
}
