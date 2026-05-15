import 'package:flutter/foundation.dart';
import '../models/artikel_models.dart';
import '../services/artikel_service.dart';

enum ArtikelLoadState { idle, loading, loaded, error }

class ArtikelProvider extends ChangeNotifier {
  final ArtikelService _svc = ArtikelService();

  // ── Daftar artikel ────────────────────────────────────────────────────────
  List<Artikel>      _artikelList   = [];
  ArtikelLoadState   _listState     = ArtikelLoadState.idle;
  String?            _listError;
  String?            _filterKategori;
  bool               _hasMore       = true;
  int                _offset        = 0;
  static const int   _pageSize      = 15;

  List<Artikel>    get artikelList    => _artikelList;
  ArtikelLoadState get listState      => _listState;
  String?          get listError      => _listError;
  String?          get filterKategori => _filterKategori;
  bool             get hasMore        => _hasMore;

  // ── Detail + komentar ─────────────────────────────────────────────────────
  Artikel?           _detail;
  List<Komentar>     _komentar      = [];
  ArtikelLoadState   _detailState   = ArtikelLoadState.idle;
  final Set<String>  _likedIds      = {};

  Artikel?         get detail       => _detail;
  List<Komentar>   get komentar     => _komentar;
  ArtikelLoadState get detailState  => _detailState;

  // ── Load daftar ───────────────────────────────────────────────────────────

  Future<void> loadArtikel({String? masjidId, bool refresh = false}) async {
    if (refresh) {
      _artikelList = [];
      _offset      = 0;
      _hasMore     = true;
    }
    if (!_hasMore && !refresh) return;

    _listState = _artikelList.isEmpty ? ArtikelLoadState.loading : _listState;
    notifyListeners();

    try {
      final items = await _svc.fetchArtikel(
        masjidId:   masjidId,
        kategoriId: _filterKategori,
        limit:      _pageSize,
        offset:     _offset,
      );
      _artikelList.addAll(items);
      _hasMore = items.length == _pageSize;
      _offset += items.length;
      _listState = ArtikelLoadState.loaded;
    } catch (e) {
      _listState = ArtikelLoadState.error;
      _listError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> loadMore({String? masjidId}) => loadArtikel(masjidId: masjidId);

  void setFilter(String? kategoriId) {
    _filterKategori = kategoriId;
    loadArtikel(refresh: true);
  }

  // ── Detail artikel ────────────────────────────────────────────────────────

  Future<void> loadDetail(String artikelId) async {
    _detail      = null;
    _komentar    = [];
    _detailState = ArtikelLoadState.loading;
    notifyListeners();

    try {
      final results = await Future.wait([
        _svc.fetchDetail(artikelId),
        _svc.fetchKomentar(artikelId),
      ]);
      _detail      = results[0] as Artikel;
      _komentar    = results[1] as List<Komentar>;
      _detailState = ArtikelLoadState.loaded;
    } catch (e) {
      _detailState = ArtikelLoadState.error;
    }
    notifyListeners();
  }

  // ── Like ──────────────────────────────────────────────────────────────────

  Future<void> toggleLike(String artikelId) async {
    if (_detail == null) return;
    final isLiked = _likedIds.contains(artikelId);
    isLiked ? _likedIds.remove(artikelId) : _likedIds.add(artikelId);

    final newCount = await _svc.toggleLike(artikelId, _detail!.likeCount, isLiked);
    _detail = Artikel(
      id: _detail!.id, masjidId: _detail!.masjidId, masjidNama: _detail!.masjidNama,
      judul: _detail!.judul, konten: _detail!.konten, ringkasan: _detail!.ringkasan,
      kategoriId: _detail!.kategoriId, thumbnailUrl: _detail!.thumbnailUrl,
      penulisNama: _detail!.penulisNama, createdAt: _detail!.createdAt,
      likeCount: newCount, viewCount: _detail!.viewCount, tags: _detail!.tags,
    );
    notifyListeners();
  }

  bool isLiked(String id) => _likedIds.contains(id);

  // ── Komentar ──────────────────────────────────────────────────────────────

  Future<void> tambahKomentar({
    required String artikelId,
    required String userId,
    required String userName,
    required String isi,
    required String token,
  }) async {
    await _svc.tambahKomentar(
      artikelId: artikelId, userId: userId,
      userName: userName, isi: isi, token: token,
    );
    // Refresh komentar
    _komentar = await _svc.fetchKomentar(artikelId);
    notifyListeners();
  }
}
