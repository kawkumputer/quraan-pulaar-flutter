import 'package:flutter/material.dart';

/// ScaffoldMessenger racine (passé à GetMaterialApp). Remplace Get.snackbar,
/// qui ne trouve pas l'Overlay du navigateur avec Flutter 3.44 / GetX 4.7.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showMessage(String message, {bool error = false}) {
  final messenger = rootMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Colors.red.shade700 : null,
      duration: const Duration(seconds: 3),
    ));
}
