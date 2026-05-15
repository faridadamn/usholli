// ── User ─────────────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final String nomorHp;
  final String nama;
  final String? avatar;
  final String? masjidId;       // masjid aktif saat ini
  final List<String> masjidIds; // semua masjid yang diikuti
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.nomorHp,
    required this.nama,
    this.avatar,
    this.masjidId,
    this.masjidIds = const [],
    required this.createdAt,
  });

  AppUser copyWith({String? nama, String? avatar, String? masjidId, List<String>? masjidIds}) =>
      AppUser(
        id: id, nomorHp: nomorHp,
        nama: nama ?? this.nama,
        avatar: avatar ?? this.avatar,
        masjidId: masjidId ?? this.masjidId,
        masjidIds: masjidIds ?? this.masjidIds,
        createdAt: createdAt,
      );

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id:        j['id'] as String,
    nomorHp:   j['nomor_hp'] as String,
    nama:      j['nama'] as String? ?? 'Jamaah',
    avatar:    j['avatar'] as String?,
    masjidId:  j['masjid_id'] as String?,
    masjidIds: List<String>.from(j['masjid_ids'] as List? ?? []),
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'nomor_hp': nomorHp, 'nama': nama,
    'avatar': avatar, 'masjid_id': masjidId, 'masjid_ids': masjidIds,
  };
}

// ── Masjid ────────────────────────────────────────────────────────────────────

class Masjid {
  final String id;
  final String nama;
  final String alamat;
  final String kota;
  final String provinsi;
  final double latitude;
  final double longitude;
  final String? fotoUrl;
  final String? pengumumanSingkat;
  final int jamaahCount;
  final bool terverifikasi;
  final String adminId;

  const Masjid({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.kota,
    required this.provinsi,
    required this.latitude,
    required this.longitude,
    this.fotoUrl,
    this.pengumumanSingkat,
    this.jamaahCount = 0,
    this.terverifikasi = false,
    required this.adminId,
  });

  String get lokasi => '$kota, $provinsi';

  factory Masjid.fromJson(Map<String, dynamic> j) => Masjid(
    id:                  j['id'] as String,
    nama:                j['nama'] as String,
    alamat:              j['alamat'] as String? ?? '',
    kota:                j['kota'] as String? ?? '',
    provinsi:            j['provinsi'] as String? ?? '',
    latitude:            (j['latitude'] as num?)?.toDouble() ?? 0,
    longitude:           (j['longitude'] as num?)?.toDouble() ?? 0,
    fotoUrl:             j['foto_url'] as String?,
    pengumumanSingkat:   j['pengumuman_singkat'] as String?,
    jamaahCount:         j['jamaah_count'] as int? ?? 0,
    terverifikasi:       j['terverifikasi'] as bool? ?? false,
    adminId:             j['admin_id'] as String? ?? '',
  );
}

// ── Titip Doa ─────────────────────────────────────────────────────────────────

enum DoaStatus { menunggu, dibacakan, ditolak }

class TitipDoa {
  final String id;
  final String masjidId;
  final String userId;
  final String userName;
  final String isiDoa;
  final DoaStatus status;
  final DateTime createdAt;
  final bool anonim;

  const TitipDoa({
    required this.id,
    required this.masjidId,
    required this.userId,
    required this.userName,
    required this.isiDoa,
    this.status = DoaStatus.menunggu,
    required this.createdAt,
    this.anonim = false,
  });

  String get statusLabel => switch (status) {
    DoaStatus.menunggu   => 'Menunggu',
    DoaStatus.dibacakan  => 'Sudah Dibacakan',
    DoaStatus.ditolak    => 'Ditolak',
  };

