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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentVerse 
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.white,
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
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            verse.arabic,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              height: 1.5,
              fontFamily: 'Uthmani',
            ),
          ),
          if (verse.pulaar.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              verse.pulaar,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                height: 1.5,
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
