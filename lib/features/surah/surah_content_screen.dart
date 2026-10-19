import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/audio_options_sheet.dart';
import '../../core/utils/messenger.dart';
import 'dart:async';
import '../../core/widgets/audio_controls.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/models/surah_model.dart';
import '../../core/models/verse_model.dart';
import '../../core/controllers/audio_controller.dart';
import '../../core/services/quran_service.dart';
import '../../core/routes/app_routes.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../core/services/reading_progress_service.dart';
import '../../core/utils/verse_timing.dart';
import 'widgets/verse_actions_sheet.dart';
import 'widgets/verse_card.dart';

class SurahContentScreen extends StatefulWidget {
  final SurahModel surah;

  /// Verset (index 0-based) à afficher à l'ouverture.
  final int? initialVerseIndex;

  const SurahContentScreen({
    super.key,
    required this.surah,
    this.initialVerseIndex,
  });

  @override
  State<SurahContentScreen> createState() => _SurahContentScreenState();
}

class _SurahContentScreenState extends State<SurahContentScreen> {
  late final AudioController _audioController;
  late final QuranService _quranService;
  late final ReadingProgressService _progressService;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final RxInt _currentVerseIndex = (-1).obs;
  VerseTiming? _timing;
  Timer? _saveProgressTimer;
  StreamSubscription? _positionSubscription;
  Worker? _currentSurahWorker;
  AppLifecycleListener? _lifecycleListener;

  /// Dernière sourate jouée connue : l'écran ne suit la lecture que s'il
  /// affichait la sourate qui jouait.
  int? _lastPlayingNumber;

  @override
  void initState() {
    super.initState();
    _audioController = Get.find<AudioController>();
    _quranService = Get.find<QuranService>();

    _progressService = Get.find<ReadingProgressService>();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    if (widget.initialVerseIndex != null) {
      _progressService.save(widget.surah.number, widget.initialVerseIndex!);
    }

    _lastPlayingNumber = _audioController.currentSurah.value?.number;
    _currentSurahWorker =
        ever(_audioController.currentSurah, (_) => _followPlayback());
    _lifecycleListener = AppLifecycleListener(onResume: _followPlayback);

    _positionSubscription =
        _audioController.audioPlayer.positionStream.listen((position) {
      if (!mounted || !_isThisSurahPlaying) return;
      final duration = _audioController.audioPlayer.duration;
      if (duration == null) return;
      if (_timing?.total != duration)
        _timing = VerseTiming(widget.surah, duration);
      final newIndex = _timing!.indexAt(position);
      if (newIndex != _currentVerseIndex.value) {
        _currentVerseIndex.value = newIndex;
        if (newIndex >= 0) _scrollToVerse(newIndex);
      }
    }, onError: (_) {});
  }

  /// Basmala en tête pour toutes les sourates sauf Al-Fatiha.
  int get _offset => widget.surah.number == 1 ? 0 : 1;

