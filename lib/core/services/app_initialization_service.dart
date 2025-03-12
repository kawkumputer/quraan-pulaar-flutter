import 'dart:io';
import 'package:flutter/material.dart';
import 'tracking_permission_service.dart';

class AppInitializationService {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    if (Platform.isIOS) {
      // Show tracking permission dialog before any device ID collection
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay for better UX
      final hasPermission = await TrackingPermissionService.requestTrackingPermission();
      debugPrint('ATT Permission status: $hasPermission');
    }
  }
}
