import 'package:flutter/material.dart';
import '../../../core/models/verse_model.dart';

class VerseCard extends StatelessWidget {
  final VerseModel verse;
  final bool isCurrentVerse;
  final VoidCallback? onTap;

  const VerseCard({
    Key? key,
    required this.verse,
    this.isCurrentVerse = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (verse.number > 0) ... [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      verse.number.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            const SizedBox(height: 2),
          ],
          Text(
            verse.arabic,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 22,
              height: 1.5,
              fontFamily: 'Uthmani',
            ),
          ),
          if (verse.pulaar.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              verse.pulaar,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 17,
                height: 1.4,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
