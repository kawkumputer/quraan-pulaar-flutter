import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jokkondiral'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Arabic Text
              const Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Arabic',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Arabic Description
              const Text(
                'يعتمد هذا التطبيق على ترجمة القرآن\nالكريم للسيد أبو سيح باللغة البولارية\n(الفولاني)',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Arabic',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Arabic Developer Info
              const Text(
                'تم تطوير التطبيق بواسطة همات كان',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Arabic',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Pulaar Title
              const Text(
                'E innde alla Jurumdeero Jurmotoodo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Pulaar Description
              const Text(
                'Ngal jaaɓngal tuugnii ko e deftere Quraan teddunde nde ceerno Abuu Sih firi he ɗemngal Pulaar Fulfulde',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Baañnjitiiɗo deftere nde e mbaaydi jaaɓngal ko Hamath Kan',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Divider
              const Text(
                'Jokkondir - اتصل',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Contact Info - Abuu Sih
              Card(
                child: ListTile(
                  title: const Text(
                    'Abuu Sih - أبو سي',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.email),
                        label: const Text('atumansy6@gmail.com'),
                        onPressed: () => _launchEmail('atumansy6@gmail.com'),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.phone),
                        label: const Text('+221 77 3091782'),
                        onPressed: () => _launchPhone('+221773091782'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Contact Info - Hamath Kan
              Card(
                child: ListTile(
                  title: const Text(
                    'Hamath Kan - همات كان',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.email),
                        label: const Text('kawkumputer@gmail.com'),
                        onPressed: () => _launchEmail('kawkumputer@gmail.com'),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.phone),
                        label: const Text('+33 759845448'),
                        onPressed: () => _launchPhone('+33759845448'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
