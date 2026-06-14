import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 配置 — 后续你可以换成自己的 Supabase 项目。
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY';
}

/// 初始化 Supabase。
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
  );
}
