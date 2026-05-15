import 'package:hive/hive.dart';

part 'hadis_models.g.dart';

class Hadis {
  final int id;
  final String arab;
  final String terjemahan;
  final String rawi;        // perawi: "Dari Abu Hurairah ra."
  final String sumber;      // "HR. Bukhari No. 1"
  final String kitab;       // "Shahih Bukhari"
  final int nomorHadis;
  final String? penjelasan;

  const Hadis({
    required this.id,
    required this.arab,
    required this.terjemahan,
    required this.rawi,
    required this.sumber,
    required this.kitab,
    required this.nomorHadis,
    this.penjelasan,
  });

  factory Hadis.fromJson(Map<String, dynamic> j, String kitab) {
    String readString(List<String> keys) {
      for (final key in keys) {
        final value = j[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return '';
    }

    final arab = readString(['arab', 'text_ar', 'hadith_arabic']);
    final id = j['number'] as int? ?? j['id'] as int? ?? 0;
    final translation = j['translation'];
    final indo = readString(['id', 'text_id', 'hadith_english', 'english']);
    final rawi = readString(['rawi', 'narrator', 'header']);
    final no = j['number'] as int? ?? j['id'] as int? ?? id;

    return Hadis(
      id:          id,
      arab:        arab,
      terjemahan:  indo.isNotEmpty
          ? indo
          : translation is Map<String, dynamic>
              ? translation['id'] as String? ?? ''
              : '',
      rawi:        rawi.isNotEmpty ? 'Dari $rawi' : '',
      sumber:      'HR. $kitab No. $no',
      kitab:       kitab,
      nomorHadis:  no,
    );
  }
}

// Koleksi kitab hadis yang tersedia
class HadisKitab {
  final String id;       // slug untuk API
  final String nama;
  final String namaAr;
  final int totalHadis;
  final String keterangan;

  const HadisKitab({
    required this.id,
    required this.nama,
    required this.namaAr,
    required this.totalHadis,
    required this.keterangan,
  });

  static const List<HadisKitab> all = [
    HadisKitab(id: 'abu-daud',      nama: 'Abu Daud',      namaAr: 'أبو داود',     totalHadis: 4419,  keterangan: 'Sunan Abu Daud'),
    HadisKitab(id: 'ahmad',         nama: 'Ahmad',         namaAr: 'أحمد',          totalHadis: 4305,  keterangan: 'Musnad Ahmad'),
    HadisKitab(id: 'bukhari',       nama: 'Bukhari',       namaAr: 'البخاري',        totalHadis: 6638,  keterangan: 'Shahih Bukhari'),
    HadisKitab(id: 'darimi',        nama: 'Darimi',        namaAr: 'الدارمي',        totalHadis: 2949,  keterangan: 'Sunan Darimi'),
    HadisKitab(id: 'ibnu-majah',    nama: 'Ibnu Majah',    namaAr: 'ابن ماجه',      totalHadis: 4285,  keterangan: 'Sunan Ibnu Majah'),
    HadisKitab(id: 'malik',         nama: 'Malik',         namaAr: 'مالك',           totalHadis: 1587,  keterangan: 'Muwatta Malik'),
    HadisKitab(id: 'muslim',        nama: 'Muslim',        namaAr: 'مسلم',           totalHadis: 4930,  keterangan: 'Shahih Muslim'),
    HadisKitab(id: 'nasai',         nama: "Nasa'i",        namaAr: 'النسائي',        totalHadis: 5364,  keterangan: "Sunan Nasa'i"),
    HadisKitab(id: 'tirmidzi',      nama: 'Tirmidzi',      namaAr: 'الترمذي',        totalHadis: 3625,  keterangan: 'Sunan Tirmidzi'),
  ];
}

// Hadis yang disimpan offline (hive)
@HiveType(typeId: 3)
class SavedHadis extends HiveObject {
  @HiveField(0) int hadisId;
  @HiveField(1) String kitab;
  @HiveField(2) String arab;
  @HiveField(3) String terjemahan;
  @HiveField(4) String sumber;
  @HiveField(5) DateTime savedAt;

  SavedHadis({
    required this.hadisId,
    required this.kitab,
    required this.arab,
    required this.terjemahan,
    required this.sumber,
    required this.savedAt,
  });
}

// Cache hadis hari ini
@HiveType(typeId: 4)
class CachedHadisHariIni extends HiveObject {
  @HiveField(0) String kitabId;
  @HiveField(1) int nomorHadis;
  @HiveField(2) String arab;
  @HiveField(3) String terjemahan;
  @HiveField(4) String rawi;
  @HiveField(5) String sumber;
  @HiveField(6) String tanggal;  // yyyy-MM-dd

  CachedHadisHariIni({
    required this.kitabId,
    required this.nomorHadis,
    required this.arab,
    required this.terjemahan,
    required this.rawi,
    required this.sumber,
    required this.tanggal,
  });

  Hadis toHadis() => Hadis(
    id:         nomorHadis,
    arab:       arab,
    terjemahan: terjemahan,
    rawi:       rawi,
    sumber:     sumber,
    kitab:      kitabId,
    nomorHadis: nomorHadis,
  );
}
