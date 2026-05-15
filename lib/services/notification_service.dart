import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_time.dart';
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _i = NotificationService._internal();
  factory NotificationService() => _i;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ID unik per waktu salat (1-6)
  static const Map<String, int> _prayerIds = {
    'Subuh': 1, 'Syuruq': 2, 'Dzuhur': 3,
    'Ashar': 4, 'Maghrib': 5, 'Isya': 6,
  };

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 13+ — minta izin notifikasi
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // TODO: navigate ke halaman jadwal salat
  }

  /// Jadwalkan semua notifikasi adzan hari ini
  Future<void> scheduleAllPrayers(List<PrayerTime> prayers) async {
    final prefs = await SharedPreferences.getInstance();

    for (final prayer in prayers) {
      if (prayer.name == 'Syuruq') continue; // syuruq tidak ada adzan

      final enabled = prefs.getBool('notif_${prayer.name}') ?? true;
      if (!enabled) continue;

      final scheduledTime = prayer.time;
      if (scheduledTime.isBefore(DateTime.now())) continue;

      await _scheduleOne(prayer, scheduledTime);
    }
  }

  Future<void> _scheduleOne(PrayerTime prayer, DateTime time) async {
    try {
      await _scheduleOneWithSound(prayer, time, useAdzanSound: true);
    } on PlatformException catch (e) {
      if (e.code != 'invalid_sound') return;
      try {
        await _scheduleOneWithSound(prayer, time, useAdzanSound: false);
      } on PlatformException {
        return;
      }
    }
  }

  Future<void> _scheduleOneWithSound(
    PrayerTime prayer,
    DateTime time, {
    required bool useAdzanSound,
  }) async {
    final id = _prayerIds[prayer.name] ?? 0;

    // Android: channel berbeda per waktu salat agar bisa custom ringtone
    final androidDetails = AndroidNotificationDetails(
      useAdzanSound
          ? 'prayer_${prayer.name.toLowerCase()}_adzan_v2'
          : 'prayer_${prayer.name.toLowerCase()}_default',
      'Adzan ${prayer.name}',
      channelDescription: 'Notifikasi waktu salat ${prayer.name}',
      importance: Importance.max,
      priority: Priority.high,
      // Nama file audio adzan tanpa ekstensi (di res/raw/)
      sound: useAdzanSound
          ? const RawResourceAndroidNotificationSound('adzan')
          : null,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      styleInformation: const BigTextStyleInformation(''),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'adzan.aiff',
      presentSound: true,
      presentAlert: true,
    );

    await _plugin.zonedSchedule(
      id,
      'Waktu ${prayer.name} ${prayer.nameAr}',
      'Allahu Akbar — Telah masuk waktu salat ${prayer.name}',
      tz.TZDateTime.from(time, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Batalkan notifikasi untuk satu waktu salat
  Future<void> cancelPrayer(String prayerName) async {
    final id = _prayerIds[prayerName];
    if (id != null) await _plugin.cancel(id);
  }

  /// Batalkan semua notifikasi
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Toggle notifikasi per waktu salat (disimpan di prefs)
  Future<void> togglePrayer(String prayerName, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$prayerName', enabled);
    if (!enabled) await cancelPrayer(prayerName);
  }

  Future<bool> isPrayerEnabled(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notif_$prayerName') ?? true;
  }
}
