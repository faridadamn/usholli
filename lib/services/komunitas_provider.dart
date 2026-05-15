import 'package:flutter/foundation.dart';
import '../models/komunitas_models.dart';
import '../services/komunitas_service.dart';
import '../services/masjid_service.dart';

enum KomunitasLoadState { idle, loading, loaded, error }

class KomunitasProvider extends ChangeNotifier {
  final KomunitasService _svc   = KomunitasService();
  final MasjidService    _masjid = MasjidService();

  // ── Titip Doa ─────────────────────────────────────────────────────────────
  List<TitipDoa>       _doaList  = [];
  KomunitasLoadState   _doaState = KomunitasLoadState.idle;
  bool                 _doaSent  = false;

  List<TitipDoa>     get doaList  => _doaList;
  KomunitasLoadState get doaState => _doaState;
  bool               get doaSent  => _doaSent;

  // ── Undangan ──────────────────────────────────────────────────────────────
  List<Undangan>     _undanganList  = [];
  Undangan?          _undanganDetail;
  KomunitasLoadState _undanganState = KomunitasLoadState.idle;

  List<Undangan>     get undanganList   => _undanganList;
  Undangan?          get undanganDetail => _undanganDetail;
  KomunitasLoadState get undanganState  => _undanganState;

  // ── Masjid ────────────────────────────────────────────────────────────────
  List<Masjid>       _masjidList   = [];
  List<Masjid>       _masjidSaya   = [];
  KomunitasLoadState _masjidState  = KomunitasLoadState.idle;
  String             _searchQuery  = '';

  List<Masjid>       get masjidList  => _masjidList;
  List<Masjid>       get masjidSaya  => _masjidSaya;
  KomunitasLoadState get masjidState => _masjidState;

  // ── Load doa ──────────────────────────────────────────────────────────────

  Future<void> loadDoa(String userId, String masjidId, String token) async {
    _doaState = KomunitasLoadState.loading;
    notifyListeners();
    try {
      _doaList  = await _svc.fetchDoaSaya(userId, masjidId, token);
      _doaState = KomunitasLoadState.loaded;
    } catch (_) {
      _doaState = KomunitasLoadState.error;
    }
    notifyListeners();
  }

  Future<void> kirimDoa({
    required String masjidId,
    required String userId,
    required String userName,
    required String isiDoa,
    required bool anonim,
    required String token,
  }) async {
    _doaSent = false;
    try {
      final doa = await _svc.kirimDoa(
        masjidId: masjidId, userId: userId,
        userName: userName, isiDoa: isiDoa,
        anonim: anonim, token: token,
      );
      _doaList.insert(0, doa);
      _doaSent = true;
    } catch (_) { _doaSent = false; }
    notifyListeners();
  }

  // ── Load undangan ─────────────────────────────────────────────────────────

  Future<void> loadUndangan(String userId, String token) async {
    _undanganState = KomunitasLoadState.loading;
    notifyListeners();
    try {
      _undanganList  = await _svc.fetchUndanganSaya(userId, token);
      _undanganState = KomunitasLoadState.loaded;
    } catch (_) {
      _undanganState = KomunitasLoadState.error;
    }
    notifyListeners();
  }

  Future<Undangan?> cariByKode(String kode) async {
    final u = await _svc.fetchByKode(kode);
    _undanganDetail = u;
    notifyListeners();
    return u;
  }

  Future<Undangan?> buatUndangan({
    required String pembuatId,
    required String pembuatNama,
    required String token,
    required Map<String, dynamic> data,
    String? masjidId,
  }) async {
    try {
      final u = await _svc.buatUndangan(
        pembuatId: pembuatId, pembuatNama: pembuatNama,
        data: data, token: token, masjidId: masjidId,
      );
      _undanganList.insert(0, u);
      notifyListeners();
      return u;
    } catch (_) { return null; }
  }

  Future<void> bergabung(String undanganId, String userId, List<String> currentIds, String token) async {
    final updated = await _svc.bergabung(undanganId, userId, currentIds, token);
    final idx = _undanganList.indexWhere((u) => u.id == undanganId);
    if (idx >= 0) _undanganList[idx] = updated;
    _undanganDetail = updated;
    notifyListeners();
  }

  // ── Cari Masjid ───────────────────────────────────────────────────────────

  Future<void> cariMasjid(String query) async {
    if (query == _searchQuery) return;
    _searchQuery = query;
    if (query.trim().length < 2) { _masjidList = []; notifyListeners(); return; }
    _masjidState = KomunitasLoadState.loading;
    notifyListeners();
    try {
      _masjidList  = await _masjid.cari(query);
      _masjidState = KomunitasLoadState.loaded;
    } catch (_) {
      _masjidState = KomunitasLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMasjidSaya(List<String> ids) async {
    _masjidSaya = await _masjid.masjidSaya(ids);
    notifyListeners();
  }

  Future<void> cariTerdekat(double lat, double lng) async {
    _masjidState = KomunitasLoadState.loading;
    notifyListeners();
    try {
      _masjidList  = await _masjid.terdekat(lat: lat, lng: lng);
      _masjidState = KomunitasLoadState.loaded;
    } catch (_) {
      _masjidState = KomunitasLoadState.error;
    }
    notifyListeners();
  }

  MasjidService get masjidService => _masjid;
}
