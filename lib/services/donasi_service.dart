import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/donasi_models.dart';

/// Backend  : Supabase (gratis)
/// Payment  : Midtrans Snap (free sandbox → production bayar per transaksi ~0.7%)
///
/// SQL Supabase:
/// ─────────────
/// create table donasi_program (
///   id              uuid default gen_random_uuid() primary key,
///   masjid_id       uuid references masjid(id),
///   judul           text not null,
///   deskripsi       text,
///   emoji           text default '🕌',
///   target_nominal  numeric,
///   terkumpul       numeric default 0,
///   deadline        timestamptz,
///   aktif           boolean default true,
///   thumbnail_url   text,
///   created_at      timestamptz default now()
/// );
///
/// create table donasi_transaksi (
///   id            uuid default gen_random_uuid() primary key,
///   masjid_id     uuid references masjid(id),
///   program_id    uuid references donasi_program(id),
///   donatur_nama  text,
///   nominal       numeric not null,
///   metode        text default 'qris',
///   status        text default 'pending',
///   pesan_doa     text,
///   payment_url   text,
///   order_id      text unique,
///   created_at    timestamptz default now()
/// );
///
/// create table laporan_keuangan (
///   id                uuid default gen_random_uuid() primary key,
///   masjid_id         uuid references masjid(id),
///   tahun             int,
///   bulan             int,
///   total_pemasukan   numeric default 0,
///   total_pengeluaran numeric default 0,
///   pemasukan         jsonb default '[]',
///   pengeluaran       jsonb default '[]',
///   created_at        timestamptz default now()
/// );
///
/// -- Trigger: update terkumpul saat donasi berhasil
/// create or replace function update_terkumpul()
/// returns trigger as $$
/// begin
///   if NEW.status = 'berhasil' and NEW.program_id is not null then
///     update donasi_program
///     set terkumpul = terkumpul + NEW.nominal
///     where id = NEW.program_id;
///   end if;
///   return NEW;
/// end;
/// $$ language plpgsql;
///
/// create trigger on_donasi_berhasil
///   after update on donasi_transaksi
///   for each row
///   when (OLD.status != 'berhasil' and NEW.status = 'berhasil')
///   execute function update_terkumpul();

class DonasiService {
  static const String _supabaseUrl = 'https://YOUR_PROJECT.supabase.co/rest/v1';
  static const String _anonKey     = 'YOUR_ANON_KEY';

  // Midtrans Snap — sandbox dulu, ganti ke production saat live
  static const String _midtransUrl = 'https://app.sandbox.midtrans.com/snap/v1/transactions';
  static const String _midtransKey = 'YOUR_MIDTRANS_SERVER_KEY'; // Base64-encode: "serverKey:"

  Map<String, String> get _headers => {
    'apikey':        _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type':  'application/json',
  };

  // ── Program donasi ────────────────────────────────────────────────────────

