import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/strings.dart';
import '../../core/services/reminder_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/respectful_banner_ad.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _shareApp() async {
    final link = Platform.isIOS ? kAppStoreUrl : kPlayStoreUrl;
    await SharePlus.instance.share(ShareParams(text: '${S.shareText}\n$link'));
  }

  Future<void> _toggleReminder(BuildContext context, bool enabled) async {
    final ok = await Get.find<ReminderService>().setEnabled(enabled);
    if (!ok) {
      Get.snackbar('', S.reminderPermissionDenied, snackPosition: SnackPosition.BOTTOM);
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
        title: const Text('Teelte'),
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
                        leading: const Icon(Icons.dark_mode),
                        title: const Text('Goobu'),
                        trailing: Obx(() => DropdownButton<ThemeMode>(
                              value: settingsService.themeMode,
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text(S.themeSystem),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text('Jalbugol'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text('Niɓɓiɗgol'),
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
                        title: const Text('Ɓeydugol binndi'),
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
                        title: const Text(S.surahOrder),
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
                            title: const Text(S.reminder),
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
                        leading: const Icon(Icons.share),
                        title: const Text(S.share),
                        onTap: _shareApp,
                      ),
                      Obx(() => !settingsService.isActivated
                          ? Column(
                              children: [
                                const Divider(),
                                ListTile(
                                  leading: const Icon(Icons.device_unknown),
                                  title: const Text('Kuɓnugol Kaɓirgal'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Get.toNamed(AppRoutes.activation),
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
          const RespectfulBannerAd(
            screenId: 'settings_screen',
            isQuranSection: false,
          ),
        ],
      ),
    );
  }
}
