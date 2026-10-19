import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/offline_banner.dart';
import 'widgets/recent_reading_card.dart';
import '../../core/services/reminder_service.dart';
import '../../core/services/app_config_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/settings_service.dart';
import '../../core/controllers/activation_controller.dart';
import 'widgets/daily_verse_widget.dart';
import '../../core/widgets/respectful_banner_ad.dart';
import '../../core/constants/strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _activationController = Get.find<ActivationController>();

  @override
  void initState() {
    super.initState();
    // Check activation after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // App ouverte depuis le rappel quotidien : on ouvre la sourate du verset.
      Get.find<ReminderService>().handleLaunchNotification();
      // Mise à jour obligatoire : le dialogue bloquant ne se ferme pas.
      await Get.find<AppConfigService>().checkForUpdate();
      _activationController.checkActivation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quraan Pulaar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Center(
                child: Text(
                  'Quraan Pulaar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(S.contact),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.about);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(S.settings),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.settings);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activation Status Banner
                  Obx(() => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: settingsService.isActivated
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                color: Colors.green.shade50,
                                child: Row(
                                  children: [
                                    Icon(Icons.verified,
                                        color: Colors.green.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      S.fullVersion,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                color: Colors.amber.shade50,
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.amber.shade900),
                                    const SizedBox(width: 8),
                                    Text(
                                      S.freeVersion,
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      icon: const Icon(Icons.lock_open),
                                      label: Text(S.activate),
                                      onPressed: () =>
                                          Get.toNamed(AppRoutes.activation),
                                    ),
                                  ],
                                ),
                              ),
                      )),

                  // Daily Verse Section
                  DailyVerseWidget(),

                  // Reprendre la lecture
                  const RecentReadingCard(),

                  // Navigation Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildNavigationCard(
                          title: S.surahs,
                          subtitle: S.surahsSubtitle,
                          icon: Icons.menu_book,
                          onTap: () => Get.toNamed(AppRoutes.allSurahs),
                        ),
                        const SizedBox(height: 16),
                        _buildNavigationCard(
                          title: S.hadithsMenu,
                          subtitle: S.hadithsSubtitle,
                          icon: Icons.record_voice_over,
                          onTap: () => Get.toNamed(AppRoutes.hadith),
                        ),
                        const SizedBox(height: 16),
                        _buildNavigationCard(
                          title: S.bookmarksMenu,
                          subtitle: S.bookmarksSubtitle,
                          icon: Icons.bookmark,
                          onTap: () => Get.toNamed(AppRoutes.bookmarks),
                        ),
                        const SizedBox(height: 16),
                        _buildNavigationCard(
                          title: S.search,
                          subtitle: S.searchSubtitle,
                          icon: Icons.search,
                          onTap: () => Get.toNamed(AppRoutes.search),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Add banner at bottom with unique screen ID
          const RespectfulBannerAd(
            screenId: 'home_screen',
            isQuranSection: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
        onTap: onTap,
      ),
    );
  }
}