  Future<List<DonasiProgram>> fetchProgram(String masjidId) async {
    final res = await http.get(
      Uri.parse('$_supabaseUrl/donasi_program?masjid_id=eq.$masjidId&aktif=eq.true&order=created_at.desc'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('Gagal memuat program donasi');
    final list = jsonDecode(res.body) as List;
    return list.map((j) => DonasiProgram.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Buat transaksi + redirect ke Midtrans Snap ───────────────────────────

  Future<DonasiTransaksi> buatTransaksi({
    required String masjidId,
    required double nominal,
    required String metode,
    String? programId,
    String? donaturNama,
    String? donaturEmail,
    String? pesanDoa,
  }) async {
    // 1. Buat order_id unik
    final orderId = 'USHOLLI-${DateTime.now().millisecondsSinceEpoch}-${_randStr(6)}';

    // 2. Simpan transaksi pending ke Supabase
    final insertRes = await http.post(
      Uri.parse('$_supabaseUrl/donasi_transaksi'),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode({
        'masjid_id':    masjidId,
        'program_id':   programId,
        'donatur_nama': donaturNama ?? 'Hamba Allah',
        'nominal':      nominal,
        'metode':       metode,
        'status':       'pending',
        'pesan_doa':    pesanDoa,
        'order_id':     orderId,
      }),
    ).timeout(const Duration(seconds: 10));

    if (insertRes.statusCode != 201) throw Exception('Gagal membuat transaksi');
    final txData = (jsonDecode(insertRes.body) as List).first as Map<String, dynamic>;
    final txId = txData['id'] as String;

    // 3. Buat Snap token via Midtrans
    final snapRes = await http.post(
      Uri.parse(_midtransUrl),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_midtransKey:'))}',
      },
      body: jsonEncode({
        'transaction_details': {
          'order_id':     orderId,
          'gross_amount': nominal.toInt(),
        },
        'customer_details': {
          'first_name': donaturNama ?? 'Hamba Allah',
          'email':      donaturEmail ?? 'donatur@usholli.app',
        },
        'item_details': [{
          'id':       programId ?? 'infaq-masjid',
          'price':    nominal.toInt(),
          'quantity': 1,
          'name':     programId != null ? 'Donasi Program' : 'Infaq Masjid',
        }],
        // Aktifkan hanya QRIS dan transfer bank
        'enabled_payments': ['gopay', 'shopeepay', 'qris', 'bca_va', 'bni_va', 'bri_va', 'permata_va'],
        'callbacks': {
          'finish':  'usholli://donasi/finish?order_id=$orderId',
          'unfinish':'usholli://donasi/pending?order_id=$orderId',
          'error':   'usholli://donasi/error?order_id=$orderId',
        },
      }),
    ).timeout(const Duration(seconds: 15));

    String? paymentUrl;
    if (snapRes.statusCode == 201) {
      final snapData = jsonDecode(snapRes.body) as Map<String, dynamic>;
      paymentUrl = snapData['redirect_url'] as String?;

      // Simpan payment URL ke Supabase
      await http.patch(
        Uri.parse('$_supabaseUrl/donasi_transaksi?id=eq.$txId'),
        headers: _headers,
        body: jsonEncode({'payment_url': paymentUrl}),
      );
    }

    return DonasiTransaksi(
      id:          txId,
      masjidId:    masjidId,
      programId:   programId,
      donaturNama: donaturNama,
      nominal:     nominal,
      metode:      DonasiMetode.values.firstWhere((m) => m.name == metode),
      status:      DonasiStatus.pending,
      pesanDoa:    pesanDoa,
      paymentUrl:  paymentUrl,
      orderId:     orderId,
      createdAt:   DateTime.now(),
    );
  }

  // ── Cek status transaksi (polling setelah kembali dari payment) ───────────

  Future<DonasiStatus> cekStatus(String orderId) async {
    final res = await http.get(
      Uri.parse('$_supabaseUrl/donasi_transaksi?order_id=eq.$orderId&select=status'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return DonasiStatus.pending;
    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) return DonasiStatus.pending;
    final statusStr = (list.first as Map)['status'] as String? ?? 'pending';
    return DonasiStatus.values.firstWhere(
      (s) => s.name == statusStr, orElse: () => DonasiStatus.pending,
    );
  }

  // ── Riwayat donasi jamaah (berdasarkan nama / device) ────────────────────

  Future<List<DonasiTransaksi>> fetchRiwayat(String masjidId, {String? donaturNama}) async {
    var url = '$_supabaseUrl/donasi_transaksi?masjid_id=eq.$masjidId&order=created_at.desc&limit=30';
    if (donaturNama != null) url += '&donatur_nama=eq.${Uri.encodeComponent(donaturNama)}';

    final res = await http.get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list.map((j) => DonasiTransaksi.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Laporan keuangan (transparansi) ──────────────────────────────────────

  Future<List<LaporanBulan>> fetchLaporan(String masjidId) async {
    final res = await http.get(
      Uri.parse('$_supabaseUrl/laporan_keuangan?masjid_id=eq.$masjidId&order=tahun.desc,bulan.desc&limit=12'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list.map((j) => LaporanBulan.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Donasi terbaru publik (feed) ──────────────────────────────────────────

  Future<List<DonasiTransaksi>> fetchDonasiTerbaru(String masjidId) async {
    final res = await http.get(
      Uri.parse('$_supabaseUrl/donasi_transaksi?masjid_id=eq.$masjidId&status=eq.berhasil&order=created_at.desc&limit=10'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list.map((j) => DonasiTransaksi.fromJson(j as Map<String, dynamic>)).toList();
  }

  String _randStr(int len) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng   = Random();
    return String.fromCharCodes(
      Iterable.generate(len, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }
}
