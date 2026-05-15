import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quran_models.dart';

/// API utama  : https://alquran.cloud/api  (100% gratis, no key)
/// Audio      : CDN Everyayah.com  (Mishary Rashid Alafasy)
/// Tafsir     : https://quranenc.com/api  (Kemenag RI)
class QuranApiService {
  static const String _base      = 'https://api.alquran.cloud/v1';
  static const String _audioBase = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy';
  static const String _tafsirBase = 'https://quranenc.com/api/v1';

  // ── Daftar Surah ─────────────────────────────────────────────────────────

  Future<List<Surah>> fetchSurahList() async {
    final res = await http.get(Uri.parse('$_base/surah')).timeout(const Duration(seconds: 10));
    _checkStatus(res, 'Gagal mengambil daftar surah');

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as List;
    return data.map((s) => Surah.fromJson(s as Map<String, dynamic>)).toList();
  }

  // ── Ayat sebuah Surah (Arabic + Terjemahan Indonesia sekaligus) ──────────

  Future<List<Ayah>> fetchSurah(int surahNumber) async {
    // Panggil dua edisi sekaligus secara paralel
    final results = await Future.wait([
      _fetchEdition(surahNumber, 'quran-uthmani'),        // teks Arab
      _fetchEdition(surahNumber, 'id.indonesian'),         // terjemahan RI
    ]);

    final arabicAyahs    = results[0];
    final translationAyahs = results[1];

    return List.generate(arabicAyahs.length, (i) {
      final num = arabicAyahs[i]['numberInSurah'] as int;
      return Ayah(
        surahNumber: surahNumber,
        ayahNumber:  num,
        arabic:      arabicAyahs[i]['text'] as String,
        translation: translationAyahs[i]['text'] as String,
        audioUrl:    '$_audioBase/${ arabicAyahs[i]['number'] }.mp3',
      );
    });
  }

  Future<List<Map<String, dynamic>>> _fetchEdition(int surahNum, String edition) async {
    final res = await http
        .get(Uri.parse('$_base/surah/$surahNum/$edition'))
        .timeout(const Duration(seconds: 10));
    _checkStatus(res, 'Gagal mengambil surah');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(
      (json['data']['ayahs'] as List),
    );
  }

  // ── Tafsir per ayat (Kemenag RI via quranenc.com) ────────────────────────

  Future<String?> fetchTafsir(int surahNumber, int ayahNumber) async {
    try {
      final res = await http
          .get(Uri.parse('$_tafsirBase/translation/aya/indonesian_affairs/$surahNumber/$ayahNumber'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final result = json['result'] as Map<String, dynamic>?;
      return result?['translation'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Pencarian sederhana (by kata dalam terjemahan) ───────────────────────

  Future<List<Map<String, dynamic>>> search(String query) async {
    final res = await http
        .get(Uri.parse('$_base/search/${Uri.encodeComponent(query)}/all/id.indonesian'))
        .timeout(const Duration(seconds: 10));
    _checkStatus(res, 'Pencarian gagal');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final matches = json['data']['matches'] as List? ?? [];
    return List<Map<String, dynamic>>.from(matches);
  }

  void _checkStatus(http.Response res, String msg) {
    if (res.statusCode != 200) throw Exception('$msg (${res.statusCode})');
  }
}
