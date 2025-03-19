import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import '../../core/widgets/audio_controls.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/models/surah_model.dart';
import '../../core/models/verse_model.dart';
import '../../core/controllers/audio_controller.dart';
import '../../core/services/quran_service.dart';
import '../../core/routes/app_routes.dart';
import 'widgets/verse_card.dart';

class SurahContentScreen extends StatefulWidget {
  final SurahModel surah;

  const SurahContentScreen({
    super.key,
    required this.surah,
  });

  @override
  State<SurahContentScreen> createState() => _SurahContentScreenState();
}

class _SurahContentScreenState extends State<SurahContentScreen> {
  final AudioController _audioController = Get.find<AudioController>();
  final BookmarkService _bookmarkService = Get.find<BookmarkService>();
  final QuranService _quranService = Get.find<QuranService>();
  final ScrollController _scrollController = ScrollController();
  int _currentVerseIndex = 0;
  final Map<int, GlobalKey> _verseKeys = {};
  final Map<int, double> _verseTimestamps = {};
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  SurahModel? get _previousSurah {
    final currentIndex = _quranService.surahs.indexWhere((s) => s.number == widget.surah.number);
    if (currentIndex > 0) {
      return _quranService.surahs[currentIndex - 1];
    }
    return null;
  }

  SurahModel? get _nextSurah {
    final currentIndex = _quranService.surahs.indexWhere((s) => s.number == widget.surah.number);
    if (currentIndex < _quranService.surahs.length - 1) {
      return _quranService.surahs[currentIndex + 1];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    // Initialize verse keys
    for (int i = 0; i < widget.surah.verses.length; i++) {
      _verseKeys[i] = GlobalKey();
    }
    _verseKeys[-1] = GlobalKey(); // Special key for Basmala

    // Auto-play if coming from previous surah completion
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic> && arguments['autoPlay'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _audioController.playUrl(
          widget.surah.number,
          widget.surah.audioUrl,
          surahName: widget.surah.namePulaar,
          surahNameArabic: widget.surah.nameArabic,
        );
      });
    }
  }

  Future<void> _initializeAudioAndPlay() async {
    try {
      await _audioController.playUrl(
        widget.surah.number,
        widget.surah.audioUrl,
        surahName: widget.surah.namePulaar,
        surahNameArabic: widget.surah.nameArabic,
      );
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  void _setupAudioPlayer() {
    _playerStateSubscription = _audioController.audioPlayer.playerStateStream.listen((state) async {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _currentVerseIndex = 0;
        });
        _scrollToVerse(0);

        // Auto-navigate to next surah if available
        if (_nextSurah != null) {
          await _navigateToNextSurah(autoPlay: true);
        } else {
          await _audioController.stopPlaying();
        }
      }
    });

    _positionSubscription = _audioController.audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      final newIndex = _findCurrentVerseIndex(position);
      if (newIndex != _currentVerseIndex) {
        setState(() {
          _currentVerseIndex = newIndex;
        });
        _scrollToVerse(newIndex);
      }
    });

    _durationSubscription = _audioController.audioPlayer.durationStream.listen((duration) {
      if (!mounted) return;
      if (duration != null) {
        _initializeVerseTimestamps(duration);
      }
    });
  }

  void _initializeVerseTimestamps(Duration totalDuration) {
    final int totalVerses = widget.surah.verses.length;
    // Calculate approximate verse durations based on verse lengths
    int totalTextLength = widget.surah.verses.fold(0, (sum, verse) => sum + verse.arabic.length);

    // Add Basmala length for non-Fatiha surahs
    if (widget.surah.number != 1) {
      totalTextLength += 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'.length;
    }

    double currentTime = 0;

    // Account for Basmala timing in non-Fatiha surahs
    if (widget.surah.number != 1) {
      final double basmalaDuration = ('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'.length / totalTextLength) * totalDuration.inMilliseconds;
      currentTime += basmalaDuration;
    }

    for (int i = 0; i < totalVerses; i++) {
      final verse = widget.surah.verses[i];
      final double verseDuration = (verse.arabic.length / totalTextLength) * totalDuration.inMilliseconds;
      _verseTimestamps[i] = currentTime;
      currentTime += verseDuration;
    }
  }

  int _findCurrentVerseIndex(Duration position) {
    final currentTime = position.inMilliseconds.toDouble();

    // Find the verse whose timestamp is closest to but not exceeding current time
    int targetIndex = 0;
    for (int i = 0; i < _verseTimestamps.length; i++) {
      if (_verseTimestamps[i]! <= currentTime) {
        targetIndex = i;
      } else {
        break;
      }
    }

    // Don't highlight any verse during Basmala for non-Fatiha surahs
    if (widget.surah.number != 1 && currentTime < _verseTimestamps[0]!) {
      return -1;
    }

    return targetIndex;
  }

  void _scrollToVerse(int index) {
    final key = _verseKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.3, // Align verse towards the top third of screen
      );
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextSurah({bool autoPlay = false}) async {
    if (_nextSurah != null) {
      await _audioController.stopPlaying();
      _quranService.setCurrentSurah(_nextSurah!);
      await Get.off(
        () => SurahContentScreen(surah: _nextSurah!),
        transition: Transition.rightToLeft,
        preventDuplicates: false,
        arguments: autoPlay ? {'autoPlay': true} : null
      );
    }
  }

  void _navigateToPreviousSurah({bool autoPlay = false}) {
    if (_previousSurah != null) {
      _audioController.stopPlaying();
      _quranService.setCurrentSurah(_previousSurah!);
      Get.off(
        () => SurahContentScreen(surah: _previousSurah!),
        transition: Transition.leftToRight,
        preventDuplicates: false,
        arguments: autoPlay ? {'autoPlay': true} : null
      );
    }
  }

  void _togglePlay() {
    _audioController.togglePlay(
      widget.surah.number,
      widget.surah.audioUrl,
      surahName: widget.surah.namePulaar,
      surahNameArabic: widget.surah.nameArabic,
    );
  }

  void _stopPlaying() {
    _audioController.stopPlaying();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        _stopPlaying();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _stopPlaying();
              Get.back();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.surah.nameArabic,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              Text(
                widget.surah.namePulaar,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            Obx(() => IconButton(
              icon: Icon(
                _bookmarkService.isBookmarked(widget.surah.number)
                  ? Icons.bookmark
                  : Icons.bookmark_border
              ),
              onPressed: () => _bookmarkService.toggleBookmark(widget.surah.number),
            )),
          ],
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      thumbColor: Theme.of(context).primaryColor,
                      overlayColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    child: AudioControls(
                      audioPlayer: _audioController.audioPlayer,
                      onPlayPressed: _togglePlay,
                      onPausePressed: _togglePlay,
                      onPreviousPressed: _previousSurah != null ? _navigateToPreviousSurah : () {},
                      onNextPressed: _nextSurah != null ? _navigateToNextSurah : () {},
                      onStopPressed: _stopPlaying,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: widget.surah.verses.isEmpty
                    ? (widget.surah.number == 1 ? 1 : 2)  // Empty surah: 1 item for Fatiha, 2 for others (Basmala + message)
                    : (widget.surah.number == 1 ? widget.surah.verses.length : widget.surah.verses.length + 1), // Normal case
                itemBuilder: (context, index) {
                  // Show Basmala for all surahs except Al-Fatiha (surah 1)
                  if (widget.surah.number != 1 && index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: VerseCard(
                          key: _verseKeys[-1], // Special key for Basmala
                          verse: VerseModel(
                            number: 0,
                            arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            pulaar: 'E innde alla Jurumdeero Jurmotooɗo',
                          ),
                          isCurrentVerse: false,
                        ),
                      ),
                    );
                  }

                  // Show "verses coming soon" message after Basmala (or as first item for Fatiha)
                  if (widget.surah.verses.isEmpty &&
                      ((widget.surah.number == 1 && index == 0) ||
                       (widget.surah.number != 1 && index == 1))) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.update_rounded,
                              size: 28,
                              color: Theme.of(context).primaryColor.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Maa maandeeji ɗi ɓeydoye ɗoo e yeeso',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.5,
                              color: Theme.of(context).primaryColor.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show verses if available
                  if (widget.surah.verses.isNotEmpty) {
                    final verseIndex = widget.surah.number == 1 ? index : index - 1;
                    if (verseIndex >= 0 && verseIndex < widget.surah.verses.length) {
                      return VerseCard(
                        key: _verseKeys[verseIndex],
                        verse: widget.surah.verses[verseIndex],
                        isCurrentVerse: verseIndex == _currentVerseIndex && _audioController.isPlaying.value,
                      );
                    }
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
