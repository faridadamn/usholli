import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/komunitas_models.dart';

/// SQL Supabase:
/// ─────────────
/// create table masjid (
///   id                  uuid default gen_random_uuid() primary key,
///   nama                text not null,
///   alamat              text,
///   kota                text,
///   provinsi            text,
///   latitude            numeric,
///   longitude           numeric,
///   foto_url            text,
///   pengumuman_singkat  text,
///   jamaah_count        int default 0,
///   terverifikasi       boolean default false,
///   admin_id            uuid references auth.users(id),
///   created_at          timestamptz default now()
/// );
/// alter table masjid enable row level security;
/// create policy "Semua bisa baca masjid" on masjid for select using (true);
/// create policy "Admin masjid bisa update" on masjid for update
///   using (auth.uid() = admin_id);

class MasjidService {
  static const String _base =
      'https://gqmwnzwjogclrtsaggba.supabase.co/rest/v1';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdxbXduendqb2djbHJ0c2FnZ2JhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4MjE0NjQsImV4cCI6MjA5NDM5NzQ2NH0.0KzbCjgbCYCfyxFxXDD35UYoa94HUQz8xh_haQmMffY';

  Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      };

  // ── Cari masjid (by nama / kota) ──────────────────────────────────────────

  Future<List<Masjid>> cari(String query) async {
    final res = await http
        .get(
          Uri.parse(
              '$_base/masjid?or=(nama.ilike.*${Uri.encodeComponent(query)}*,kota.ilike.*${Uri.encodeComponent(query)}*)&limit=20'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Masjid.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Masjid terdekat (berdasarkan koordinat) ───────────────────────────────

  Future<List<Masjid>> terdekat(
      {required double lat, required double lng}) async {
    // Supabase PostGIS: order by jarak
    final res = await http
        .get(
          Uri.parse('$_base/masjid?order=latitude.asc&limit=10'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    final masjids =
        list.map((j) => Masjid.fromJson(j as Map<String, dynamic>)).toList();

    // Sort by jarak secara manual (Haversine sederhana)
    masjids.sort((a, b) {
      final da = _jarak(lat, lng, a.latitude, a.longitude);
      final db = _jarak(lat, lng, b.latitude, b.longitude);
      return da.compareTo(db);
    });
    return masjids.take(10).toList();
  }

  // ── Tambah masjid baru ───────────────────────────────────────────────────

  Future<Masjid> tambah(Masjid masjid) async {
    final res = await http
        .post(
          Uri.parse('$_base/masjid?select=*'),
          headers: {
            ..._headers,
            'Prefer': 'return=representation',
          },
          body: jsonEncode(
              _toPayload(masjid, includeAdmin: masjid.adminId.isNotEmpty)),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) {
      throw Exception(_errorMessage(res.body, 'Gagal menambahkan masjid'));
    }

    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) {
      throw Exception('Masjid berhasil dibuat, tapi data tidak dikembalikan');
    }
    return Masjid.fromJson(list.first as Map<String, dynamic>);
  }

  // ── Update masjid ────────────────────────────────────────────────────────

  Future<Masjid> update(Masjid masjid) async {
    final res = await http
        .patch(
          Uri.parse('$_base/masjid?id=eq.${masjid.id}&select=*'),
          headers: {
            ..._headers,
            'Prefer': 'return=representation',
          },
          body: jsonEncode(
              _toPayload(masjid, includeAdmin: masjid.adminId.isNotEmpty)),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res.body, 'Gagal memperbarui masjid'));
    }

    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) throw Exception('Masjid tidak ditemukan');
    return Masjid.fromJson(list.first as Map<String, dynamic>);
  }

  // ── Detail masjid ─────────────────────────────────────────────────────────

  Future<Masjid> detail(String masjidId) async {
    final res = await http
        .get(
          Uri.parse('$_base/masjid?id=eq.$masjidId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('Masjid tidak ditemukan');
    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) throw Exception('Masjid tidak ditemukan');
    return Masjid.fromJson(list.first as Map<String, dynamic>);
  }

  // ── Daftar masjid yang diikuti user ───────────────────────────────────────

  Future<List<Masjid>> masjidSaya(List<String> masjidIds) async {
    if (masjidIds.isEmpty) return [];
    final ids = masjidIds.map((id) => '"$id"').join(',');
    final res = await http
        .get(
          Uri.parse('$_base/masjid?id=in.($ids)'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Masjid.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Jarak Haversine (km) ──────────────────────────────────────────────────

  double _jarak(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        _sin2(dLat / 2) + _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin2(dLng / 2);
    return r * 2 * _asin(_sqrt(a));
  }

  double _rad(double d) => d * math.pi / 180;

  double _sin2(double x) {
    final s = math.sin(x);
    return s * s;
  }

  double _cos(double x) => math.cos(x);
  double _asin(double x) => math.asin(x);
  double _sqrt(double x) => math.sqrt(x);

  String jarakStr(double lat1, double lng1, double lat2, double lng2) {
    final km = jarakKm(lat1, lng1, lat2, lng2);
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  double jarakKm(double lat1, double lng1, double lat2, double lng2) {
    return _jarak(lat1, lng1, lat2, lng2);
  }

  Map<String, dynamic> _toPayload(Masjid masjid, {required bool includeAdmin}) {
    final payload = <String, dynamic>{
      'nama': masjid.nama,
      'alamat': masjid.alamat,
      'kota': masjid.kota,
      'provinsi': masjid.provinsi,
      'latitude': masjid.latitude,
      'longitude': masjid.longitude,
      'foto_url': masjid.fotoUrl,
      'pengumuman_singkat': masjid.pengumumanSingkat,
      'jamaah_count': masjid.jamaahCount,
      'terverifikasi': masjid.terverifikasi,
    };

    if (includeAdmin) payload['admin_id'] = masjid.adminId;
    return payload;
  }

  String _errorMessage(String body, String fallback) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] as String? ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
