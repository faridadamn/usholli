import 'package:flutter/foundation.dart';
import '../models/komunitas_models.dart';
import '../services/auth_service.dart';

enum AuthState { idle, loading, otpSent, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _svc = AuthService();

  AppUser?  _user;
  String?   _token;
  AuthState _state      = AuthState.idle;
  String?   _error;
  String    _nomorHp    = '';

  AppUser?  get user    => _user;
  String?   get token   => _token;
  AuthState get state   => _state;
  String?   get error   => _error;
  bool      get isLoggedIn => _user != null && _token != null;
  String    get namaDisplay => _user?.nama ?? 'Jamaah';
  String    get masjidAktifId => _user?.masjidId ?? '';

  // ── Init: coba load session ───────────────────────────────────────────────

  Future<void> init() async {
    _state = AuthState.loading;
    notifyListeners();
    try {
      final session = await _svc.loadSession();
      if (session != null) {
        _user   = session.user;
        _token  = session.token;
        _state  = AuthState.authenticated;
      } else {
        _state = AuthState.idle;
      }
    } catch (_) {
      _state = AuthState.idle;
    }
    notifyListeners();
  }

  // ── Step 1: Kirim OTP ─────────────────────────────────────────────────────

  Future<void> kirimOtp(String nomorHp) async {
    _nomorHp = nomorHp;
    _state   = AuthState.loading;
    _error   = null;
    notifyListeners();
    try {
      await _svc.kirimOtp(nomorHp);
      _state = AuthState.otpSent;
    } catch (e) {
      _state = AuthState.error;
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ── Step 2: Verifikasi OTP ────────────────────────────────────────────────

  Future<void> verifyOtp(String otp, {String? nama}) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await _svc.verifyOtp(_nomorHp, otp);
      _token = result.token;
      _user  = await _svc.upsertProfil(
        userId: result.userId,
        nomorHp: _nomorHp,
        token: result.token,
        nama: nama,
      );
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.error;
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ── Update profil ─────────────────────────────────────────────────────────

  Future<void> updateProfil({String? nama, String? avatar}) async {
    if (_user == null || _token == null) return;
    final data = <String, dynamic>{};
    if (nama   != null) data['nama']   = nama;
    if (avatar != null) data['avatar'] = avatar;
    if (data.isEmpty) return;

    await _svc.updateProfil(_user!.id, _token!, data);
    _user = _user!.copyWith(nama: nama, avatar: avatar);
    notifyListeners();
  }

  // ── Pilih / ganti masjid aktif ────────────────────────────────────────────

  Future<void> setMasjidAktif(String masjidId) async {
    if (_user == null || _token == null) return;
    final masjidIds = {..._user!.masjidIds, masjidId}.toList();
    await _svc.updateProfil(_user!.id, _token!, {
      'masjid_id':  masjidId,
      'masjid_ids': masjidIds,
    });
    _user = _user!.copyWith(masjidId: masjidId, masjidIds: masjidIds);
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _svc.logout();
    _user  = null;
    _token = null;
    _state = AuthState.idle;
    notifyListeners();
  }

  void resetError() { _error = null; _state = AuthState.idle; notifyListeners(); }
  void kembaliKeInput() { _state = AuthState.idle; notifyListeners(); }
}
