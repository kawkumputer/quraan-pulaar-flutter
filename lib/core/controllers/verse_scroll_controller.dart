import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class VerseScrollController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final RxInt currentVerseIndex = RxInt(0);
  final RxBool isAutoScrolling = RxBool(false);
  final Duration scrollDuration;
  final double itemHeight;
  final int totalVerses;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _stateSubscription;

  VerseScrollController({
    required this.scrollDuration,
    required this.itemHeight,
    required this.totalVerses,
  }) {
    print('VerseScrollController initialized with itemHeight: $itemHeight, totalVerses: $totalVerses');
  }

  void startAutoScroll(AudioPlayer audioPlayer) async {
    print('Starting auto-scroll');
    isAutoScrolling.value = true;
    
    // Wait for duration to be available
    final duration = await audioPlayer.duration;
    print('Got audio duration: $duration');
    
    if (duration == null || duration == Duration.zero) {
      print('Invalid audio duration');
      return;
    }

    // Calculate time per verse
    final timePerVerse = duration.inMilliseconds ~/ totalVerses;
    print('Time per verse: $timePerVerse ms');

    // Cancel any existing subscriptions
    await _positionSubscription?.cancel();
    await _stateSubscription?.cancel();

    // Subscribe to position updates
    _positionSubscription = audioPlayer.positionStream.listen((position) {
      if (!isAutoScrolling.value) return;
      
      final progress = position.inMilliseconds / duration.inMilliseconds;
      final targetIndex = (progress * (totalVerses - 1)).floor();
      
      print('Progress: $progress, Position: $position, Target Index: $targetIndex, Current Index: ${currentVerseIndex.value}');
      
      if (targetIndex != currentVerseIndex.value && targetIndex >= 0 && targetIndex < totalVerses) {
        print('Scrolling to verse $targetIndex');
        currentVerseIndex.value = targetIndex;
        scrollToVerse(targetIndex);
      }
    }, onError: (error) {
      print('Error in position stream: $error');
    });

    // Subscribe to player state changes
    _stateSubscription = audioPlayer.playerStateStream.listen((state) {
      print('Audio state changed: ${state.processingState}');
      if (state.processingState == ProcessingState.completed) {
        print('Audio completed, stopping auto-scroll');
        stopAutoScroll();
      }
    });
  }

  void stopAutoScroll() {
    print('Stopping auto-scroll');
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    isAutoScrolling.value = false;
    currentVerseIndex.value = 0;
  }

  void scrollToVerse(int index) {
    if (!scrollController.hasClients) {
      print('ScrollController has no clients');
      return;
    }
    
    final targetOffset = index * itemHeight;
    final maxScroll = scrollController.position.maxScrollExtent;
    final minScroll = scrollController.position.minScrollExtent;
    
    final safeOffset = targetOffset.clamp(minScroll, maxScroll);
    print('Scrolling to offset $safeOffset (target: $targetOffset, max: $maxScroll, min: $minScroll)');
    
    scrollController.animateTo(
      safeOffset,
      duration: scrollDuration,
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    print('Disposing VerseScrollController');
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
