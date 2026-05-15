import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String cityName;
  final String provinceName;
  final bool isGps;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.provinceName = '',
    required this.isGps,
  });
}

class LocationService {
  static const _keyLat = 'manual_lat';
  static const _keyLng = 'manual_lng';
  static const _keyCity = 'manual_city';
  static const _keyUseGps = 'use_gps';

  /// Ambil lokasi: coba GPS dulu, fallback ke manual
  Future<LocationResult> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final useGps = prefs.getBool(_keyUseGps) ?? true;

    if (useGps) {
      try {
        return await getGpsLocation();
      } catch (_) {
        // GPS gagal → fallback ke manual
        return _getManualLocation(prefs) ??
            const LocationResult(
              latitude: -6.2088,
              longitude: 106.8456,
              cityName: 'Jakarta',
              provinceName: 'DKI Jakarta',
              isGps: false,
            );
      }
    }

    return _getManualLocation(prefs) ??
        const LocationResult(
          latitude: -6.2088,
          longitude: 106.8456,
          cityName: 'Jakarta',
          provinceName: 'DKI Jakarta',
          isGps: false,
        );
  }

  Future<LocationResult> getGpsLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    // Cek permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi diblokir permanen');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
      timeLimit: const Duration(seconds: 8),
    );

    // Reverse geocoding → nama kota
    String cityName = 'Lokasi Saya';
    String provinceName = '';
    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        cityName = p.subAdministrativeArea ??
            p.locality ??
            p.administrativeArea ??
            'Lokasi Saya';
        provinceName = p.administrativeArea ?? '';
      }
    } catch (_) {}

    return LocationResult(
      latitude: pos.latitude,
      longitude: pos.longitude,
      cityName: cityName,
      provinceName: provinceName,
      isGps: true,
    );
  }

  LocationResult? _getManualLocation(SharedPreferences prefs) {
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    final city = prefs.getString(_keyCity);
    if (lat != null && lng != null && city != null) {
      return LocationResult(
        latitude: lat,
        longitude: lng,
        cityName: city,
        isGps: false,
      );
    }
    return null;
  }

  /// Simpan lokasi manual yang dipilih jamaah
  Future<void> saveManualLocation(LocationResult loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, loc.latitude);
    await prefs.setDouble(_keyLng, loc.longitude);
    await prefs.setString(_keyCity, loc.cityName);
    await prefs.setBool(_keyUseGps, false);
  }

  /// Reset ke GPS
  Future<void> resetToGps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseGps, true);
  }

  /// Daftar kota besar Indonesia (untuk picker manual)
  static const List<Map<String, dynamic>> indonesiaCities = [
    {'name': 'Jakarta', 'lat': -6.2088, 'lng': 106.8456},
    {'name': 'Surabaya', 'lat': -7.2575, 'lng': 112.7521},
    {'name': 'Bandung', 'lat': -6.9175, 'lng': 107.6191},
    {'name': 'Medan', 'lat': 3.5952, 'lng': 98.6722},
    {'name': 'Semarang', 'lat': -6.9932, 'lng': 110.4203},
    {'name': 'Makassar', 'lat': -5.1477, 'lng': 119.4327},
    {'name': 'Yogyakarta', 'lat': -7.7956, 'lng': 110.3695},
    {'name': 'Palembang', 'lat': -2.9761, 'lng': 104.7754},
    {'name': 'Tangerang', 'lat': -6.1783, 'lng': 106.6319},
    {'name': 'Depok', 'lat': -6.4025, 'lng': 106.7942},
    {'name': 'Bekasi', 'lat': -6.2383, 'lng': 106.9756},
    {'name': 'Bogor', 'lat': -6.5971, 'lng': 106.8060},
    {'name': 'Pekanbaru', 'lat': 0.5071, 'lng': 101.4478},
    {'name': 'Banjarmasin', 'lat': -3.3186, 'lng': 114.5944},
    {'name': 'Malang', 'lat': -7.9666, 'lng': 112.6326},
    {'name': 'Aceh', 'lat': 5.5483, 'lng': 95.3238},
  ];
}
