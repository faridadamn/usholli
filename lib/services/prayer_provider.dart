import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/prayer_time.dart';
import '../services/prayer_api_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

enum PrayerLoadState { idle, loading, loaded, error }

class PrayerProvider extends ChangeNotifier {
  final PrayerApiService _api  = PrayerApiService();
  final LocationService  _loc  = LocationService();
  final NotificationService _notif = NotificationService();

  PrayerLoadState _state    = PrayerLoadState.idle;
  PrayerSchedule? _schedule;
  LocationResult? _location;
  String?         _errorMsg;
  Timer?          _countdownTimer;
  Duration        _timeToNext = Duration.zero;

  PrayerLoadState get state    => _state;
  PrayerSchedule? get schedule => _schedule;
  LocationResult? get location => _location;
  String?         get errorMsg => _errorMsg;
  Duration        get timeToNext => _timeToNext;

  PrayerTime? get nextPrayer => _schedule?.nextPrayer;

  String get countdownString {
    final h = _timeToNext.inHours;
    final m = _timeToNext.inMinutes.remainder(60).toString().padLeft(2,'0');
    final s = _timeToNext.inSeconds.remainder(60).toString().padLeft(2,'0');
    if (h > 0) return '${h}j ${m}m ${s}d';
    return '${m}m ${s}d';
  }

  Future<void> loadPrayers() async {
    _state = PrayerLoadState.loading;
    _errorMsg = null;
    notifyListeners();

    try {
      _location = await _loc.getLocation();

      _schedule = await _api.fetchByCoordinates(
        latitude:  _location!.latitude,
        longitude: _location!.longitude,
        cityName:  _location!.cityName,
      );

      _state = PrayerLoadState.loaded;
      _startCountdown();

      // Jadwalkan notifikasi adzan
      await _notif.scheduleAllPrayers(_schedule!.prayers);
    } catch (e) {
      _state = PrayerLoadState.error;
      _errorMsg = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  Future<void> switchToCity(Map<String, dynamic> city) async {
    _state = PrayerLoadState.loading;
    notifyListeners();

    try {
      final loc = LocationResult(
        latitude: city['lat'] as double,
        longitude: city['lng'] as double,
        cityName: city['name'] as String,
        isGps: false,
      );
      await _loc.saveManualLocation(loc);
      _location = loc;

      _schedule = await _api.fetchByCoordinates(
        latitude:  loc.latitude,
        longitude: loc.longitude,
        cityName:  loc.cityName,
      );

      _state = PrayerLoadState.loaded;
      _startCountdown();
      await _notif.scheduleAllPrayers(_schedule!.prayers);
    } catch (e) {
      _state = PrayerLoadState.error;
      _errorMsg = 'Gagal mengambil jadwal untuk kota ini';
    }

    notifyListeners();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
      // Refresh jadwal saat pergantian hari
      final now = DateTime.now();
      if (now.hour == 0 && now.minute == 0 && now.second == 0) {
        loadPrayers();
      }
      notifyListeners();
    });
  }

  void _updateCountdown() {
    final remaining = _schedule?.timeToNextPrayer;
    _timeToNext = remaining ?? Duration.zero;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
