import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quran_service.dart';

/// Mode correcteur : réservé aux comptes admin (Abou Sy, le développeur).
/// Permet de corriger la traduction pulaar d'un verset directement dans l'app.
class CorrectorService extends GetxService {
  final isCorrector = false.obs;
  final email = RxnString();
  StreamSubscription<AuthState>? _authSub;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    _refresh();
    _authSub = _client.auth.onAuthStateChange.listen((_) => _refresh());
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  Future<void> _refresh() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      isCorrector.value = false;
      email.value = null;
      return;
    }
    try {
      isCorrector.value = await _client.rpc('is_admin') == true;
      email.value = user.email;
    } catch (e) {
      debugPrint('is_admin check failed: $e');
    }
  }

  /// Connexion ; renvoie un message d'erreur, ou null si c'est réussi.
  Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException {
      return 'Email ou mot de passe incorrect.';
    } catch (e) {
      return 'Connexion impossible (réseau ?).';
    }
    await _refresh();
    if (!isCorrector.value) {
      await _client.auth.signOut();
      return "Ce compte n'a pas accès au mode correcteur.";
    }
    return null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _refresh();
  }

  /// Corrige la traduction d'un verset ; renvoie un message d'erreur, ou null.
  Future<String?> correct(int surah, int verse, String pulaar) async {
    final text = pulaar.replaceAll(RegExp(r'\s+'), ' ').trim();
    try {
      final rows = await _client
          .from('quran_verses')
          .update({'pulaar': text})
          .eq('surah_number', surah)
          .eq('number', verse)
          .select('number');
      if ((rows as List).isEmpty) return "La correction n'a pas été enregistrée (droits ?).";
    } catch (e) {
      debugPrint('Verse correction failed: $e');
      return 'Enregistrement impossible. Vérifiez la connexion.';
    }
    await Get.find<QuranService>().applyCorrection(surah, verse, text);
    return null;
  }
}
