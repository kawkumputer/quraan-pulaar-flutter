import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/quran_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/models/surah_model.dart';
import '../../core/widgets/respectful_banner_ad.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final QuranService _quranService = Get.find<QuranService>();
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _quranService.loadSurahs();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.find<AdService>().showInterstitialAd('search_screen');
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yiylo cimooje'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Get.find<AdService>().showInterstitialAd('search_screen');
              Get.back();
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => _searchQuery.value = value,
                decoration: InputDecoration(
                  hintText: 'Yiylo innde simoore, tongoode walla maande',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_quranService.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_quranService.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Waawaa heɓde cimooje',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_quranService.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _quranService.loadSurahs,
                          child: const Text('Fuɗɗito'),
                        ),
                      ],
                    ),
                  );
                }

                final results = _searchQuery.value.isEmpty 
                    ? _quranService.surahs
                    : _quranService.searchSurahs(_searchQuery.value);

                if (_quranService.surahs.isEmpty) {
                  return const Center(
                    child: Text('Waawaa heɓde cimooje'),
                  );
                }

                if (results.isEmpty && _searchQuery.value.isNotEmpty) {
                  return const Center(
                    child: Text('Alaa ko heɓaa'),
                  );
                }

                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final surah = results[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            surah.number.toString(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(surah.namePulaar),
                      subtitle: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          surah.nameArabic,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                          ),
                        ),
                      ),
                      onTap: () {
                        Get.toNamed(
                          AppRoutes.surah,
                          arguments: surah,
                        );
                      },
                    );
                  },
                );
              }),
            ),
            // Add banner at bottom, not marking as Quran section since it's just search
            const RespectfulBannerAd(
              screenId: 'search_screen',
              isQuranSection: false,
              isAudioPlaying: false,
            ),
          ],
        ),
      ),
    );
  }
}
