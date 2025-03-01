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
        title: const Text('Teelte'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                Obx(() => ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Goobu'),
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
                      title: const Text('Ɓeydugol binndi'),
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
                  title: const Text('Firo'),
                  subtitle: const Text('Pulaar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Show translation options
                  },
                ),
                const Divider(),
                Obx(() => ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Tintine'),
                      subtitle: const Text('Tintine maande ñalnde'),
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
                  title: const Text('Baɗte'),
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
                          'Jaaɓngal Quraan e firo Pulaar',
                        ),
                      ],
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Sar jaaɓngal ngal'),
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