  /// Position de lecture : premier verset visible, enregistré après 1 s d'arrêt.
  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || widget.surah.verses.isEmpty) return;
    final first = positions.where((p) => p.itemTrailingEdge > 0.05).fold<int?>(
        null, (min, p) => min == null || p.index < min ? p.index : min);
    if (first == null) return;
    final verseIndex =
        (first - _offset).clamp(0, widget.surah.verses.length - 1);
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer(const Duration(seconds: 1),
        () => _progressService.save(widget.surah.number, verseIndex));
  }

  bool get _isThisSurahPlaying =>
      _audioController.contentType.value == AudioContentType.surah &&
      _audioController.currentSurah.value?.number == widget.surah.number;

  /// La playlist est passée à une autre sourate : si cet écran montrait la sourate
  /// qui jouait et qu'il est visible, on affiche la nouvelle.
  void _followPlayback() {
    final playing = _audioController.currentSurah.value;
    final wasShowingPlaying = _lastPlayingNumber == widget.surah.number;
    final appVisible =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    final isTopRoute = mounted && (ModalRoute.of(context)?.isCurrent ?? false);

    if (playing != null && appVisible) {
      _lastPlayingNumber = playing.number;
    }
    if (playing == null || playing.number == widget.surah.number) return;
    if (wasShowingPlaying && appVisible && isTopRoute) {
      AppRoutes.openSurah(playing, replace: true);
    }
  }

  void _scrollToVerse(int verseIndex) {
    if (!_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: verseIndex + _offset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          // Download button
          Obx(() {
            final controller = Get.find<AudioController>();
            if (controller.isSurahDownloaded(widget.surah.number)) {
              return IconButton(
                icon: const Icon(Icons.download_done),
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Momtu Simoore'),
                      content: const Text('Aɗa yiɗi momtude simoore nde?'),
                      actions: [
                        TextButton(
                          child: const Text('Alaa'),
                          onPressed: () => Get.back(),
                        ),
                        TextButton(
                          child: const Text('Eyy'),
                          onPressed: () async {
                            await controller.deleteSurah(widget.surah.number);
                            Get.back();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            } else if (controller.isSurahDownloading(widget.surah.number)) {
              return IconButton(
                onPressed: null,
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: controller
                            .getSurahDownloadProgress(widget.surah.number),
                        strokeWidth: 2,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: () async {
                  final success =
                      await controller.downloadSurah(widget.surah.number);
                  if (!success) {
                    showMessage('Roŋki aawde simoore nde', error: true);
                  }
                },
              );
            }
          }),
          // Bookmark button
          Obx(() {
            final controller = Get.find<BookmarkService>();
            return IconButton(
              icon: Icon(controller.isBookmarked(widget.surah.number)
                  ? Icons.bookmark
                  : Icons.bookmark_border),
              onPressed: () => controller.toggleBookmark(widget.surah.number),
            );
          }),
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
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Theme.of(context).primaryColor,
                    inactiveTrackColor:
                        Theme.of(context).primaryColor.withOpacity(0.2),
                    thumbColor: Theme.of(context).primaryColor,
                    overlayColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  child: Obx(() {
                    final active = _isThisSurahPlaying;
                    final previous =
                        _quranService.previousOf(widget.surah.number);
                    final next = _quranService.nextOf(widget.surah.number);
                    return AudioControls(
                      audioPlayer: _audioController.audioPlayer,
                      active: active,
                      onPlayPressed: _togglePlay,
                      onPausePressed: _togglePlay,
                      onPreviousPressed:
                          previous == null ? null : () => _goTo(previous),
                      onNextPressed: next == null ? null : () => _goTo(next),
                      previousTooltip: previous?.namePulaar,
                      nextTooltip: next?.namePulaar,
                      onStopPressed: _audioController.stopPlaying,
                    onMorePressed: active ? AudioOptionsSheet.show : null,
                    );
                  }),
                ),
                _NeighbourCaption(
                    surah: widget.surah, quranService: _quranService),
              ],
            ),
          ),
          Expanded(
            child: ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              initialScrollIndex: widget.initialVerseIndex == null ||
                      widget.surah.verses.isEmpty
                  ? 0
                  : (widget.initialVerseIndex!
                          .clamp(0, widget.surah.verses.length - 1) +
                      _offset),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              itemCount: widget.surah.verses.isEmpty
                  ? (widget.surah.number == 1
                      ? 1
                      : 2) // Empty surah: 1 item for Fatiha, 2 for others (Basmala + message)
                  : (widget.surah.number == 1
                      ? widget.surah.verses.length
                      : widget.surah.verses.length + 1), // Normal case
              itemBuilder: (context, index) {
                // Show Basmala for all surahs except Al-Fatiha (surah 1)
                if (widget.surah.number != 1 && index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 12.0),
                      child: VerseCard(
                        verse: VerseModel(
                          number: 0,
                          arabic: kBasmalaArabic,
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.update_rounded,
                            size: 28,
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Maa maandeeji ɗi ɓeydoye ɗoo e yeeso',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.5,
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.7),
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
                  final verseIndex =
                      widget.surah.number == 1 ? index : index - 1;
                  if (verseIndex >= 0 &&
                      verseIndex < widget.surah.verses.length) {
                    return Obx(() => VerseCard(
                          verse: widget.surah.verses[verseIndex],
                          isCurrentVerse:
                              verseIndex == _currentVerseIndex.value &&
                                  _isThisSurahPlaying,
                          isBookmarked: Get.find<BookmarkService>()
                              .isVerseBookmarked(
                                  widget.surah.number, verseIndex),
                          onTap: () =>
                              VerseActionsSheet.show(widget.surah, verseIndex),
                        ));
                  }
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Précédent / suivant : si cette sourate joue, on avance dans la playlist
  /// (l'écran suit) ; sinon on ouvre la sourate et on la lit.
  void _goTo(SurahModel target) {
    final wasPlaying = _isThisSurahPlaying;
    final isNext =
        target.number == _quranService.nextOf(widget.surah.number)?.number;
    if (wasPlaying) {
      isNext ? _audioController.skipNext() : _audioController.skipPrevious();
    } else {
      _audioController.playSurah(target);
      AppRoutes.openSurah(target, replace: true);
    }
  }

  void _togglePlay() => _audioController.toggleSurah(widget.surah);

  @override
  void dispose() {
    _currentSurahWorker?.dispose();
    _lifecycleListener?.dispose();
    _positionSubscription?.cancel();
    _saveProgressTimer?.cancel();
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }
}

/// Noms de la sourate précédente et suivante, sous les contrôles.
class _NeighbourCaption extends StatelessWidget {
  final SurahModel surah;
  final QuranService quranService;

  const _NeighbourCaption({required this.surah, required this.quranService});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Obx(() {
      final previous = quranService.previousOf(surah.number);
      final next = quranService.nextOf(surah.number);
      if (previous == null && next == null) return const SizedBox(height: 8);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                previous == null ? '' : '‹ ${previous.namePulaar}',
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                next == null ? '' : '${next.namePulaar} ›',
                style: style,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    });
  }
}
