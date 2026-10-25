import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:quraan_pulaar/core/utils/quran_snapshot.dart';

Map<String, dynamic> _surah(int n, int count) => {
      'number': n,
      'name_arabic': 'ar$n',
      'name_pulaar': 'ff$n',
      'audio_url': 'https://audio/$n.mp3',
      'verses_count': count,
    };

Map<String, dynamic> _verse(int s, int n, String ff) => {'s': s, 'n': n, 'ar': 'ar$s:$n', 'ff': ff};

void main() {
  final fullResponse = {
    'server_time': '2026-10-25T10:00:00Z',
    'activated': false,
    'surahs': [_surah(112, 2), _surah(1, 2)],
    'verses': [_verse(1, 2, 'b'), _verse(1, 1, 'a'), _verse(112, 1, 'c'), _verse(112, 2, 'd')],
  };

  test('full sync builds sorted models', () {
    final snap = QuranSnapshot.empty.apply(fullResponse, full: true);
    expect(snap.isEmpty, isFalse);
    expect(snap.serverTime, DateTime.utc(2026, 10, 25, 10));
    final models = snap.toModels();
    expect(models.map((s) => s.number), [1, 112]);
    expect(models.first.verses.map((v) => v.pulaar), ['a', 'b']);
    expect(models.first.audioUrl, 'https://audio/1.mp3');
    expect(models.first.versesCount, 2);
  });

  test('incremental sync only replaces changed verses', () {
    final snap = QuranSnapshot.empty.apply(fullResponse, full: true).apply({
      'server_time': '2026-10-25T11:00:00Z',
      'activated': false,
      'surahs': [],
      'verses': [_verse(1, 2, 'b corrigé')],
    }, full: false);
    expect(snap.serverTime, DateTime.utc(2026, 10, 25, 11));
    expect(snap.verses[1], {1: ['ar1:1', 'a'], 2: ['ar1:2', 'b corrigé']});
    expect(snap.verses[112]!.length, 2);
  });

  test('full sync drops content no longer allowed', () {
    final snap = QuranSnapshot.empty.apply(fullResponse, full: true).apply({
      'server_time': '2026-10-25T12:00:00Z',
      'activated': false,
      'surahs': [_surah(1, 2)],
      'verses': [_verse(1, 1, 'a'), _verse(1, 2, 'b')],
    }, full: true);
    expect(snap.surahs.keys, [1]);
    expect(snap.verses.containsKey(112), isFalse);
  });

  test('withPulaar corrects one verse without touching the original', () {
    final snap = QuranSnapshot.empty.apply(fullResponse, full: true);
    final fixed = snap.withPulaar(112, 1, 'nouveau');
    expect(fixed.verses[112]![1], ['ar112:1', 'nouveau']);
    expect(snap.verses[112]![1], ['ar112:1', 'c']);
    expect(identical(snap.withPulaar(2, 1, 'x'), snap), isTrue);
  });

  test('JSON round-trip', () {
    final snap = QuranSnapshot.empty.apply({...fullResponse, 'activated': true}, full: true);
    final back = QuranSnapshot.fromJson(jsonDecode(jsonEncode(snap.toJson())) as Map<String, dynamic>);
    expect(back.activated, isTrue);
    expect(back.serverTime, snap.serverTime);
    expect(back.surahs, snap.surahs);
    expect(back.verses, snap.verses);
  });
}
