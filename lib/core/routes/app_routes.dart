import 'package:get/get.dart';
import '../../features/home/home_screen.dart';
import '../../features/surah/surah_content_screen.dart';
import '../../features/surah/all_surahs_screen.dart';
import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/hadith/hadith_screen.dart';
import '../../features/activation/activation_screen.dart';
import '../../features/about/about_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../services/quran_service.dart';
import '../models/surah_model.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String allSurahs = '/all-surahs';
  static const String surah = '/surah/:number';
  static const String bookmarks = '/bookmarks';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String hadith = '/hadith';
  static const String activation = '/activation';
  static const String about = '/about';

  static String surahPath(int number) => '/surah/$number';

  /// Ouvre l'écran d'une sourate (ou l'activation si elle est verrouillée).
  /// [replace] remplace l'écran courant au lieu d'empiler.
  /// [verseIndex] : verset (index 0-based) à afficher en arrivant.
  static Future<void>? openSurah(SurahModel surah, {int? verseIndex, bool replace = false}) {
    final quranService = Get.find<QuranService>();
    if (quranService.isLocked(surah)) return Get.toNamed(activation);
    quranService.setCurrentSurah(surah);
    final path = surahPath(surah.number);
    final args = {'surah': surah, 'verse': verseIndex};
    return replace
        ? Get.offNamed(path, arguments: args, preventDuplicates: false)
        : Get.toNamed(path, arguments: args, preventDuplicates: false);
  }

  static final List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: allSurahs,
      page: () => const AllSurahsScreen(),
    ),
    GetPage(
      name: surah,
      page: () {
        final args = Get.arguments;
        if (args is SurahModel) return SurahContentScreen(surah: args);
        if (args is Map && args['surah'] is SurahModel) {
          return SurahContentScreen(
            surah: args['surah'] as SurahModel,
            initialVerseIndex: args['verse'] as int?,
          );
        }

        final number = int.tryParse(Get.parameters['number'] ?? '');
        final surah = number == null ? null : Get.find<QuranService>().byNumber(number);
        if (surah == null) return const HomeScreen();
        return SurahContentScreen(surah: surah);
      },
    ),
    GetPage(
      name: bookmarks,
      page: () => BookmarksScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: search,
      page: () => SearchScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: hadith,
      page: () => const HadithScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: activation,
      page: () => const ActivationScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: about,
      page: () => const AboutScreen(),
    ),
  ];
}
