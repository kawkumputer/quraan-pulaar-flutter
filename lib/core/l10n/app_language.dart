import 'package:flutter/widgets.dart';

/// Langues de l'interface. Le Coran reste toujours en arabe avec sa traduction Pulaar.
enum AppLanguage {
  pulaar('ff', 'Pulaar'),
  french('fr', 'Français'),
  arabic('ar', 'العربية');

  final String code;

  /// Nom de la langue dans la langue elle-même (écran de choix).
  final String nativeName;

  const AppLanguage(this.code, this.nativeName);

  bool get isRtl => this == AppLanguage.arabic;

  /// Locale passée à MaterialApp. Le Pulaar n'a pas de traductions Material :
  /// on utilise le français pour les composants système (sélecteur d'heure…).
  Locale get materialLocale => Locale(this == AppLanguage.arabic ? 'ar' : 'fr');

  static AppLanguage? fromCode(String? code) {
    for (final l in AppLanguage.values) {
      if (l.code == code) return l;
    }
    return null;
  }
}

/// Langue courante, lue par S (mise à jour par SettingsService).
class CurrentLanguage {
  static AppLanguage value = AppLanguage.pulaar;
}
