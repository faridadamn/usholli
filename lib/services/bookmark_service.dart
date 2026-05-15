import 'package:hive_flutter/hive_flutter.dart';
import '../models/quran_models.dart';

class BookmarkService {
  static const String _boxBookmark  = 'quran_bookmarks';
  static const String _boxLastRead  = 'quran_last_read';

  // ── Init (panggil sekali di main) ────────────────────────────────────────

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(QuranBookmarkAdapter());
    Hive.registerAdapter(LastReadAdapter());
    await Hive.openBox<QuranBookmark>(_boxBookmark);
    await Hive.openBox<LastRead>(_boxLastRead);
  }

  // ── Bookmark ─────────────────────────────────────────────────────────────

  Box<QuranBookmark> get _bookBox => Hive.box<QuranBookmark>(_boxBookmark);

  List<QuranBookmark> getAll() =>
      _bookBox.values.toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  bool isBookmarked(int surah, int ayah) =>
      _bookBox.values.any((b) => b.surahNumber == surah && b.ayahNumber == ayah);

  Future<void> toggle(int surah, int ayah, String surahName) async {
    final existing = _bookBox.values.firstWhere(
      (b) => b.surahNumber == surah && b.ayahNumber == ayah,
      orElse: () => QuranBookmark(surahNumber: -1, ayahNumber: -1, surahName: '', savedAt: DateTime.now()),
    );

    if (existing.surahNumber != -1) {
      await existing.delete();
    } else {
      await _bookBox.add(QuranBookmark(
        surahNumber: surah,
        ayahNumber:  ayah,
        surahName:   surahName,
        savedAt:     DateTime.now(),
      ));
    }
  }

  Future<void> delete(QuranBookmark bookmark) => bookmark.delete();

  // ── Last Read ────────────────────────────────────────────────────────────

  Box<LastRead> get _lastBox => Hive.box<LastRead>(_boxLastRead);

  LastRead? getLastRead() =>
      _lastBox.isEmpty ? null : _lastBox.values.last;

  Future<void> saveLastRead(int surah, int ayah, String surahName) async {
    await _lastBox.clear();
    await _lastBox.add(LastRead(
      surahNumber: surah,
      ayahNumber:  ayah,
      surahName:   surahName,
      readAt:      DateTime.now(),
    ));
  }
}
