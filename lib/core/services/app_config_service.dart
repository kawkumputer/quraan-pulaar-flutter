import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../constants/strings.dart';
import '../utils/version.dart';

/// Version minimale / dernière version publiées dans Supabase (table app_config).
/// Permet de forcer la mise à jour lors d'une future migration.
class AppConfigService extends GetxService {
  static const _lastOptionalPromptKey = 'last_update_prompt';
  static const _optionalPromptInterval = Duration(days: 7);

  /// À appeler une fois l'accueil affiché. Toute erreur (hors ligne, etc.) est ignorée.
  Future<void> checkForUpdate() async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final installed = (await PackageInfo.fromPlatform()).version;
      final config = await Supabase.instance.client
          .rpc('get_app_config', params: {'p_platform': platform})
          .timeout(const Duration(seconds: 5));
      if (config is! Map) return;

      final minVersion = config['min_version'] as String?;
      final latestVersion = config['latest_version'] as String?;
      final storeUrl = (config['store_url'] as String?) ??
          (Platform.isIOS ? kAppStoreUrl : kPlayStoreUrl);
      final message = config['message'] as String?;

      if (minVersion != null && compareVersions(installed, minVersion) < 0) {
        await _showDialog(storeUrl, message ?? S.updateRequired, blocking: true);
      } else if (latestVersion != null &&
          compareVersions(installed, latestVersion) < 0 &&
          await _optionalPromptDue()) {
        await _showDialog(storeUrl, message ?? S.updateAvailable, blocking: false);
      }
    } catch (e) {
      debugPrint('App config check skipped: $e');
    }
  }

  Future<bool> _optionalPromptDue() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastOptionalPromptKey);
    if (last != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)) <
            _optionalPromptInterval) {
      return false;
    }
    await prefs.setInt(_lastOptionalPromptKey, DateTime.now().millisecondsSinceEpoch);
    return true;
  }

  Future<void> _showDialog(String storeUrl, String message, {required bool blocking}) {
    return Get.dialog(
      PopScope(
        canPop: !blocking,
        child: AlertDialog(
          title: Text(S.updateTitle),
          content: Text(message),
          actions: [
            if (!blocking)
              TextButton(onPressed: Get.back, child: Text(S.later)),
            ElevatedButton(
              onPressed: () => launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication),
              child: Text(S.updateButton),
            ),
          ],
        ),
      ),
      barrierDismissible: !blocking,
    );
  }
}
