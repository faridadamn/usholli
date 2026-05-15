enum DonasiStatus { pending, berhasil, gagal, kadaluarsa }
enum DonasiMetode { qris, transfer, ewallet }

class DonasiProgram {
  final String id;
  final String masjidId;
  final String judul;
  final String deskripsi;
  final String emoji;
  final double? targetNominal;    // null = tanpa target
  final double terkumpul;
  final DateTime? deadline;
  final bool aktif;
  final String? thumbnailUrl;

  const DonasiProgram({
    required this.id,
    required this.masjidId,
    required this.judul,
    required this.deskripsi,
    required this.emoji,
    this.targetNominal,
    this.terkumpul = 0,
    this.deadline,
    this.aktif = true,
    this.thumbnailUrl,
  });

  double get persentase => targetNominal != null && targetNominal! > 0
      ? (terkumpul / targetNominal! * 100).clamp(0, 100)
      : 0;

  String get terkumpulStr => _formatRupiah(terkumpul);
  String get targetStr    => targetNominal != null ? _formatRupiah(targetNominal!) : '∞';

  factory DonasiProgram.fromJson(Map<String, dynamic> j) => DonasiProgram(
    id:             j['id'] as String,
    masjidId:       j['masjid_id'] as String,
    judul:          j['judul'] as String,
    deskripsi:      j['deskripsi'] as String? ?? '',
    emoji:          j['emoji'] as String? ?? '🕌',
    targetNominal:  (j['target_nominal'] as num?)?.toDouble(),
    terkumpul:      (j['terkumpul'] as num?)?.toDouble() ?? 0,
    deadline:       j['deadline'] != null ? DateTime.parse(j['deadline'] as String) : null,
    aktif:          j['aktif'] as bool? ?? true,
    thumbnailUrl:   j['thumbnail_url'] as String?,
  );
}

class DonasiTransaksi {
  final String id;
  final String masjidId;
  final String? programId;
  final String? donaturNama;    // null = anonim
  final double nominal;
  final DonasiMetode metode;
  final DonasiStatus status;
  final String? pesanDoa;
  final String? paymentUrl;     // redirect ke Midtrans/Xendit
  final String? orderId;
  final DateTime createdAt;

  const DonasiTransaksi({
    required this.id,
    required this.masjidId,
    this.programId,
    this.donaturNama,
    required this.nominal,
    required this.metode,
    required this.status,
    this.pesanDoa,
    this.paymentUrl,
    this.orderId,
    required this.createdAt,
  });

  String get nominalStr => _formatRupiah(nominal);
  String get statusLabel => switch (status) {
    DonasiStatus.pending    => 'Menunggu',
    DonasiStatus.berhasil   => 'Berhasil',
    DonasiStatus.gagal      => 'Gagal',
    DonasiStatus.kadaluarsa => 'Kadaluarsa',
  };

  factory DonasiTransaksi.fromJson(Map<String, dynamic> j) => DonasiTransaksi(
    id:          j['id'] as String,
    masjidId:    j['masjid_id'] as String,
    programId:   j['program_id'] as String?,
    donaturNama: j['donatur_nama'] as String?,
    nominal:     (j['nominal'] as num).toDouble(),
    metode:      DonasiMetode.values.firstWhere(
                   (m) => m.name == (j['metode'] as String? ?? 'qris'),
                   orElse: () => DonasiMetode.qris),
    status:      DonasiStatus.values.firstWhere(
                   (s) => s.name == (j['status'] as String? ?? 'pending'),
                   orElse: () => DonasiStatus.pending),
    pesanDoa:    j['pesan_doa'] as String?,
    paymentUrl:  j['payment_url'] as String?,
    orderId:     j['order_id'] as String?,
    createdAt:   DateTime.parse(j['created_at'] as String),
  );
}

// Laporan keuangan bulanan (untuk transparansi)
class LaporanBulan {
  final int tahun;
  final int bulan;
  final double totalPemasukan;
  final double totalPengeluaran;
  final List<ItemLaporan> pemasukan;
  final List<ItemLaporan> pengeluaran;

  const LaporanBulan({
    required this.tahun,
    required this.bulan,
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.pemasukan,
    required this.pengeluaran,
  });

  double get saldo => totalPemasukan - totalPengeluaran;

  String get bulanStr {
    const m = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${m[bulan]} $tahun';
  }

  factory LaporanBulan.fromJson(Map<String, dynamic> j) => LaporanBulan(
    tahun:              j['tahun'] as int,
    bulan:              j['bulan'] as int,
    totalPemasukan:     (j['total_pemasukan'] as num).toDouble(),
    totalPengeluaran:   (j['total_pengeluaran'] as num).toDouble(),
    pemasukan:   (j['pemasukan'] as List? ?? [])
                   .map((x) => ItemLaporan.fromJson(x as Map<String, dynamic>)).toList(),
    pengeluaran: (j['pengeluaran'] as List? ?? [])
                   .map((x) => ItemLaporan.fromJson(x as Map<String, dynamic>)).toList(),
  );
}

class ItemLaporan {
  final String keterangan;
  final double nominal;
  final DateTime tanggal;

  const ItemLaporan({required this.keterangan, required this.nominal, required this.tanggal});

  String get nominalStr => _formatRupiah(nominal);
  String get tglStr {
    const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${tanggal.day} ${m[tanggal.month-1]}';
  }

  factory ItemLaporan.fromJson(Map<String, dynamic> j) => ItemLaporan(
    keterangan: j['keterangan'] as String,
    nominal:    (j['nominal'] as num).toDouble(),
    tanggal:    DateTime.parse(j['tanggal'] as String),
  );
}

// Nominal cepat pilih
const List<double> nominalCepat = [10000, 20000, 50000, 100000, 200000, 500000];

String _formatRupiah(double n) {
  if (n >= 1000000000) return 'Rp ${(n/1000000000).toStringAsFixed(1)} M';
  if (n >= 1000000)    return 'Rp ${(n/1000000).toStringAsFixed(1)} Jt';
  if (n >= 1000)       return 'Rp ${(n/1000).toStringAsFixed(0)} Rb';
  return 'Rp ${n.toStringAsFixed(0)}';
}

String formatRupiahFull(double n) {
  final parts = n.toStringAsFixed(0).split('').reversed.toList();
  final result = <String>[];
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && i % 3 == 0) result.add('.');
    result.add(parts[i]);
  }
  return 'Rp ${result.reversed.join('')}';
}
