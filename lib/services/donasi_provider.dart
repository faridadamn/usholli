import 'package:flutter/foundation.dart';
import '../models/donasi_models.dart';
import '../services/donasi_service.dart';

enum DonasiLoadState { idle, loading, loaded, error }
enum PaymentState    { idle, processing, waitingPayment, success, failed }

// Ganti dengan masjid ID jamaah yang sedang aktif
// (nanti diambil dari auth/profil masjid)
const String _demoMasjidId = 'YOUR_MASJID_UUID';

class DonasiProvider extends ChangeNotifier {
  final DonasiService _svc = DonasiService();

  // ── Program ───────────────────────────────────────────────────────────────
  List<DonasiProgram> _programs     = [];
  DonasiLoadState     _programState = DonasiLoadState.idle;

  List<DonasiProgram> get programs      => _programs;
  DonasiLoadState     get programState  => _programState;

  // ── Laporan keuangan ──────────────────────────────────────────────────────
  List<LaporanBulan> _laporan      = [];
  DonasiLoadState    _laporanState = DonasiLoadState.idle;

  List<LaporanBulan> get laporan      => _laporan;
  DonasiLoadState    get laporanState => _laporanState;

  // ── Feed donasi terbaru ───────────────────────────────────────────────────
  List<DonasiTransaksi> _feed = [];
  List<DonasiTransaksi> get feed => _feed;

  // ── Form donasi ───────────────────────────────────────────────────────────
  double       _nominal        = 50000;
  String       _donaturNama    = '';
  String       _pesanDoa       = '';
  String       _metode         = 'qris';
  DonasiProgram? _selectedProgram;
  PaymentState _paymentState  = PaymentState.idle;
  DonasiTransaksi? _lastTx;
  String?      _paymentError;

  double         get nominal        => _nominal;
  String         get donaturNama    => _donaturNama;
  String         get pesanDoa       => _pesanDoa;
  String         get metode         => _metode;
  DonasiProgram? get selectedProgram => _selectedProgram;
  PaymentState   get paymentState   => _paymentState;
  DonasiTransaksi? get lastTx       => _lastTx;
  String?        get paymentError   => _paymentError;

  // ── Load program ──────────────────────────────────────────────────────────

  Future<void> loadPrograms() async {
    _programState = DonasiLoadState.loading;
    notifyListeners();
    try {
      _programs     = await _svc.fetchProgram(_demoMasjidId);
      _programState = DonasiLoadState.loaded;
      _feed         = await _svc.fetchDonasiTerbaru(_demoMasjidId);
    } catch (_) {
      _programState = DonasiLoadState.error;
      // Demo data saat offline
      _programs = _demoPrograms();
    }
    notifyListeners();
  }

  // ── Load laporan ──────────────────────────────────────────────────────────

  Future<void> loadLaporan() async {
    _laporanState = DonasiLoadState.loading;
    notifyListeners();
    try {
      _laporan      = await _svc.fetchLaporan(_demoMasjidId);
      _laporanState = DonasiLoadState.loaded;
    } catch (_) {
      _laporanState = DonasiLoadState.error;
      _laporan      = _demoLaporan();
    }
    notifyListeners();
  }

  // ── Form setters ──────────────────────────────────────────────────────────

  void setNominal(double v)           { _nominal = v; notifyListeners(); }
  void setDonaturNama(String v)       { _donaturNama = v; notifyListeners(); }
  void setPesanDoa(String v)          { _pesanDoa = v; notifyListeners(); }
  void setMetode(String v)            { _metode = v; notifyListeners(); }
  void setProgram(DonasiProgram? p)   { _selectedProgram = p; notifyListeners(); }

  // ── Buat transaksi & buka payment ─────────────────────────────────────────

  Future<String?> prosesdonasi() async {
    if (_nominal < 1000) {
      _paymentError = 'Nominal minimal Rp 1.000';
      notifyListeners();
      return null;
    }

    _paymentState = PaymentState.processing;
    _paymentError = null;
    notifyListeners();

    try {
      final tx = await _svc.buatTransaksi(
        masjidId:    _demoMasjidId,
        nominal:     _nominal,
        metode:      _metode,
        programId:   _selectedProgram?.id,
        donaturNama: _donaturNama.isNotEmpty ? _donaturNama : null,
        pesanDoa:    _pesanDoa.isNotEmpty ? _pesanDoa : null,
      );

      _lastTx       = tx;
      _paymentState = PaymentState.waitingPayment;
      notifyListeners();
      return tx.paymentUrl; // buka di WebView / browser
    } catch (e) {
      _paymentState = PaymentState.failed;
      _paymentError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> konfirmasiPembayaran() async {
    if (_lastTx?.orderId == null) return;
    final status = await _svc.cekStatus(_lastTx!.orderId!);
    _paymentState = status == DonasiStatus.berhasil
        ? PaymentState.success
        : PaymentState.failed;
    notifyListeners();
    if (_paymentState == PaymentState.success) {
      await loadPrograms(); // refresh terkumpul
    }
  }

  void resetPayment() {
    _paymentState = PaymentState.idle;
    _lastTx       = null;
    _paymentError = null;
    _nominal      = 50000;
    _donaturNama  = '';
    _pesanDoa     = '';
    notifyListeners();
  }

  // ── Demo data saat offline / belum setup Supabase ─────────────────────────

  List<DonasiProgram> _demoPrograms() => [
    DonasiProgram(
      id: 'demo-1', masjidId: '', judul: 'Renovasi Masjid',
      deskripsi: 'Perbaikan atap dan pengecatan ulang masjid',
      emoji: '🏗️', targetNominal: 50000000, terkumpul: 32500000,
    ),
    DonasiProgram(
      id: 'demo-2', masjidId: '', judul: 'Beli Karpet Baru',
      deskripsi: 'Karpet sajadah lantai utama dan selasar',
      emoji: '🟩', targetNominal: 8000000, terkumpul: 5200000,
    ),
    DonasiProgram(
      id: 'demo-3', masjidId: '', judul: 'Infaq Operasional',
      deskripsi: 'Listrik, air, kebersihan, dan kegiatan rutin',
      emoji: '💡', targetNominal: null, terkumpul: 1750000,
    ),
  ];

  List<LaporanBulan> _demoLaporan() {
    final now = DateTime.now();
    return [
      LaporanBulan(
        tahun: now.year, bulan: now.month,
        totalPemasukan: 4500000, totalPengeluaran: 1800000,
        pemasukan: [
          ItemLaporan(keterangan: 'Infaq Jumat', nominal: 2100000, tanggal: DateTime(now.year, now.month, 7)),
          ItemLaporan(keterangan: 'Donasi Renovasi', nominal: 1500000, tanggal: DateTime(now.year, now.month, 12)),
          ItemLaporan(keterangan: 'Zakat Fitrah', nominal: 900000, tanggal: DateTime(now.year, now.month, 20)),
        ],
        pengeluaran: [
          ItemLaporan(keterangan: 'Listrik & Air', nominal: 450000, tanggal: DateTime(now.year, now.month, 5)),
          ItemLaporan(keterangan: 'Kebersihan', nominal: 300000, tanggal: DateTime(now.year, now.month, 10)),
          ItemLaporan(keterangan: 'Perbaikan Sound System', nominal: 1050000, tanggal: DateTime(now.year, now.month, 18)),
        ],
      ),
    ];
  }
}
