import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://ybymvlwkftcopukpsder.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlieW12bHdrZnRjb3B1a3BzZGVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE0MTQ0NDAsImV4cCI6MjA5Njk5MDQ0MH0.U8Z38CKHcw4HIEDAzexCsjcUPY3sxU34woFuuCY3fus';
}

Future<void> initSupabase() async {
  await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
}
