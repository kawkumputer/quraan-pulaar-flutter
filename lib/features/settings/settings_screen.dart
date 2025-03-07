import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teelte'),
      ),
      body: ListView(
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
                  subtitle: Obx(() => Slider(
                        value: settingsService.fontSize,
                        min: 14,
                        max: 30,
                        divisions: 8,
                        label: settingsService.fontSize.round().toString(),
                        onChanged: (value) {
                          settingsService.setFontSize(value);
                        },
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Tintine'),
                  subtitle: const Text('Tintine maande ñalnde'),
                  trailing: Obx(() => Switch(
                        value: settingsService.notificationsEnabled,
                        onChanged: (value) {
                          settingsService.setNotificationsEnabled(value);
                        },
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Yaltinde'),
                  onTap: () {
                    // TODO: Implement app sharing
                  },
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
    );
  }
}
