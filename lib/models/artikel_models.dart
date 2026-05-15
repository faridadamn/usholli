class ArtikelKategori {
  final String id;
  final String nama;
  final String emoji;

  const ArtikelKategori({required this.id, required this.nama, required this.emoji});

  static const List<ArtikelKategori> all = [
    ArtikelKategori(id: 'umum',      nama: 'Umum',        emoji: '📌'),
    ArtikelKategori(id: 'fiqih',     nama: 'Fiqih',       emoji: '📖'),
    ArtikelKategori(id: 'akidah',    nama: 'Akidah',      emoji: '🌙'),
    ArtikelKategori(id: 'akhlak',    nama: 'Akhlak',      emoji: '🤲'),
    ArtikelKategori(id: 'pengumuman',nama: 'Pengumuman',  emoji: '📢'),
    ArtikelKategori(id: 'kajian',    nama: 'Kajian',      emoji: '🕌'),
    ArtikelKategori(id: 'ramadan',   nama: 'Ramadan',     emoji: '⭐'),
    ArtikelKategori(id: 'sosial',    nama: 'Sosial',      emoji: '🤝'),
  ];

  static ArtikelKategori byId(String id) =>
      all.firstWhere((k) => k.id == id, orElse: () => all.first);
}

class Artikel {
  final String id;
  final String masjidId;
  final String masjidNama;
  final String judul;
  final String konten;         // Markdown / HTML
  final String ringkasan;      // preview 2-3 kalimat
  final String kategoriId;
  final String? thumbnailUrl;
  final String penulisNama;
  final String? penulisAvatar;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool diterbitkan;
  final int likeCount;
  final int viewCount;
  final List<String> tags;

  const Artikel({
    required this.id,
    required this.masjidId,
    required this.masjidNama,
    required this.judul,
    required this.konten,
    required this.ringkasan,
    required this.kategoriId,
    this.thumbnailUrl,
    required this.penulisNama,
    this.penulisAvatar,
    required this.createdAt,
    this.updatedAt,
    this.diterbitkan = true,
    this.likeCount   = 0,
    this.viewCount   = 0,
    this.tags        = const [],
  });

  ArtikelKategori get kategori => ArtikelKategori.byId(kategoriId);

  String get waktuPublikasi {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)    return '${diff.inHours} jam lalu';
    if (diff.inDays < 7)      return '${diff.inDays} hari lalu';
    const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${createdAt.day} ${m[createdAt.month-1]} ${createdAt.year}';
  }

  factory Artikel.fromJson(Map<String, dynamic> j) => Artikel(
    id:           j['id'] as String,
    masjidId:     j['masjid_id'] as String,
    masjidNama:   j['masjid_nama'] as String? ?? '',
    judul:        j['judul'] as String,
    konten:       j['konten'] as String,
    ringkasan:    j['ringkasan'] as String? ?? '',
    kategoriId:   j['kategori_id'] as String? ?? 'umum',
    thumbnailUrl: j['thumbnail_url'] as String?,
    penulisNama:  j['penulis_nama'] as String? ?? 'Admin',
    penulisAvatar:j['penulis_avatar'] as String?,
    createdAt:    DateTime.parse(j['created_at'] as String),
    updatedAt:    j['updated_at'] != null ? DateTime.parse(j['updated_at'] as String) : null,
    diterbitkan:  j['diterbitkan'] as bool? ?? true,
    likeCount:    j['like_count'] as int? ?? 0,
    viewCount:    j['view_count'] as int? ?? 0,
    tags:         List<String>.from(j['tags'] as List? ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id':            id,
    'masjid_id':     masjidId,
    'judul':         judul,
    'konten':        konten,
    'ringkasan':     ringkasan,
    'kategori_id':   kategoriId,
    'thumbnail_url': thumbnailUrl,
    'penulis_nama':  penulisNama,
    'diterbitkan':   diterbitkan,
    'tags':          tags,
  };
}

// Model untuk komentar jamaah
class Komentar {
  final String id;
  final String artikelId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String isi;
  final DateTime createdAt;

  const Komentar({
    required this.id,
    required this.artikelId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.isi,
    required this.createdAt,
  });

  factory Komentar.fromJson(Map<String, dynamic> j) => Komentar(
    id:         j['id'] as String,
    artikelId:  j['artikel_id'] as String,
    userId:     j['user_id'] as String,
    userName:   j['user_name'] as String,
    userAvatar: j['user_avatar'] as String?,
    isi:        j['isi'] as String,
    createdAt:  DateTime.parse(j['created_at'] as String),
  );
}
