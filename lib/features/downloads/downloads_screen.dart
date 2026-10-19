import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/strings.dart';
import '../../core/models/surah_model.dart';
import '../../core/services/download_service.dart';
import '../../core/services/quran_service.dart';

String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  return '${(bytes / 1024).toStringAsFixed(0)} Ko';
}

/// Gestion des sourates téléchargées pour l'écoute hors ligne.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final _downloads = Get.find<DownloadService>();
  final _quranService = Get.find<QuranService>();
  final RxInt _usedBytes = 0.obs;
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _refreshUsage();
    // Recalcul de l'espace quand un téléchargement se termine ou est supprimé.
    _worker = debounce(_downloads.downloadedRx, (_) => _refreshUsage(),
        time: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  Future<void> _refreshUsage() async {
    _usedBytes.value = await _downloads.totalBytesOnDisk();
  }

  List<SurahModel> get _surahs =>
      _quranService.accessibleSurahs.where((s) => s.audioUrl.isNotEmpty).toList();

  Future<void> _confirmDeleteAll() async {
    final ok = await Get.dialog<bool>(AlertDialog(
      content: const Text(S.deleteAllConfirm),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text(S.no)),
        TextButton(onPressed: () => Get.back(result: true), child: const Text(S.yes)),
      ],
    ));
    if (ok == true) {
      await _downloads.deleteAll();
      await _refreshUsage();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.downloads)),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                Obx(() => ListTile(
                      leading: const Icon(Icons.sd_storage),
                      title: const Text(S.storageUsed),
                      trailing: Text(formatBytes(_usedBytes.value)),
                    )),
                Obx(() => SwitchListTile(
                      secondary: const Icon(Icons.wifi),
                      title: const Text(S.wifiOnly),
                      value: _downloads.wifiOnly.value,
                      onChanged: _downloads.setWifiOnly,
                    )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text(S.downloadAll),
                          onPressed: () => _downloads.downloadAll(_surahs),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text(S.deleteAll),
                          onPressed: _confirmDeleteAll,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final surahs = _surahs;
              return ListView.builder(
                itemCount: surahs.length,
                itemBuilder: (context, index) => _DownloadTile(
                  surah: surahs[index],
                  onChanged: _refreshUsage,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final SurahModel surah;
  final VoidCallback onChanged;

  const _DownloadTile({required this.surah, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final downloads = Get.find<DownloadService>();
    final n = surah.number;

    return Obx(() {
      final downloaded = downloads.isDownloaded(n);
      final downloading = downloads.isDownloading(n);
      final waiting = downloads.waiting.contains(n);
      final progress = downloads.getProgress(n);

      Widget trailing;
      if (downloaded) {
        trailing = IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await downloads.deleteSurah(n);
            onChanged();
          },
        );
      } else if (downloading) {
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 2.5,
              ),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => downloads.cancel(n)),
          ],
        );
      } else {
        trailing = IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: () async {
            if (await downloads.downloadSurah(surah)) onChanged();
          },
        );
      }

      return ListTile(
        leading: CircleAvatar(child: Text('$n')),
        title: Text(surah.namePulaar),
        subtitle: downloaded
            ? FutureBuilder<int>(
                future: downloads.fileSize(n),
                builder: (_, s) => Text(s.hasData ? formatBytes(s.data!) : ''),
              )
            : waiting
                ? const Text(S.waitingNetwork)
                : downloading
                    ? Text('${(progress * 100).round()} %')
                    : FutureBuilder<int?>(
                        future: downloads.remoteSize(surah),
                        builder: (_, s) => Text(s.data != null ? formatBytes(s.data!) : ''),
                      ),
        trailing: trailing,
      );
    });
  }
}
