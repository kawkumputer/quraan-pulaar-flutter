import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/models/verse_model.dart';

class VerseCard extends StatelessWidget {
  final VerseModel verse;
  final bool isCurrentVerse;
  final bool isBookmarked;
  final VoidCallback? onTap;

  const VerseCard({
    super.key,
    required this.verse,
    this.isCurrentVerse = false,
    this.isBookmarked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // Verset en cours de récitation : fond et bordure teintés.
          color: isCurrentVerse
              ? colorScheme.primary.withValues(alpha: 0.10)
              : colorScheme.surface,
          border: Border.all(
            color: isCurrentVerse
                ? colorScheme.primary.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1.5,
          ),
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
            if (verse.number > 0) ...[
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
                  if (isBookmarked)
                    Icon(Icons.bookmark, size: 16, color: colorScheme.primary),
                ],
              ),
              const SizedBox(height: 2),
            ],
            // Taille réglable dans Teelte (16 par défaut : arabe 22, pulaar 17).
            Obx(() {
              final fontSize = Get.find<SettingsService>().fontSize;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    verse.arabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: fontSize + 6,
                      height: 1.7,
                      fontFamily: 'Amiri',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (verse.pulaar.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      verse.pulaar,
                      textAlign: TextAlign.left,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: fontSize + 1,
                        height: 1.4,
                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
