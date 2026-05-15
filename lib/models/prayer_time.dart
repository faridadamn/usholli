import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrayerTime {
  final String name;
  final String nameAr;
  final DateTime time;
  final bool isNext;
  final bool isPassed;

  const PrayerTime({
    required this.name,
    required this.nameAr,
    required this.time,
    this.isNext = false,
    this.isPassed = false,
  });

  PrayerTime copyWith({bool? isNext, bool? isPassed}) => PrayerTime(
    name: name,
    nameAr: nameAr,
    time: time,
    isNext: isNext ?? this.isNext,
    isPassed: isPassed ?? this.isPassed,
  );

  String get timeString {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color get color => switch (name) {
    'Subuh'   => AppTheme.subuh,
    'Syuruq'  => AppTheme.syuruq,
    'Dzuhur'  => AppTheme.dzuhur,
    'Ashar'   => AppTheme.ashar,
    'Maghrib' => AppTheme.maghrib,
    'Isya'    => AppTheme.isya,
    _         => AppTheme.primary,
  };

  String get icon => switch (name) {
    'Subuh'   => '🌙',
    'Syuruq'  => '🌅',
    'Dzuhur'  => '☀️',
    'Ashar'   => '🌤️',
    'Maghrib' => '🌇',
    'Isya'    => '✨',
    _         => '🕌',
  };

  factory PrayerTime.fromAladhan(String name, String nameAr, String timeStr, DateTime date) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return PrayerTime(
      name: name,
      nameAr: nameAr,
      time: DateTime(date.year, date.month, date.day, hour, minute),
    );
  }
}

class PrayerSchedule {
  final DateTime date;
  final String hijriDate;
  final String city;
  final List<PrayerTime> prayers;

  const PrayerSchedule({
    required this.date,
    required this.hijriDate,
    required this.city,
    required this.prayers,
  });

  PrayerTime? get nextPrayer {
    final now = DateTime.now();
    try {
      return prayers.firstWhere(
        (p) => p.name != 'Syuruq' && p.time.isAfter(now),
      );
    } catch (_) {
      return null;
    }
  }

  Duration? get timeToNextPrayer {
    final next = nextPrayer;
    if (next == null) return null;
    return next.time.difference(DateTime.now());
  }

  List<PrayerTime> get markedPrayers {
    final now = DateTime.now();
    final next = nextPrayer;
    return prayers.map((p) => p.copyWith(
      isNext: p.name == next?.name,
      isPassed: p.time.isBefore(now),
    )).toList();
  }
}
