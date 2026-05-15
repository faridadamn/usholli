import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/komunitas_models.dart';

/// Auth flow:
///   1. Kirim OTP → Supabase Phone Auth (pakai Twilio di belakang, gratis 10 SMS/hari)
///      Fallback: WhatsApp OTP via Fonnte (murah, Rp 150/pesan)
///   2. Verify OTP → dapat access token
///   3. Upsert profil user ke tabel `profiles`
///
/// SQL Supabase:
/// ─────────────
/// create table profiles (
///   id         uuid references auth.users primary key,
///   nomor_hp   text unique not null,
///   nama       text default 'Jamaah',
///   avatar     text,
///   masjid_id  uuid references masjid(id),
///   masjid_ids uuid[] default '{}',
///   created_at timestamptz default now()
/// );
/// alter table profiles enable row level security;
/// create policy "User lihat profil sendiri" on profiles
///   for select using (auth.uid() = id);
/// create policy "User update profil sendiri" on profiles
///   for update using (auth.uid() = id);
/// create policy "Auto insert saat register" on profiles
///   for insert with check (auth.uid() = id);

class AuthService {
  static const String _supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String _anonKey     = 'YOUR_ANON_KEY';

  static const String _keyToken    = 'auth_token';
  static const String _keyRefresh  = 'auth_refresh';
  static const String _keyUserId   = 'auth_user_id';
  static const String _keyUserJson = 'auth_user_json';

  Map<String, String> get _headers => {
    'apikey':       _anonKey,
    'Content-Type': 'application/json',
  };

  Map<String, String> authHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  // ── Kirim OTP ────────────────────────────────────────────────────────────

  Future<void> kirimOtp(String nomorHp) async {
    // Format E.164: +628xxxxxxxx
    final hp = _toE164(nomorHp);

    final res = await http.post(
      Uri.parse('$_supabaseUrl/auth/v1/otp'),
      headers: _headers,
      body: jsonEncode({'phone': hp, 'channel': 'sms'}),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['msg'] ?? 'Gagal mengirim OTP');
    }
  }

  // ── Verifikasi OTP ────────────────────────────────────────────────────────

  Future<({String token, String userId})> verifyOtp(String nomorHp, String otp) async {
    final hp  = _toE164(nomorHp);

    final res = await http.post(
      Uri.parse('$_supabaseUrl/auth/v1/verify'),
      headers: _headers,
      body: jsonEncode({'phone': hp, 'token': otp, 'type': 'sms'}),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('OTP salah atau kadaluarsa');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token   = data['access_token'] as String;
    final refresh = data['refresh_token'] as String;
    final userId  = (data['user'] as Map)['id'] as String;

    // Simpan session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken,   token);
    await prefs.setString(_keyRefresh, refresh);
    await prefs.setString(_keyUserId,  userId);

    return (token: token, userId: userId);
  }

  // ── Upsert profil ─────────────────────────────────────────────────────────

  Future<AppUser> upsertProfil({
    required String userId,
    required String nomorHp,
    required String token,
    String? nama,
  }) async {
    final res = await http.post(
      Uri.parse('$_supabaseUrl/rest/v1/profiles'),
      headers: {
        ...authHeaders(token),
        'Prefer': 'resolution=merge-duplicates,return=representation',
      },
      body: jsonEncode({
        'id':       userId,
        'nomor_hp': _toE164(nomorHp),
        if (nama != null) 'nama': nama,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Gagal menyimpan profil');
    }

    final list = jsonDecode(res.body) as List;
    final user = AppUser.fromJson(list.first as Map<String, dynamic>);

    // Cache user
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserJson, jsonEncode(user.toJson()));

    return user;
  }

  // ── Load session yang sudah ada ───────────────────────────────────────────

  Future<({AppUser user, String token})?> loadSession() async {
    final prefs  = await SharedPreferences.getInstance();
    final token  = prefs.getString(_keyToken);
    final cached = prefs.getString(_keyUserJson);
    if (token == null || cached == null) return null;
    try {
      final user = AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      return (user: user, token: token);
    } catch (_) { return null; }
  }

  // ── Update profil ─────────────────────────────────────────────────────────

  Future<void> updateProfil(String userId, String token, Map<String, dynamic> data) async {
    await http.patch(
      Uri.parse('$_supabaseUrl/rest/v1/profiles?id=eq.$userId'),
      headers: authHeaders(token),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));

    // Update cache
    final prefs  = await SharedPreferences.getInstance();
    final cached = prefs.getString(_keyUserJson);
    if (cached != null) {
      final map = Map<String, dynamic>.from(jsonDecode(cached) as Map);
      map.addAll(data);
      await prefs.setString(_keyUserJson, jsonEncode(map));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefresh);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserJson);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _toE164(String hp) {
    final clean = hp.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('62')) return '+$clean';
    if (clean.startsWith('0'))  return '+62${clean.substring(1)}';
    return '+62$clean';
  }
}
