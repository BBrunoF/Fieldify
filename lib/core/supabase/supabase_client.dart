import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

/// Single shared Supabase client accessor.
final supabase = Supabase.instance.client;

Future<void> initializeSupabase() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}
