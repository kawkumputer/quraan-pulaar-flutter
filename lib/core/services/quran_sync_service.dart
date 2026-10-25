import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/quran_snapshot.dart';
import 'activation_api_service.dart';
import 'device_service.dart';
import 'settings_service.dart';

/// Texte du Coran : copie locale (fichier) + synchronisation avec Supabase (quran_sync).
class QuranSyncService extends GetxService {
  static const _fileName = 'quran_cache.json';

  QuranSnapshot _snapshot = QuranSnapshot.empty;
  QuranSnapshot get snapshot => _snapshot;

  Future<File> get _file async =>
      File('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}$_fileName');

  /// Charge la copie locale (aucun accès réseau).
  Future<QuranSnapshot> loadLocal() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final json = await compute(_decode, await file.readAsString());
        _snapshot = QuranSnapshot.fromJson(json);
      }
    } catch (e) {
      debugPrint('Quran cache unreadable, ignored: $e');
      _snapshot = QuranSnapshot.empty;
    }
    return _snapshot;
  }

  static Map<String, dynamic> _decode(String s) => jsonDecode(s) as Map<String, dynamic>;
  static String _encode(Map<String, dynamic> m) => jsonEncode(m);

  Future<void> _save() async {
    try {
      final file = await _file;
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(await compute(_encode, _snapshot.toJson()));
      await tmp.rename(file.path);
    } catch (e) {
      debugPrint('Could not save Quran cache: $e');
    }
  }

  /// Synchronise avec le serveur. Renvoie true si le contenu a changé.
  /// Repart de zéro si l'état d'activation a changé (nouveau contenu payant, ou
  /// contenu payant à retirer après une désactivation).
  Future<bool> sync() async {
    final settings = Get.find<SettingsService>();
    final code = settings.isActivated ? settings.activationCode : '';
    String? uniqueId;
    if (code.isNotEmpty) {
      uniqueId = (await Get.find<DeviceService>().getDeviceInfo()).uniqueId;
    }

    final incremental = !_snapshot.isEmpty && _snapshot.activated == settings.isActivated;
    var response = await _call(uniqueId, code, incremental ? _snapshot.serverTime : null);
    var full = !incremental;

    // Code activé dans l'app mais pas encore rattaché à cet appareil (client d'une
    // version antérieure) : check_device le rattache, puis on recharge.
    if (code.isNotEmpty && response['activated'] != true) {
      final valid = await Get.find<ActivationApiService>().checkDeviceValidity(uniqueId!, code);
      if (valid == true) {
        response = await _call(uniqueId, code, null);
        full = true;
      }
    }

    // L'activation côté serveur diffère de la copie locale : tout recharger.
    if (!full && response['activated'] != _snapshot.activated) {
      response = await _call(uniqueId, code, null);
      full = true;
    }

    final changed = full ||
        (response['verses'] as List? ?? const []).isNotEmpty ||
        (response['surahs'] as List? ?? const []).isNotEmpty;
    _snapshot = _snapshot.apply(response, full: full);
    await _save();
    return changed;
  }

  Future<Map<String, dynamic>> _call(String? uniqueId, String code, DateTime? since) async {
    final result = await Supabase.instance.client.rpc('quran_sync', params: {
      'p_unique_id': uniqueId,
      'p_code': code.isEmpty ? null : code,
      'p_since': since?.toIso8601String(),
    });
    return Map<String, dynamic>.from(result as Map);
  }

  /// Applique localement une correction (mode correcteur), sans attendre la synchro.
  Future<void> applyCorrection(int surah, int verse, String pulaar) async {
    _snapshot = _snapshot.withPulaar(surah, verse, pulaar);
    await _save();
  }
}
