import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/strings.dart';
import '../../../core/controllers/audio_controller.dart';
import '../../../core/models/surah_model.dart';
import '../../../core/services/bookmark_service.dart';
import '../../../core/utils/messenger.dart';

/// Actions sur un verset : copier, partager, favori, lire à partir d'ici.
class VerseActionsSheet extends StatelessWidget {
  final SurahModel surah;
  final int verseIndex;

  const VerseActionsSheet({super.key, required this.surah, required this.verseIndex});

  static Future<void> show(SurahModel surah, int verseIndex) {
    return Get.bottomSheet(
      VerseActionsSheet(surah: surah, verseIndex: verseIndex),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  String get _text {
    final verse = surah.verses[verseIndex];
    return '${verse.arabic}\n\n${verse.pulaar}\n\n'
        '- ${surah.namePulaar}, Maande ${verse.number}\n\nUmmoraade e Quraan Pulaar';
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = Get.find<BookmarkService>();
    final verse = surah.verses[verseIndex];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${surah.namePulaar} · Maande ${verse.number}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text(S.playFromHere),
            onTap: () {
              Get.back();
              Get.find<AudioController>().playFromVerse(surah, verseIndex);
            },
          ),
          Obx(() {
            final saved = bookmarks.isVerseBookmarked(surah.number, verseIndex);
            return ListTile(
              leading: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              title: Text(saved ? S.removeVerseBookmark : S.bookmarkVerse),
              onTap: () => bookmarks.toggleVerseBookmark(surah.number, verseIndex),
            );
          }),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text(S.copy),
            onTap: () async {
              Get.back();
              await Clipboard.setData(ClipboardData(text: _text));
              showMessage(S.copied);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text(S.share),
            onTap: () {
              Get.back();
              SharePlus.instance.share(ShareParams(text: _text));
            },
          ),
        ],
      ),
    );
  }
}
