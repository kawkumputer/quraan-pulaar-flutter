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

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String allSurahs = '/all-surahs';
  static const String surah = '/surah';
  static const String bookmarks = '/bookmarks';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String hadith = '/hadith';
  static const String activation = '/activation';
  static const String about = '/about';

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
      page: () => SurahContentScreen(
        surah: Get.arguments,
      ),
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
