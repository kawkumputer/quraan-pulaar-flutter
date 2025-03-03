import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../features/surah/models/surah.dart';
import '../../core/models/surah_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final RxString _searchQuery = ''.obs;
  final RxList<Surah> _allSurahs = <Surah>[].obs;
  final RxBool _isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    _isLoading.value = true;
    final surahs = await _firebaseService.getAllSurahs();
    _allSurahs.value = surahs;
    _isLoading.value = false;
  }

  List<Surah> _searchSurahs(String query) {
    if (query.isEmpty) return _allSurahs;

    final lowercaseQuery = query.toLowerCase();
    return _allSurahs.where((surah) {
      final numberMatch = surah.number.toString().contains(query);
      final nameMatch = surah.namePulaar.toLowerCase().contains(lowercaseQuery) ||
                       surah.nameArabic.contains(query);

      // Also search in verses if there's a match in the text or translation
      final versesMatch = surah.verses.any((verse) =>
        verse.pulaar.toLowerCase().contains(lowercaseQuery) ||
        verse.arabic.contains(query)
      );

      return numberMatch || nameMatch || versesMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yiylo cimooje'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
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
              if (_isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final results = _searchSurahs(_searchQuery.value);

              if (_allSurahs.isEmpty) {
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
                        arguments: SurahModel.fromFirebase(surah),
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
