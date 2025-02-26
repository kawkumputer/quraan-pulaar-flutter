import 'package:flutter/material.dart';
import '../models/surah.dart';

class VerseCard extends StatelessWidget {
  final Verse verse;
  final bool isHighlighted;

  const VerseCard({
    super.key,
    required this.verse,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted 
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
          Text(
            verse.arabic,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
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
                fontSize: 15,
                height: 1.3,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
