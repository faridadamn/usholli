import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/komunitas_models.dart';

/// SQL Supabase:
/// ─────────────
/// create table titip_doa (
///   id         uuid default gen_random_uuid() primary key,
///   masjid_id  uuid references masjid(id),
///   user_id    uuid references auth.users(id),
///   user_name  text not null,
///   isi_doa    text not null,
///   status     text default 'menunggu',
///   anonim     boolean default false,
///   created_at timestamptz default now()
/// );
/// alter table titip_doa enable row level security;
/// create policy "User lihat doanya sendiri" on titip_doa for select
///   using (auth.uid() = user_id);
/// create policy "Admin lihat semua doa" on titip_doa for select
///   using (exists (select 1 from masjid where id = masjid_id and admin_id = auth.uid()));
/// create policy "User kirim doa" on titip_doa for insert
///   with check (auth.uid() = user_id);
///
/// create table undangan (
///   id             uuid default gen_random_uuid() primary key,
///   pembuat_id     uuid references auth.users(id),
///   pembuat_nama   text,
///   masjid_id      uuid references masjid(id),
///   jenis_id       text default 'lainnya',
///   judul          text not null,
///   deskripsi      text,
///   alamat         text not null,
///   waktu_mulai    timestamptz not null,
///   waktu_selesai  timestamptz,
///   kode_undangan  text unique not null,
///   peserta_ids    uuid[] default '{}',
///   max_peserta    int default 500,
///   created_at     timestamptz default now()
/// );
/// alter table undangan enable row level security;
/// create policy "Semua bisa baca undangan" on undangan for select using (true);
/// create policy "User buat undangan" on undangan for insert
///   with check (auth.uid() = pembuat_id);
/// create policy "Pembuat bisa edit" on undangan for update
///   using (auth.uid() = pembuat_id);

class KomunitasService {
  static const String _base    = 'https://YOUR_PROJECT.supabase.co/rest/v1';
  static const String _anonKey = 'YOUR_ANON_KEY';

  Map<String, String> _headers([String? token]) => {
    'apikey':        _anonKey,
    'Authorization': 'Bearer ${token ?? _anonKey}',
    'Content-Type':  'application/json',
    'Prefer':        'return=representation',
  };

  // ── Titip Doa ─────────────────────────────────────────────────────────────

  Future<List<TitipDoa>> fetchDoaSaya(String userId, String masjidId, String token) async {
    final res = await http.get(
      Uri.parse('$_base/titip_doa?user_id=eq.$userId&masjid_id=eq.$masjidId&order=created_at.desc'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List)
        .map((j) => TitipDoa.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<TitipDoa> kirimDoa({
    required String masjidId,
    required String userId,
    required String userName,
    required String isiDoa,
    required bool anonim,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/titip_doa'),
      headers: _headers(token),
      body: jsonEncode({
        'masjid_id': masjidId,
        'user_id':   userId,
        'user_name': anonim ? 'Hamba Allah' : userName,
        'isi_doa':   isiDoa,
        'anonim':    anonim,
      }),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) throw Exception('Gagal mengirim doa');
    return TitipDoa.fromJson((jsonDecode(res.body) as List).first as Map<String, dynamic>);
  }

  // ── Undangan Acara ────────────────────────────────────────────────────────

  Future<List<Undangan>> fetchUndanganSaya(String userId, String token) async {
    final res = await http.get(
      Uri.parse('$_base/undangan?or=(pembuat_id.eq.$userId,peserta_ids.cs.{$userId})&order=waktu_mulai.asc'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List)
        .map((j) => Undangan.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Undangan>> fetchUndanganMasjid(String masjidId) async {
    final res = await http.get(
      Uri.parse('$_base/undangan?masjid_id=eq.$masjidId&order=waktu_mulai.asc&limit=20'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List)
        .map((j) => Undangan.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Undangan?> fetchByKode(String kode) async {
    final res = await http.get(
      Uri.parse('$_base/undangan?kode_undangan=eq.$kode'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) return null;
    return Undangan.fromJson(list.first as Map<String, dynamic>);
  }

  Future<Undangan> buatUndangan({
    required String pembuatId,
    required String pembuatNama,
    required Map<String, dynamic> data,
    required String token,
    String? masjidId,
  }) async {
    final kode = _generateKode();
    final res  = await http.post(
      Uri.parse('$_base/undangan'),
      headers: _headers(token),
      body: jsonEncode({
        ...data,
        'pembuat_id':    pembuatId,
        'pembuat_nama':  pembuatNama,
        'masjid_id':     masjidId,
        'kode_undangan': kode,
        'peserta_ids':   [pembuatId],
      }),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) throw Exception('Gagal membuat undangan');
    return Undangan.fromJson((jsonDecode(res.body) as List).first as Map<String, dynamic>);
  }

  Future<Undangan> bergabung(String undanganId, String userId, List<String> currentIds, String token) async {
    final newIds = [...currentIds, userId];
    final res = await http.patch(
      Uri.parse('$_base/undangan?id=eq.$undanganId'),
      headers: _headers(token),
      body: jsonEncode({'peserta_ids': newIds}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Gagal bergabung');
    return Undangan.fromJson((jsonDecode(res.body) as List).first as Map<String, dynamic>);
  }

  String _generateKode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng   = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }
}
