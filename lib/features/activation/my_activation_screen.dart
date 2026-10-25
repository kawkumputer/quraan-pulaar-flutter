import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/device_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/messenger.dart';

/// État de l'activation de cet appareil : version, code (masqué), date, appareil.
/// Aucune donnée personnelle de l'acheteur n'est affichée.
class MyActivationScreen extends StatefulWidget {
  const MyActivationScreen({super.key});

  @override
  State<MyActivationScreen> createState() => _MyActivationScreenState();
}

class _MyActivationScreenState extends State<MyActivationScreen> {
  final _settings = Get.find<SettingsService>();
  bool _showCode = false;
  DateTime? _activatedAt;
  String? _deviceModel;

  @override
  void initState() {
    super.initState();
    if (_settings.isActivated) _loadDetails();
  }

  /// Date et appareil d'activation depuis le serveur (facultatif : hors ligne, on s'en passe).
  Future<void> _loadDetails() async {
    try {
      final uniqueId = (await Get.find<DeviceService>().getDeviceInfo()).uniqueId;
      final result = await Supabase.instance.client.rpc('my_activation', params: {
        'p_unique_id': uniqueId,
        'p_code': _settings.activationCode,
      });
      final data = Map<String, dynamic>.from(result as Map);
      if (!mounted || data['activated'] != true) return;
      setState(() {
        _activatedAt = DateTime.tryParse(data['activated_at'] as String? ?? '')?.toLocal();
        _deviceModel = data['device_model'] as String?;
      });
    } catch (e) {
      debugPrint('my_activation failed: $e');
    }
  }

  String get _maskedCode {
    final code = _settings.activationCode;
    if (_showCode || code.length <= 3) return code;
    return '${'•' * (code.length - 3)}${code.substring(code.length - 3)}';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _openWhatsapp() async {
    final code = _settings.isActivated ? _settings.activationCode : '';
    final uri = Uri.parse(
        'https://wa.me/$kContactWhatsapp?text=${Uri.encodeComponent(S.whatsappMessage(code))}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(S.myActivation)),
      body: Obx(() {
        final activated = _settings.isActivated;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  activated ? Icons.verified : Icons.lock_outline,
                  color: activated ? theme.colorScheme.primary : theme.colorScheme.outline,
                  size: 32,
                ),
                title: Text(activated ? S.fullVersion : S.freeVersion),
              ),
            ),
            if (activated) ...[
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.key),
                      title: Text(S.activationCode),
                      subtitle: Text(_maskedCode,
                          style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 2)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: S.showCode,
                            icon: Icon(_showCode ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showCode = !_showCode),
                          ),
                          IconButton(
                            tooltip: S.copy,
                            icon: const Icon(Icons.copy),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: _settings.activationCode));
                              showMessage(S.copied);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_activatedAt != null) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.event_available),
                        title: Text(S.activatedOn),
                        subtitle: Text(_formatDate(_activatedAt!)),
                      ),
                    ],
                    if (_deviceModel != null) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.smartphone),
                        title: Text(S.onDevice),
                        subtitle: Text(_deviceModel!),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Text(S.keepCodeHint, style: theme.textTheme.bodySmall),
              ),
            ] else ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.lock_open),
                label: Text(S.activateDevice),
                onPressed: () => Get.toNamed(AppRoutes.activation),
              ),
            ],
            const SizedBox(height: 24),
            Text(activated ? S.changePhoneContact : S.buyCodeContact,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.chat),
              label: Text(S.contactWhatsapp),
              onPressed: _openWhatsapp,
            ),
          ],
        );
      }),
    );
  }
}
