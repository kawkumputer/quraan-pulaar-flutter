import 'package:flutter/material.dart';

class AudioControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showNavigationButtons;

  const AudioControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPause,
    required this.onStop,
    this.onPrevious,
    this.onNext,
    this.showNavigationButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              onPressed: isLoading ? null : onPrevious,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: isLoading ? null : onPlayPause,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.stop_circle_outlined,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: isLoading ? null : onStop,
          ),
          if (showNavigationButtons && onNext != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 32),
              onPressed: isLoading ? null : onNext,
              color: Theme.of(context).primaryColor,
            ),
          ],
          if (isLoading)
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
    );
  }
}
