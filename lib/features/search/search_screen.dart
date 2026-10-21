import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/strings.dart';
import '../../core/models/surah_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/quran_service.dart';
import '../../core/services/search_service.dart';
import '../../core/utils/text_normalizer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final QuranService _quranService = Get.find<QuranService>();
  final SearchService _searchService = Get.find<SearchService>();
  final RxString _input = ''.obs;
  final RxString _query = ''.obs;
  final RxList<SearchResult> _results = <SearchResult>[].obs;
  late final Worker _debounce;

  @override
  void initState() {
    super.initState();
    // On cherche 300 ms après la dernière frappe.
    _debounce = debounce(_input, (String q) => _query.value = q,
        time: const Duration(milliseconds: 300));
    ever(_query, (_) => _runSearch());
    ever(_searchService.isIndexing, (_) => _runSearch());
  }

  void _runSearch() {
    _results.value = _searchService.search(_query.value);
  }

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(title: Text(S.searchTitle)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (value) => _input.value = value,
                decoration: InputDecoration(
                  hintText: S.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_query.value.trim().isEmpty) {
                  return _SurahList(quranService: _quranService);
                }
                if (_results.isEmpty) {
                  return _searchService.isIndexing.value
                      ? const Center(child: CircularProgressIndicator())
                      : Center(child: Text(S.noResults));
                }
                final normalized =
                    TextNormalizer.normalize(_query.value.trim());
                return ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ResultTile(
                      result: _results[index], normalizedQuery: normalized),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sans recherche : liste des sourates.
class _SurahList extends StatelessWidget {
  final QuranService quranService;

  const _SurahList({required this.quranService});

  @override
  Widget build(BuildContext context) => Obx(() => _build());

  Widget _build() {
    final surahs = quranService.surahs;
    if (surahs.isEmpty) {
      return Center(
        child: TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: Text(S.retry),
          onPressed: () => quranService.loadSurahs(force: true),
        ),
      );
    }
    return ListView.builder(
      itemCount: surahs.length,
      itemBuilder: (context, index) => _SurahTile(surah: surahs[index]),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final SurahModel surah;

  const _SurahTile({required this.surah});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: primary.withValues(alpha: 0.1),
        child: Text('${surah.number}',
            style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
      ),
      title: Text(surah.namePulaar),
      subtitle: Text(
        surah.nameArabic,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
      ),
      onTap: () => AppRoutes.openSurah(surah),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  final String normalizedQuery;

  const _ResultTile({required this.result, required this.normalizedQuery});

  @override
  Widget build(BuildContext context) {
    final verseIndex = result.verseIndex;
    if (verseIndex == null) return _SurahTile(surah: result.surah);

    final verse = result.surah.verses[verseIndex];
    final arabicRange =
        TextNormalizer.findInOriginal(verse.arabic, normalizedQuery);
    final pulaarRange =
        TextNormalizer.findInOriginal(verse.pulaar, normalizedQuery);
    final theme = Theme.of(context);

    return ListTile(
      title: Text(
        S.verseRef(result.surah, verse.number),
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.primary),
      ),
      subtitle: arabicRange != null
          ? _highlighted(verse.arabic, arabicRange, context, arabic: true)
          : _highlighted(verse.pulaar, pulaarRange, context),
      onTap: () => AppRoutes.openSurah(result.surah, verseIndex: verseIndex),
    );
  }

  /// Extrait autour de la correspondance, avec la correspondance en gras surligné.
  Widget _highlighted(String text, (int, int)? range, BuildContext context,
      {bool arabic = false}) {
    final base = TextStyle(
      fontFamily: arabic ? 'Amiri' : null,
      fontSize: arabic ? 18 : 14,
      color: Theme.of(context).colorScheme.onSurface,
    );
    if (range == null) {
      return Text(text,
          maxLines: 3, overflow: TextOverflow.ellipsis, style: base);
    }
    final (start, end) = range;
    // Fenêtre de contexte pour que la correspondance reste visible.
    final from = (start - 60).clamp(0, text.length);
    final to = (end + 80).clamp(0, text.length);
    return Text.rich(
      TextSpan(style: base, children: [
        if (from > 0) const TextSpan(text: '… '),
        TextSpan(text: text.substring(from, start)),
        TextSpan(
          text: text.substring(start, end),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
          ),
        ),
        TextSpan(text: text.substring(end, to)),
        if (to < text.length) const TextSpan(text: ' …'),
      ]),
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }
}
