import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';

class AudioRouteObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stopAudioIfPlaying();
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stopAudioIfPlaying();
    super.didPush(route, previousRoute);
  }

  void _stopAudioIfPlaying() {
    try {
      final audioController = Get.find<AudioController>();
      audioController.stopPlaying();
    } catch (_) {
      // AudioController might not be initialized yet
    }
  }
}
