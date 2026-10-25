import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/messenger.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/strings.dart';
import '../../core/l10n/app_language.dart';
import '../../core/services/reminder_service.dart';
import '../../core/services/corrector_service.dart';
import '../../core/services/settings_service.dart';
import '../surah/widgets/corrector_dialogs.dart';
import '../../core/routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _shareApp() async {
    final link = Platform.isIOS ? kAppStoreUrl : kPlayStoreUrl;
    await SharePlus.instance.share(ShareParams(text: '${S.shareText}\n$link'));
  }

  Future<void> _toggleReminder(BuildContext context, bool enabled) async {
    final ok = await Get.find<ReminderService>().setEnabled(enabled);
    if (!ok) {
      showMessage(S.reminderPermissionDenied);
    }
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final settings = Get.find<SettingsService>();
    final time = await showTimePicker(context: context, initialTime: settings.reminderTime);
    if (time != null) {
      await Get.find<ReminderService>().setEnabled(true, time: time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        // 5 appuis sur le titre : connexion au mode correcteur (Abou Sy, développeur).
        title: _TapCounter(onTriggered: CorrectorLoginDialog.show, child: Text(S.settings)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.translate),
                        title: Text(S.language),
                        trailing: Obx(() => DropdownButton<AppLanguage>(
                              value: settingsService.language ?? AppLanguage.pulaar,
                              items: [
                                for (final l in AppLanguage.values)
                                  DropdownMenuItem(value: l, child: Text(l.nativeName)),
                              ],
                              onChanged: (AppLanguage? l) {
                                if (l != null) settingsService.setLanguage(l);
                              },
                            )),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.dark_mode),
                        title: Text(S.theme),
                        trailing: Obx(() => DropdownButton<ThemeMode>(
                              value: settingsService.themeMode,
                              items: [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text(S.themeSystem),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text(S.themeLight),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text(S.themeDark),
                                ),
                              ],
                              onChanged: (ThemeMode? mode) {
                                if (mode != null) {
                                  settingsService.setThemeMode(mode);
                                }
                              },
                            )),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: Text(S.fontSize),
                        subtitle: Obx(() => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Slider(
                                  value: settingsService.fontSize,
                                  min: 14,
                                  max: 30,
                                  divisions: 8,
                                  label: settingsService.fontSize.round().toString(),
                                  onChanged: settingsService.setFontSize,
                                ),
                                Text(
                                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: settingsService.fontSize + 6,
                                  ),
                                ),
                                Text(
                                  S.fontPreview,
                                  style: TextStyle(fontSize: settingsService.fontSize + 1),
                                ),
                              ],
                            )),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.sort),
                        title: Text(S.surahOrder),
                        trailing: Obx(() => DropdownButton<SurahOrder>(
                              value: settingsService.surahOrder,
                              items: const [
                                DropdownMenuItem(
                                  value: SurahOrder.descending,
                                  child: Text('114 → 1'),
                                ),
                                DropdownMenuItem(
                                  value: SurahOrder.ascending,
                                  child: Text('1 → 114'),
                                ),
                              ],
                              onChanged: (SurahOrder? order) {
                                if (order != null) settingsService.setSurahOrder(order);
                              },
                            )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Obx(() => Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications),
                            title: Text(S.reminder),
                            value: settingsService.reminderEnabled,
                            onChanged: (value) => _toggleReminder(context, value),
                          ),
                          if (settingsService.reminderEnabled)
                            ListTile(
                              leading: const Icon(Icons.schedule),
                              title: Text(settingsService.reminderTime.format(context)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _pickReminderTime(context),
                            ),
                        ],
                      )),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.download_for_offline_outlined),
                        title: Text(S.downloads),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Get.toNamed(AppRoutes.downloads),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: Text(S.share),
                        onTap: _shareApp,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.verified_user_outlined),
                        title: Text(S.myActivation),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Get.toNamed(AppRoutes.myActivation),
                      ),
                      Obx(() => Get.find<CorrectorService>().isCorrector.value
                          ? Column(
                              children: [
                                const Divider(),
                                ListTile(
                                  leading: const Icon(Icons.edit_note),
                                  title: const Text('Mode correcteur'),
                                  subtitle: Text(Get.find<CorrectorService>().email.value ?? ''),
                                  trailing: const Icon(Icons.logout),
                                  onTap: CorrectorLoginDialog.signOut,
                                ),
                              ],
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Déclenche [onTriggered] après 5 appuis rapprochés.
class _TapCounter extends StatefulWidget {
  final VoidCallback onTriggered;
  final Widget child;

  const _TapCounter({required this.onTriggered, required this.child});

  @override
  State<_TapCounter> createState() => _TapCounterState();
}

class _TapCounterState extends State<_TapCounter> {
  int _count = 0;
  DateTime _last = DateTime(0);

  void _onTap() {
    final now = DateTime.now();
    _count = now.difference(_last) < const Duration(milliseconds: 700) ? _count + 1 : 1;
    _last = now;
    if (_count >= 5) {
      _count = 0;
      widget.onTriggered();
    }
  }

  @override
  Widget build(BuildContext context) =>
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: _onTap, child: widget.child);
}
