import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class TrackingPermissionService {
  static Future<bool> requestTrackingPermission() async {
    if (!Platform.isIOS) return true;

    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 200));
      final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
      return newStatus == TrackingStatus.authorized;
    }
    
    return status == TrackingStatus.authorized;
  }
}
