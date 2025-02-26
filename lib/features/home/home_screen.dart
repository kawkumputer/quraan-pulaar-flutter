import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/daily_verse_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Verse Section
            DailyVerseWidget(),
            
            // Navigation Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildNavigationCard(
                    title: 'All Surahs',
                    subtitle: 'Browse all surahs of the Quran',
                    icon: Icons.menu_book,
                    onTap: () => Get.toNamed(AppRoutes.allSurahs),
                  ),
                  const SizedBox(height: 16),
                  _buildNavigationCard(
                    title: 'Hadiths',
                    subtitle: 'Listen to Prophetic traditions',
                    icon: Icons.record_voice_over,
                    onTap: () => Get.toNamed(AppRoutes.hadith),
                  ),
                  const SizedBox(height: 16),
                  _buildNavigationCard(
                    title: 'Bookmarks',
                    subtitle: 'Access your saved surahs',
                    icon: Icons.bookmark,
                    onTap: () => Get.toNamed(AppRoutes.bookmarks),
                  ),
                  const SizedBox(height: 16),
                  _buildNavigationCard(
                    title: 'Search',
                    subtitle: 'Search for verses and surahs',
                    icon: Icons.search,
                    onTap: () => Get.toNamed(AppRoutes.search),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        leading: Icon(icon, color: const Color(0xFF1F6E8C)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
