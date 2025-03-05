import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/widgets/audio_controls.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/models/surah_model.dart';
import '../../core/models/verse_model.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BookmarkService _bookmarkService = Get.find<BookmarkService>();
  bool _isPlaying = false;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  int _currentVerseIndex = 0;
  double _verseHeight = 200.0;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });

      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _currentVerseIndex = 0;
        });
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
        );
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      if (!_audioPlayer.playing) return;

      final duration = _audioPlayer.duration;
      if (duration == null) return;

      final progress = position.inMilliseconds / duration.inMilliseconds;
      final targetIndex = (progress * widget.surah.verses.length).floor();

      if (targetIndex != _currentVerseIndex && targetIndex >= 0 && targetIndex < widget.surah.verses.length) {
        setState(() {
          _currentVerseIndex = targetIndex;
        });

        final targetOffset = targetIndex * _verseHeight;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.duration == null) {
          await _audioPlayer.setUrl(widget.surah.audioUrl);
        }
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Roŋki aawtaade simoore nde'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopPlaying() async {
    await _audioPlayer.stop();
    setState(() {
      _currentVerseIndex = 0;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    _verseHeight = screenHeight / 3;

    return WillPopScope(
      onWillPop: () async {
        await _stopPlaying();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            children: [
              Text(
                widget.surah.nameArabic,
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                widget.surah.namePulaar,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _stopPlaying();
              Get.back();
            },
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 1.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: AudioControls(
                  audioPlayer: _audioPlayer,
                  isPlaying: _audioPlayer.playing,
                  onPlayPause: _togglePlay,
                  onStop: _stopPlaying,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: widget.surah.number == 1 ? widget.surah.verses.length : widget.surah.verses.length + 1,
                itemBuilder: (context, index) {
                  // Show Basmala for all surahs except Al-Fatiha (surah 1)
                  if (widget.surah.number != 1 && index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: VerseCard(
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

                  final verse = widget.surah.verses[widget.surah.number == 1 ? index : index - 1];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 1.0),
                    color: (widget.surah.number == 1 ? index : index - 1) == _currentVerseIndex
                        ? Theme.of(context).primaryColor.withOpacity(0.05)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                      child: VerseCard(
                        verse: verse,
                        isCurrentVerse: (widget.surah.number == 1 ? index : index - 1) == _currentVerseIndex && _audioPlayer.playing,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
