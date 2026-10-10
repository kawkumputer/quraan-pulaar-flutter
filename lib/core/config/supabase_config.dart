import 'package:supabase_flutter/supabase_flutter.dart';

// Clé "publishable" (ex-anon) : publique par conception, elle ne donne accès
// qu'aux RPC activate_code et check_device (voir supabase/migrations/001_init.sql).
// Dashboard Supabase > Project Settings > API.
const String supabaseUrl = 'https://aruetqtlcdoabgukpjcz.supabase.co';
const String supabasePublishableKey = 'sb_publishable_jy4F5N2HVy_HuBEGXLmGxg_tSNk7yKX';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}
