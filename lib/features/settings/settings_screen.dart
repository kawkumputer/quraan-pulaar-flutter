import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends GetView<SettingsService> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                Obx(() => ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Theme'),
                      trailing: DropdownButton<ThemeMode>(
                        value: controller.themeMode,
                        items: ThemeMode.values
                            .map((mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode.toString().split('.').last),
                                ))
                            .toList(),
                        onChanged: (mode) {
                          if (mode != null) {
                            controller.setThemeMode(mode);
                          }
                        },
                      ),
                    )),
                const Divider(),
                Obx(() => ListTile(
                      leading: const Icon(Icons.text_fields),
                      title: const Text('Font Size'),
                      subtitle: Slider(
                        value: controller.fontSize,
                        min: 14.0,
                        max: 24.0,
                        divisions: 5,
                        label: controller.fontSize.toStringAsFixed(1),
                        onChanged: (value) {
                          controller.setFontSize(value);
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: const Text('Translation'),
                  subtitle: const Text('Pulaar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Show translation options
                  },
                ),
                const Divider(),
                Obx(() => ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      subtitle: const Text('Daily verse reminders'),
                      trailing: Switch(
                        value: controller.notificationsEnabled,
                        onChanged: (value) {
                          controller.setNotificationsEnabled(value);
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Quraan Pulaar',
                      applicationVersion: '1.0.0',
                      applicationIcon: Image.asset(
                        'assets/icon/icon.png',
                        width: 48,
                        height: 48,
                      ),
                      children: [
                        const Text(
                          'A beautiful Quran app with Pulaar translation.',
                        ),
                      ],
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share App'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implement app sharing
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
