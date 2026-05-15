import 'package:hive/hive.dart';

part 'quran_models.g.dart';

// ── Surah ────────────────────────────────────────────────────────────────────

class Surah {
  final int number;
  final String nameAr;
  final String nameEn;
  final String nameId;       // transliterasi Indonesia
  final String revelation;   // 'Makkiyah' | 'Madaniyah'
  final int ayahCount;
  final String meaning;      // arti nama surah (Indonesia)

  const Surah({
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.nameId,
    required this.revelation,
    required this.ayahCount,
    required this.meaning,
  });

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
    number:    j['number'] as int,
    nameAr:    j['name'] as String,
    nameEn:    j['englishName'] as String,
    nameId:    j['englishName'] as String,
    revelation: j['revelationType'] == 'Meccan' ? 'Makkiyah' : 'Madaniyah',
    ayahCount: j['numberOfAyahs'] as int,
    meaning:   j['englishNameTranslation'] as String,
  );
}

// ── Ayah ─────────────────────────────────────────────────────────────────────

class Ayah {
  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final String translation;   // bahasa Indonesia
  final String? tafsir;
  final String audioUrl;      // murottal Mishary Rashid

  const Ayah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.translation,
    this.tafsir,
    required this.audioUrl,
  });

  String get globalKey => '$surahNumber:$ayahNumber';
}

// ── Bookmark (Hive) ───────────────────────────────────────────────────────────

@HiveType(typeId: 1)
class QuranBookmark extends HiveObject {
  @HiveField(0) int surahNumber;
  @HiveField(1) int ayahNumber;
  @HiveField(2) String surahName;
  @HiveField(3) DateTime savedAt;
  @HiveField(4) String? note;

  QuranBookmark({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.savedAt,
    this.note,
  });

  String get displayLabel => '$surahName : $ayahNumber';
}

// ── Last Read (Hive) ──────────────────────────────────────────────────────────

@HiveType(typeId: 2)
class LastRead extends HiveObject {
  @HiveField(0) int surahNumber;
  @HiveField(1) int ayahNumber;
  @HiveField(2) String surahName;
  @HiveField(3) DateTime readAt;

  LastRead({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.readAt,
  });
}
