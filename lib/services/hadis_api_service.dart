import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/hadis_models.dart';

/// API: https://api.hadith.gading.dev - gratis, bahasa Indonesia
/// Docs: https://github.com/gadingnst/hadith-api
class HadisApiService {
  static const String _base = 'https://api.hadith.gading.dev';

  // ── Fetch hadis per nomor ─────────────────────────────────────────────────

  Future<Hadis> fetchByNomor(String kitabId, int nomor) async {
    final res = await http
        .get(Uri.parse('$_base/books/$kitabId/$nomor'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Hadis tidak ditemukan');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final contents = data['contents'] as Map<String, dynamic>? ?? data;
    final kitab = HadisKitab.all.firstWhere((k) => k.id == kitabId, orElse: () => HadisKitab.all.first);
    return Hadis.fromJson(contents, kitab.nama);
  }

  // ── Fetch acak dari kitab tertentu ────────────────────────────────────────

  Future<Hadis> fetchRandom(String kitabId) async {
    final kitab = HadisKitab.all.firstWhere((k) => k.id == kitabId);
    final nomor = Random().nextInt(kitab.totalHadis) + 1;
    return fetchByNomor(kitabId, nomor);
  }

  // ── "Hadis Hari Ini" — deterministik berdasarkan tanggal ─────────────────
  // Setiap hari jamaah semua masjid mendapat hadis yang sama
  // (konsisten tanpa perlu backend)

  Future<Hadis> fetchHariIni() async {
    final now    = DateTime.now();
    final epoch  = DateTime(2024, 1, 1);
    final dayNum = now.difference(epoch).inDays;

    // Rotasi lintas kitab setiap hari
    const kitabs  = HadisKitab.all;
    final kitab   = kitabs[dayNum % kitabs.length];
    final nomor   = (dayNum % kitab.totalHadis) + 1;

    return fetchByNomor(kitab.id, nomor);
  }

  // ── Fetch list hadis per kitab (pagination) ───────────────────────────────

  Future<List<Hadis>> fetchList(String kitabId, {int page = 1, int limit = 20}) async {
    final start = ((page - 1) * limit) + 1;
    final end = start + limit - 1;
    final res = await http
        .get(Uri.parse('$_base/books/$kitabId?range=$start-$end'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('Gagal mengambil daftar hadis');

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = data['hadiths'] as List? ?? json['data'] as List? ?? [];
    final kitab = HadisKitab.all.firstWhere((k) => k.id == kitabId).nama;
    return items.map((h) => Hadis.fromJson(h as Map<String, dynamic>, kitab)).toList();
  }

  // ── Cari hadis berdasarkan kata kunci ─────────────────────────────────────

  Future<List<Hadis>> search(String query, {String? kitabId}) async {
    final path = kitabId != null
        ? '$_base/books/$kitabId/search?q=${Uri.encodeComponent(query)}'
        : '$_base/search?q=${Uri.encodeComponent(query)}';

    final res = await http
        .get(Uri.parse(path))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return [];

    final json  = jsonDecode(res.body) as Map<String, dynamic>;
    final items = json['data'] as List? ?? [];
    return items.map((h) {
      final kId  = h['book_id'] as String? ?? kitabId ?? 'bukhari';
      final kitab = HadisKitab.all.firstWhere((k) => k.id == kId, orElse: () => HadisKitab.all[2]).nama;
      return Hadis.fromJson(h as Map<String, dynamic>, kitab);
    }).toList();
  }
}
