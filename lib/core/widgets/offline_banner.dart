import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/strings.dart';
import '../services/connectivity_service.dart';

/// Bandeau discret affiché quand l'appareil est hors ligne.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();
    return Obx(() {
      if (connectivity.isOnline.value) return const SizedBox.shrink();
      final scheme = Theme.of(context).colorScheme;
      return Material(
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S.offline,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
