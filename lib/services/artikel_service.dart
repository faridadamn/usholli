import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/artikel_models.dart';

/// Backend: Supabase (gratis hingga 500MB, REST API otomatis)
/// Setup: buat project di supabase.com → buat tabel sesuai skema di bawah
///
/// SQL untuk buat tabel di Supabase:
/// ─────────────────────────────────
/// create table artikel (
///   id            uuid default gen_random_uuid() primary key,
///   masjid_id     uuid references masjid(id),
///   judul         text not null,
///   konten        text not null,
///   ringkasan     text,
///   kategori_id   text default 'umum',
///   thumbnail_url text,
///   penulis_nama  text default 'Admin',
///   penulis_avatar text,
///   diterbitkan   boolean default false,
///   like_count    int default 0,
///   view_count    int default 0,
///   tags          text[] default '{}',
///   created_at    timestamptz default now(),
///   updated_at    timestamptz
/// );
///
/// -- RLS: publik bisa baca artikel yang sudah diterbitkan
/// alter table artikel enable row level security;
/// create policy "Publik baca artikel" on artikel for select
///   using (diterbitkan = true);
/// create policy "Admin tulis artikel" on artikel for all
///   using (auth.role() = 'authenticated');
///
/// create table komentar (
///   id          uuid default gen_random_uuid() primary key,
///   artikel_id  uuid references artikel(id) on delete cascade,
///   user_id     uuid references auth.users(id),
///   user_name   text not null,
///   user_avatar text,
///   isi         text not null,
///   created_at  timestamptz default now()
/// );
/// alter table komentar enable row level security;
/// create policy "Publik baca komentar" on komentar for select using (true);
/// create policy "User tambah komentar" on komentar for insert
///   with check (auth.uid() = user_id);

class ArtikelService {
  // Ganti dengan URL dan key Supabase project kamu
  static const String _url    = 'https://YOUR_PROJECT.supabase.co/rest/v1';
  static const String _anonKey = 'YOUR_ANON_KEY';

  Map<String, String> get _headers => {
    'apikey':        _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type':  'application/json',
    'Prefer':        'return=representation',
  };

  Map<String, String> _authHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  // ── Ambil daftar artikel (publik) ─────────────────────────────────────────

  Future<List<Artikel>> fetchArtikel({
    String? masjidId,
    String? kategoriId,
    int limit  = 20,
    int offset = 0,
  }) async {
    var query = '$_url/artikel?diterbitkan=eq.true&order=created_at.desc'
        '&limit=$limit&offset=$offset';
    if (masjidId   != null) query += '&masjid_id=eq.$masjidId';
    if (kategoriId != null) query += '&kategori_id=eq.$kategoriId';

    // Join masjid untuk nama
    query += '&select=*,masjid(nama)';

    final res = await http.get(Uri.parse(query), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('Gagal memuat artikel');

    final list = jsonDecode(res.body) as List;
    return list.map((j) {
      final map = Map<String, dynamic>.from(j as Map);
      // Flatten nama masjid dari join
      if (map['masjid'] != null) {
        map['masjid_nama'] = (map['masjid'] as Map)['nama'] ?? '';
      }
      return Artikel.fromJson(map);
    }).toList();
  }

  // ── Artikel terbaru (untuk widget beranda) ────────────────────────────────

  Future<List<Artikel>> fetchTerbaru({String? masjidId, int limit = 5}) =>
      fetchArtikel(masjidId: masjidId, limit: limit);

  // ── Detail artikel + tambah view ─────────────────────────────────────────

  Future<Artikel> fetchDetail(String artikelId) async {
    final res = await http.get(
      Uri.parse('$_url/artikel?id=eq.$artikelId&select=*,masjid(nama)'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('Artikel tidak ditemukan');
    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) throw Exception('Artikel tidak ditemukan');

    final map = Map<String, dynamic>.from(list.first as Map);
    if (map['masjid'] != null) map['masjid_nama'] = (map['masjid'] as Map)['nama'] ?? '';

    // Increment view count (fire & forget)
    _incrementView(artikelId, map['view_count'] as int? ?? 0);

    return Artikel.fromJson(map);
  }

  Future<void> _incrementView(String id, int current) async {
    await http.patch(
      Uri.parse('$_url/artikel?id=eq.$id'),
      headers: _headers,
      body: jsonEncode({'view_count': current + 1}),
    );
  }

  // ── Komentar ──────────────────────────────────────────────────────────────

  Future<List<Komentar>> fetchKomentar(String artikelId) async {
    final res = await http.get(
      Uri.parse('$_url/komentar?artikel_id=eq.$artikelId&order=created_at.asc'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Komentar.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> tambahKomentar({
    required String artikelId,
    required String userId,
    required String userName,
    required String isi,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_url/komentar'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'artikel_id': artikelId,
        'user_id':    userId,
        'user_name':  userName,
        'isi':        isi,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) throw Exception('Gagal mengirim komentar');
  }

  // ── Like (toggle) ─────────────────────────────────────────────────────────

  Future<int> toggleLike(String artikelId, int currentLike, bool isLiked) async {
    final newCount = isLiked ? currentLike - 1 : currentLike + 1;
    await http.patch(
      Uri.parse('$_url/artikel?id=eq.$artikelId'),
      headers: _headers,
      body: jsonEncode({'like_count': newCount}),
    );
    return newCount;
  }

  // ── Admin: Buat artikel baru ──────────────────────────────────────────────

  Future<Artikel> buatArtikel({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_url/artikel'),
      headers: _authHeaders(token),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) throw Exception('Gagal membuat artikel');
    final list = jsonDecode(res.body) as List;
    return Artikel.fromJson(list.first as Map<String, dynamic>);
  }

  // ── Admin: Update artikel ─────────────────────────────────────────────────

  Future<void> updateArtikel({
    required String artikelId,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final res = await http.patch(
      Uri.parse('$_url/artikel?id=eq.$artikelId'),
      headers: _authHeaders(token),
      body: jsonEncode({...data, 'updated_at': DateTime.now().toIso8601String()}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('Gagal mengupdate artikel');
  }

  // ── Admin: Hapus artikel ──────────────────────────────────────────────────

  Future<void> hapusArtikel(String artikelId, String token) async {
    await http.delete(
      Uri.parse('$_url/artikel?id=eq.$artikelId'),
      headers: _authHeaders(token),
    );
  }

  // ── Admin: Toggle terbitkan ───────────────────────────────────────────────

  Future<void> toggleTerbitkan(String artikelId, bool diterbitkan, String token) async {
    await updateArtikel(
      artikelId: artikelId,
      data: {'diterbitkan': diterbitkan},
      token: token,
    );
  }
}
