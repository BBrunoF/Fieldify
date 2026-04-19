import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://jdmnvmqkmthjllckzlmp.supabase.co';
const supabaseAnonKey = 'sb_publishable_GbzZ4mVffFIIYoKW0vjqDQ_eNoI5Ixo';

/// Single shared Supabase client accessor.
final supabase = Supabase.instance.client;

Future<void> initializeSupabase() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}
