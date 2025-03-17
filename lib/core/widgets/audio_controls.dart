import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioControls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final bool isPlaying;
  final bool showProgress;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showNavigationButtons;

  const AudioControls({
    super.key,
    required this.audioPlayer,
    required this.isPlaying,
    this.showProgress = true,
    required this.onPlayPause,
    required this.onStop,
    this.onPrevious,
    this.onNext,
    this.showNavigationButtons = false,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showProgress) ...[
          StreamBuilder<Duration>(
            stream: audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = audioPlayer.duration ?? Duration.zero;
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: position.inSeconds.toDouble(),
                            max: duration.inSeconds.toDouble(),
                            onChanged: (value) {
                              audioPlayer.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showNavigationButtons && onPrevious != null) ...[
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 32),
                  onPressed: audioPlayer.processingState == ProcessingState.loading ? null : onPrevious,
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.zero,
                  splashRadius: 24,
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 44,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: audioPlayer.processingState == ProcessingState.loading ? null : onPlayPause,
                padding: EdgeInsets.zero,
                splashRadius: 24,
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: Icon(
                  Icons.stop_circle,
                  size: 44,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: audioPlayer.processingState == ProcessingState.loading ? null : onStop,
                padding: EdgeInsets.zero,
                splashRadius: 24,
              ),
              if (showNavigationButtons && onNext != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 32),
                  onPressed: audioPlayer.processingState == ProcessingState.loading ? null : onNext,
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.zero,
                  splashRadius: 24,
                ),
              ],
              if (audioPlayer.processingState == ProcessingState.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
