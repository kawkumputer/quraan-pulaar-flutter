import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/surah_model.dart';
import '../../../core/services/corrector_service.dart';
import '../../../core/utils/messenger.dart';

// Mode correcteur : textes en français (réservé à Abou Sy et au développeur).

/// Connexion / déconnexion du mode correcteur.
class CorrectorLoginDialog extends StatefulWidget {
  const CorrectorLoginDialog({super.key});

  static void show() {
    if (Get.find<CorrectorService>().isCorrector.value) {
      showMessage('Mode correcteur déjà actif');
      return;
    }
    Get.dialog(const CorrectorLoginDialog());
  }

  static Future<void> signOut() async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Mode correcteur'),
      content: const Text('Se déconnecter du mode correcteur ?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('Se déconnecter')),
      ],
    ));
    if (ok == true) await Get.find<CorrectorService>().signOut();
  }

  @override
  State<CorrectorLoginDialog> createState() => _CorrectorLoginDialogState();
}

class _CorrectorLoginDialogState extends State<CorrectorLoginDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await Get.find<CorrectorService>().signIn(_email.text, _password.text);
    if (!mounted) return;
    if (error == null) {
      Get.back();
      showMessage('Mode correcteur activé');
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mode correcteur'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
            onSubmitted: (_) => _busy ? null : _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Get.back(), child: const Text('Annuler')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Se connecter'),
        ),
      ],
    );
  }
}

/// Éditeur de la traduction pulaar d'un verset (l'arabe n'est pas modifiable).
class CorrectVerseDialog extends StatefulWidget {
  final SurahModel surah;
  final int verseNumber;

  const CorrectVerseDialog({super.key, required this.surah, required this.verseNumber});

  static Future<void> show(SurahModel surah, int verseNumber) =>
      Get.dialog(CorrectVerseDialog(surah: surah, verseNumber: verseNumber));

  @override
  State<CorrectVerseDialog> createState() => _CorrectVerseDialogState();
}

class _CorrectVerseDialogState extends State<CorrectVerseDialog> {
  late final String _original;
  late final TextEditingController _text;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _original = widget.surah.verses.firstWhere((v) => v.number == widget.verseNumber).pulaar;
    _text = TextEditingController(text: _original);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_text.text.trim() == _original.trim()) {
      Get.back();
      return;
    }
    if (_text.text.trim().isEmpty) {
      setState(() => _error = 'La traduction ne peut pas être vide.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await Get.find<CorrectorService>()
        .correct(widget.surah.number, widget.verseNumber, _text.text);
    if (!mounted) return;
    if (error == null) {
      Get.back();
      showMessage('Correction enregistrée');
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final arabic = widget.surah.verses.firstWhere((v) => v.number == widget.verseNumber).arabic;
    return AlertDialog(
      title: Text('${widget.surah.namePulaar} ${widget.surah.number}:${widget.verseNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(arabic,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Traduction pulaar',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Get.back(), child: const Text('Annuler')),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
