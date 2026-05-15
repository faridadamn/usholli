import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/quran_models.dart';
import '../services/quran_api_service.dart';
import '../services/bookmark_service.dart';

enum QuranLoadState { idle, loading, loaded, error }

class QuranProvider extends ChangeNotifier {
  final QuranApiService _api       = QuranApiService();
  final BookmarkService _bookmarks = BookmarkService();
  final AudioPlayer     _player    = AudioPlayer();

  // ── Daftar Surah ─────────────────────────────────────────────────────────
  List<Surah>      _surahList   = [];
  QuranLoadState   _listState   = QuranLoadState.idle;
  String?          _listError;

  List<Surah>    get surahList  => _surahList;
  QuranLoadState get listState  => _listState;
  String?        get listError  => _listError;

  // ── Baca Surah ────────────────────────────────────────────────────────────
  Surah?         _currentSurah;
  List<Ayah>     _ayahs        = [];
  QuranLoadState _readState     = QuranLoadState.idle;
  String?        _readError;

  Surah?         get currentSurah => _currentSurah;
  List<Ayah>     get ayahs        => _ayahs;
  QuranLoadState get readState    => _readState;
  String?        get readError    => _readError;

  // ── Tafsir ────────────────────────────────────────────────────────────────
  final Map<String, String> _tafsirCache = {};
  final Map<String, bool>   _tafsirLoading = {};

  // ── Audio ─────────────────────────────────────────────────────────────────
  String?        _playingKey;    // '2:255' dll
  bool           _isPlaying     = false;
  String?        get playingKey => _playingKey;
  bool           get isPlaying  => _isPlaying;

  // ── Settings ──────────────────────────────────────────────────────────────
  bool _isDarkMode        = false;
  double _arabicFontSize  = 28;
  bool _showTranslation   = true;

  bool   get isDarkMode       => _isDarkMode;
  double get arabicFontSize   => _arabicFontSize;
  bool   get showTranslation  => _showTranslation;

  // ── Init ──────────────────────────────────────────────────────────────────

  QuranProvider() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _playingKey = null;
        _isPlaying  = false;
      }
      notifyListeners();
    });
  }

  // ── Load daftar surah ─────────────────────────────────────────────────────

  Future<void> loadSurahList() async {
    if (_surahList.isNotEmpty) return;
    _listState = QuranLoadState.loading;
    notifyListeners();

    try {
      _surahList = await _api.fetchSurahList();
      _listState = QuranLoadState.loaded;
    } catch (e) {
      _listState = QuranLoadState.error;
      _listError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ── Buka surah ────────────────────────────────────────────────────────────

  Future<void> openSurah(Surah surah) async {
    _currentSurah = surah;
    _ayahs        = [];
    _readState    = QuranLoadState.loading;
    notifyListeners();

    try {
      _ayahs     = await _api.fetchSurah(surah.number);
      _readState = QuranLoadState.loaded;
    } catch (e) {
      _readState = QuranLoadState.error;
      _readError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ── Tafsir (lazy load per ayat) ───────────────────────────────────────────

  Future<String?> getTafsir(int surah, int ayah) async {
    final key = '$surah:$ayah';
    if (_tafsirCache.containsKey(key)) return _tafsirCache[key];
    if (_tafsirLoading[key] == true)    return null;

    _tafsirLoading[key] = true;
    final result = await _api.fetchTafsir(surah, ayah);
    if (result != null) _tafsirCache[key] = result;
    _tafsirLoading[key] = false;
    notifyListeners();
    return result;
  }

  // ── Audio murottal ────────────────────────────────────────────────────────

  Future<void> playAudio(Ayah ayah) async {
    final key = ayah.globalKey;

    if (_playingKey == key && _isPlaying) {
      await _player.pause();
      _isPlaying  = false;
      _playingKey = null;
      notifyListeners();
      return;
    }

    await _player.stop();
    _playingKey = key;
    _isPlaying  = false;
    notifyListeners();

    try {
      await _player.setUrl(ayah.audioUrl);
      await _player.play();
    } catch (_) {
      _playingKey = null;
    }
    notifyListeners();
  }

  Future<void> stopAudio() async {
    await _player.stop();
    _playingKey = null;
    _isPlaying  = false;
    notifyListeners();
  }

  // ── Bookmark ──────────────────────────────────────────────────────────────

  bool isBookmarked(int surah, int ayah) =>
      _bookmarks.isBookmarked(surah, ayah);

  Future<void> toggleBookmark(Ayah ayah) async {
    await _bookmarks.toggle(ayah.surahNumber, ayah.ayahNumber, _currentSurah?.nameId ?? '');
    notifyListeners();
  }

  List<QuranBookmark> getBookmarks() => _bookmarks.getAll();

  // ── Last read ─────────────────────────────────────────────────────────────

  Future<void> markLastRead(Ayah ayah) =>
      _bookmarks.saveLastRead(ayah.surahNumber, ayah.ayahNumber, _currentSurah?.nameId ?? '');

  LastRead? get lastRead => _bookmarks.getLastRead();

  // ── Settings ──────────────────────────────────────────────────────────────

  void toggleDarkMode()      { _isDarkMode = !_isDarkMode; notifyListeners(); }
  void toggleTranslation()   { _showTranslation = !_showTranslation; notifyListeners(); }
  void increaseFontSize()    { if (_arabicFontSize < 48) { _arabicFontSize += 2; notifyListeners(); } }
  void decreaseFontSize()    { if (_arabicFontSize > 18) { _arabicFontSize -= 2; notifyListeners(); } }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
