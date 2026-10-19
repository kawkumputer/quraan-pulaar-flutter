import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// État de la connexion, observable par l'UI (bannière hors ligne).
class ConnectivityService extends GetxService {
  final isOnline = true.obs;
  StreamSubscription<ConnectivityResult>? _subscription;

  @override
  void onInit() {
    super.onInit();
    final connectivity = Connectivity();
    connectivity.checkConnectivity().then(_update);
    _subscription = connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(ConnectivityResult result) {
    isOnline.value = result != ConnectivityResult.none;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
