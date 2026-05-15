import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/hadis_models.dart';
import '../services/hadis_api_service.dart';

enum HadisLoadState { idle, loading, loaded, error }

class HadisProvider extends ChangeNotifier {
  final HadisApiService _api = HadisApiService();

  // ── Hadis Hari Ini ────────────────────────────────────────────────────────
  Hadis?         _hadisHariIni;
  HadisLoadState _hariIniState = HadisLoadState.idle;
  String?        _hariIniError;

  Hadis?         get hadisHariIni   => _hadisHariIni;
  HadisLoadState get hariIniState   => _hariIniState;
  String?        get hariIniError   => _hariIniError;

  // ── Jelajah per Kitab ─────────────────────────────────────────────────────
  HadisKitab?    _selectedKitab;
  List<Hadis>    _hadisJelajah  = [];
  HadisLoadState _jelajahState  = HadisLoadState.idle;
  int            _currentPage   = 1;
  bool           _hasMore       = true;

  HadisKitab?    get selectedKitab  => _selectedKitab;
  List<Hadis>    get hadisJelajah   => _hadisJelajah;
  HadisLoadState get jelajahState   => _jelajahState;
  bool           get hasMore        => _hasMore;

  // ── Search ────────────────────────────────────────────────────────────────
  List<Hadis>    _searchResults = [];
  HadisLoadState _searchState   = HadisLoadState.idle;
  String         _lastQuery     = '';

  List<Hadis>    get searchResults  => _searchResults;
  HadisLoadState get searchState    => _searchState;

  // ── Tersimpan (Hive) ──────────────────────────────────────────────────────
  static const String _savedBox  = 'saved_hadis';
  static const String _cacheBox  = 'cached_hadis_hari_ini';

  static Future<void> initHive() async {
    Hive.registerAdapter(SavedHadisAdapter());
    Hive.registerAdapter(CachedHadisHariIniAdapter());
    await Hive.openBox<SavedHadis>(_savedBox);
    await Hive.openBox<CachedHadisHariIni>(_cacheBox);
  }

  // ── Load Hadis Hari Ini ───────────────────────────────────────────────────

  Future<void> loadHariIni({bool forceRefresh = false}) async {
    // Cek cache hari ini
    if (!forceRefresh) {
      final cached = _loadFromCache();
      if (cached != null) {
        _hadisHariIni = cached;
        _hariIniState = HadisLoadState.loaded;
        notifyListeners();
        return;
      }
    }

    _hariIniState = HadisLoadState.loading;
    notifyListeners();

    try {
      _hadisHariIni = await _api.fetchHariIni();
      _hariIniState = HadisLoadState.loaded;
      _saveToCache(_hadisHariIni!);
    } catch (e) {
      // Jika offline, coba cache lama
      final cached = _loadFromCache(ignoreDate: true);
      if (cached != null) {
        _hadisHariIni = cached;
        _hariIniState = HadisLoadState.loaded;
      } else {
        _hariIniState = HadisLoadState.error;
        _hariIniError = 'Tidak dapat memuat hadis. Periksa koneksi internet.';
      }
    }
    notifyListeners();
  }

  // ── Acak Hadis Baru ───────────────────────────────────────────────────────

  Future<void> refreshHariIni() async {
    _hariIniState = HadisLoadState.loading;
    notifyListeners();
    try {
      // Ambil dari kitab acak
      final kitab = HadisKitab.all[DateTime.now().millisecondsSinceEpoch % HadisKitab.all.length];
      _hadisHariIni = await _api.fetchRandom(kitab.id);
      _hariIniState = HadisLoadState.loaded;
    } catch (_) {
      _hariIniState = HadisLoadState.loaded; // tetap tampil yg lama
    }
    notifyListeners();
  }

  // ── Jelajah per Kitab ─────────────────────────────────────────────────────

  Future<void> selectKitab(HadisKitab kitab) async {
    _selectedKitab = kitab;
    _hadisJelajah  = [];
    _currentPage   = 1;
    _hasMore       = true;
    _jelajahState  = HadisLoadState.loading;
    notifyListeners();
    await _loadNextPage();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _jelajahState == HadisLoadState.loading) return;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_selectedKitab == null) return;
    try {
      final items = await _api.fetchList(_selectedKitab!.id, page: _currentPage);
      _hadisJelajah.addAll(items);
      _hasMore = items.length == 20;
      _currentPage++;
      _jelajahState = HadisLoadState.loaded;
    } catch (e) {
      _jelajahState = HadisLoadState.error;
    }
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> search(String query) async {
    if (query.trim().isEmpty) { _searchResults = []; notifyListeners(); return; }
    if (query == _lastQuery) return;
    _lastQuery   = query;
    _searchState = HadisLoadState.loading;
    notifyListeners();

    try {
      _searchResults = await _api.search(query);
      _searchState   = HadisLoadState.loaded;
    } catch (_) {
      _searchState   = HadisLoadState.error;
      _searchResults = [];
    }
    notifyListeners();
  }

  // ── Simpan / Hapus ────────────────────────────────────────────────────────

  Box<SavedHadis> get _box => Hive.box<SavedHadis>(_savedBox);

  bool isSaved(Hadis h) =>
      _box.values.any((s) => s.hadisId == h.id && s.kitab == h.kitab);

  Future<void> toggleSave(Hadis h) async {
    final existing = _box.values.firstWhere(
      (s) => s.hadisId == h.id && s.kitab == h.kitab,
      orElse: () => SavedHadis(hadisId: -1, kitab: '', arab: '', terjemahan: '', sumber: '', savedAt: DateTime.now()),
    );
    if (existing.hadisId != -1) {
      await existing.delete();
    } else {
      await _box.add(SavedHadis(
        hadisId: h.id, kitab: h.kitab,
        arab: h.arab, terjemahan: h.terjemahan,
        sumber: h.sumber, savedAt: DateTime.now(),
      ));
    }
    notifyListeners();
  }

  List<SavedHadis> getSaved() =>
      _box.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  // ── Cache internal ────────────────────────────────────────────────────────

  Hadis? _loadFromCache({bool ignoreDate = false}) {
    final box = Hive.box<CachedHadisHariIni>(_cacheBox);
    if (box.isEmpty) return null;
    final c = box.values.last;
    final today = _todayStr();
    if (!ignoreDate && c.tanggal != today) return null;
    return c.toHadis();
  }

  void _saveToCache(Hadis h) {
    final box = Hive.box<CachedHadisHariIni>(_cacheBox);
    box.clear();
    box.add(CachedHadisHariIni(
      kitabId: h.kitab, nomorHadis: h.nomorHadis,
      arab: h.arab, terjemahan: h.terjemahan,
      rawi: h.rawi, sumber: h.sumber,
      tanggal: _todayStr(),
    ));
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }
}
