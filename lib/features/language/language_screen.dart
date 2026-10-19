import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/strings.dart';
import '../../core/l10n/app_language.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

/// Choix de la langue de l'interface, au premier lancement.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  AppLanguage _selected = CurrentLanguage.value;

  Future<void> _continue() async {
    await Get.find<SettingsService>().setLanguage(_selected);
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    // Les titres s'affichent dans la langue sélectionnée, pour aider à choisir.
    final previous = CurrentLanguage.value;
    CurrentLanguage.value = _selected;
    final title = S.chooseLanguage;
    final hint = S.chooseLanguageHint;
    final button = S.continueButton;
    CurrentLanguage.value = previous;

    return Directionality(
      textDirection: _selected.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.translate, size: 56, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(hint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                for (final language in AppLanguage.values)
                  Card(
                    child: RadioListTile<AppLanguage>(
                      value: language,
                      groupValue: _selected,
                      onChanged: (value) => setState(() => _selected = value!),
                      title: Text(language.nativeName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(button, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
