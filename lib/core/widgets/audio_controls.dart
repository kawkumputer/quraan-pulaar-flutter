import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioControls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final bool isPlaying;
  final bool showProgress;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const AudioControls({
    super.key,
    required this.audioPlayer,
    required this.isPlaying,
    this.showProgress = true,
    required this.onPlayPause,
    required this.onStop,
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(_formatDuration(position)),
                      Expanded(
                        child: Slider(
                          value: position.inSeconds.toDouble(),
                          max: duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            audioPlayer.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Text(_formatDuration(duration)),
                      const SizedBox(width: 8),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 40,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: onPlayPause,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          Icons.stop_circle,
                          size: 40,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: onStop,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
