import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioControls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final VoidCallback onPlayPressed;
  final VoidCallback onPausePressed;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final VoidCallback onStopPressed;
  final bool showNavigationButtons;

  const AudioControls({
    super.key,
    required this.audioPlayer,
    required this.onPlayPressed,
    required this.onPausePressed,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.onStopPressed,
    this.showNavigationButtons = true,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          StreamBuilder<Duration?>(
            stream: audioPlayer.durationStream,
            builder: (context, snapshot) {
              final duration = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Colors.grey[300],
                          thumbColor: Theme.of(context).primaryColor,
                          overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        ),
                        child: Slider(
                          min: 0,
                          max: duration.inMilliseconds.toDouble(),
                          value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                          onChanged: (value) {
                            audioPlayer.seek(Duration(milliseconds: value.round()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (showNavigationButtons) 
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: onPreviousPressed,
                ),
              StreamBuilder<PlayerState>(
                stream: audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      width: 32.0,
                      height: 32.0,
                      child: const CircularProgressIndicator(),
                    );
                  }

                  if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_arrow),
                      iconSize: 32.0,
                      onPressed: onPlayPressed,
                    );
                  }

                  return IconButton(
                    icon: const Icon(Icons.pause),
                    iconSize: 32.0,
                    onPressed: onPausePressed,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: onStopPressed,
              ),
              if (showNavigationButtons) 
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: onNextPressed,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