  factory TitipDoa.fromJson(Map<String, dynamic> j) => TitipDoa(
    id:        j['id'] as String,
    masjidId:  j['masjid_id'] as String,
    userId:    j['user_id'] as String,
    userName:  j['user_name'] as String? ?? 'Hamba Allah',
    isiDoa:    j['isi_doa'] as String,
    status:    DoaStatus.values.firstWhere(
                 (s) => s.name == (j['status'] as String? ?? 'menunggu'),
                 orElse: () => DoaStatus.menunggu),
    createdAt: DateTime.parse(j['created_at'] as String),
    anonim:    j['anonim'] as bool? ?? false,
  );
}

// ── Undangan Acara ────────────────────────────────────────────────────────────

class JenisAcara {
  final String id;
  final String nama;
  final String emoji;

  const JenisAcara({required this.id, required this.nama, required this.emoji});

  static const List<JenisAcara> all = [
    JenisAcara(id: 'tahlilan',     nama: 'Tahlilan',       emoji: '🤲'),
    JenisAcara(id: 'yasinan',      nama: 'Yasinan',        emoji: '📖'),
    JenisAcara(id: 'syukuran',     nama: 'Syukuran',       emoji: '🎉'),
    JenisAcara(id: 'aqiqah',       nama: 'Aqiqah',         emoji: '🐑'),
    JenisAcara(id: 'walimah',      nama: 'Walimah Nikah',  emoji: '💍'),
    JenisAcara(id: 'khataman',     nama: 'Khataman',       emoji: '📿'),
    JenisAcara(id: 'pengajian',    nama: 'Pengajian',      emoji: '🕌'),
    JenisAcara(id: 'lainnya',      nama: 'Lainnya',        emoji: '📅'),
  ];

  static JenisAcara byId(String id) =>
      all.firstWhere((j) => j.id == id, orElse: () => all.last);
}

class Undangan {
  final String id;
  final String pembuatId;
  final String pembuatNama;
  final String? masjidId;
  final String jenisId;
  final String judul;
  final String? deskripsi;
  final String alamat;
  final DateTime waktuMulai;
  final DateTime? waktuSelesai;
  final String kodeUndangan;   // 6 karakter unik untuk join via link
  final List<String> pesertaIds;
  final int maxPeserta;
  final DateTime createdAt;

  const Undangan({
    required this.id,
    required this.pembuatId,
    required this.pembuatNama,
    this.masjidId,
    required this.jenisId,
    required this.judul,
    this.deskripsi,
    required this.alamat,
    required this.waktuMulai,
    this.waktuSelesai,
    required this.kodeUndangan,
    this.pesertaIds = const [],
    this.maxPeserta = 500,
    required this.createdAt,
  });

  JenisAcara get jenis => JenisAcara.byId(jenisId);
  int get jumlahPeserta => pesertaIds.length;
  String get shareLink => 'https://usholli.app/undangan/$kodeUndangan';

  String get waktuStr {
    const days = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final d = waktuMulai;
    final jam = '${d.hour.toString().padLeft(2,'0')}.${d.minute.toString().padLeft(2,'0')}';
    return '${days[d.weekday-1]}, ${d.day} ${months[d.month-1]} ${d.year} · $jam WIB';
  }

  factory Undangan.fromJson(Map<String, dynamic> j) => Undangan(
    id:            j['id'] as String,
    pembuatId:     j['pembuat_id'] as String,
    pembuatNama:   j['pembuat_nama'] as String? ?? '',
    masjidId:      j['masjid_id'] as String?,
    jenisId:       j['jenis_id'] as String? ?? 'lainnya',
    judul:         j['judul'] as String,
    deskripsi:     j['deskripsi'] as String?,
    alamat:        j['alamat'] as String? ?? '',
    waktuMulai:    DateTime.parse(j['waktu_mulai'] as String),
    waktuSelesai:  j['waktu_selesai'] != null ? DateTime.parse(j['waktu_selesai'] as String) : null,
    kodeUndangan:  j['kode_undangan'] as String,
    pesertaIds:    List<String>.from(j['peserta_ids'] as List? ?? []),
    maxPeserta:    j['max_peserta'] as int? ?? 500,
    createdAt:     DateTime.parse(j['created_at'] as String),
  );
}
