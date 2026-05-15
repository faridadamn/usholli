import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_time.dart';

class PrayerApiService {
  static const String _base = 'https://api.aladhan.com/v1';

  // Method 20 = Kementerian Agama Indonesia
  static const int _method = 20;

  /// Fetch jadwal salat berdasarkan koordinat GPS
  Future<PrayerSchedule> fetchByCoordinates({
    required double latitude,
    required double longitude,
    required String cityName,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final dateStr = '${d.day.toString().padLeft(2,'0')}-'
        '${d.month.toString().padLeft(2,'0')}-${d.year}';

    final uri = Uri.parse(
      '$_base/timings/$dateStr'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&method=$_method'
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil jadwal salat (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parse(json['data'], cityName, d);
  }

  /// Fetch jadwal salat berdasarkan nama kota
  Future<PrayerSchedule> fetchByCity({
    required String city,
    required String country,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final dateStr = '${d.day.toString().padLeft(2,'0')}-'
        '${d.month.toString().padLeft(2,'0')}-${d.year}';

    final uri = Uri.parse(
      '$_base/timingsByCity/$dateStr'
      '?city=${Uri.encodeComponent(city)}'
      '&country=${Uri.encodeComponent(country)}'
      '&method=$_method'
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Kota tidak ditemukan');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parse(json['data'], city, d);
  }

  /// Fetch jadwal satu bulan penuh (untuk kalender)
  Future<List<PrayerSchedule>> fetchMonthByCity({
    required String city,
    required String country,
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse(
      '$_base/calendarByCity/$year/$month'
      '?city=${Uri.encodeComponent(city)}'
      '&country=${Uri.encodeComponent(country)}'
      '&method=$_method'
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil kalender salat');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = json['data'] as List;

    return dataList.asMap().entries.map((entry) {
      final d = DateTime(year, month, entry.key + 1);
      return _parse(entry.value, city, d);
    }).toList();
  }

  PrayerSchedule _parse(Map<String, dynamic> data, String city, DateTime date) {
    final timings = data['timings'] as Map<String, dynamic>;
    final hijri   = data['date']['hijri'] as Map<String, dynamic>;

    final hijriStr =
        '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} H';

    // Nama salat: Indonesia → API key
    final prayerMap = {
      'Subuh'  : ('Subuh',   'صَلَاةُ الْفَجْرِ',  timings['Fajr']    as String),
      'Syuruq' : ('Syuruq',  'الشُّرُوقُ',          timings['Sunrise'] as String),
      'Dzuhur' : ('Dzuhur',  'صَلَاةُ الظُّهْرِ',   timings['Dhuhr']   as String),
      'Ashar'  : ('Ashar',   'صَلَاةُ الْعَصْرِ',   timings['Asr']     as String),
      'Maghrib': ('Maghrib', 'صَلَاةُ الْمَغْرِبِ', timings['Maghrib'] as String),
      'Isya'   : ('Isya',    'صَلَاةُ الْعِشَاءِ',  timings['Isha']    as String),
    };

    final prayers = prayerMap.entries.map((e) {
      final timeRaw = e.value.$3.split(' ')[0]; // hapus timezone suffix
      return PrayerTime.fromAladhan(e.value.$1, e.value.$2, timeRaw, date);
    }).toList();

    return PrayerSchedule(
      date: date,
      hijriDate: hijriStr,
      city: city,
      prayers: prayers,
    );
  }
}
