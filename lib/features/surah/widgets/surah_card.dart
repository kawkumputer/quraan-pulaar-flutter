import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/surah.dart';
import '../../../core/routes/app_routes.dart';

class SurahCard extends StatelessWidget {
  final Surah surah;
  final bool isBookmarked;

  const SurahCard({
    super.key,
    required this.surah,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppRoutes.surah,
            arguments: {
              'surahNumber': surah.number,
              'title': surah.nameArabic,
              'audioUrl': surah.audioUrl ?? '',
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${surah.number}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                surah.nameArabic,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Arabic',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maandeeji ${surah.verses}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      surah.namePulaar,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBookmarked)
                const Icon(
                  Icons.bookmark,
                  color: Colors.amber,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
