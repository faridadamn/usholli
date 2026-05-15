# 🕌 Usholli — Aplikasi Masjid Multi-tenant

Platform masjid digital yang menghubungkan pengurus dan jamaah.

## Fitur Lengkap

| # | Fitur | Status |
|---|-------|--------|
| 1 | Jadwal salat + notifikasi adzan (GPS + manual) | ✅ |
| 2 | Al-Quran + terjemahan + tafsir + murottal | ✅ |
| 3 | Hadis hari ini + jelajah 9 kitab + simpan | ✅ |
| 4 | Artikel masjid + admin panel web | ✅ |
| 5 | Donasi/infaq + program + laporan keuangan | ✅ |
| 6 | Login OTP SMS | ✅ |
| 7 | Titip doa ke pengurus | ✅ |
| 8 | Undangan acara personal (tahlilan, aqiqah, dll) | ✅ |
| 9 | Multi-masjid — cari, ikuti, ganti masjid aktif | ✅ |

## Struktur File

```
lib/
├── main.dart                         ← Entry + 6-tab NavigationBar
├── theme/app_theme.dart
├── models/
│   ├── prayer_time.dart
│   ├── quran_models.dart + .g.dart
│   ├── hadis_models.dart + .g.dart
│   ├── artikel_models.dart
│   ├── donasi_models.dart
│   └── komunitas_models.dart
├── services/
│   ├── prayer_provider.dart + prayer_api_service.dart
│   ├── location_service.dart + notification_service.dart
│   ├── quran_provider.dart + quran_api_service.dart + bookmark_service.dart
│   ├── hadis_provider.dart + hadis_api_service.dart
│   ├── artikel_provider.dart + artikel_service.dart
│   ├── donasi_provider.dart + donasi_service.dart
│   ├── auth_provider.dart + auth_service.dart
│   ├── komunitas_provider.dart + komunitas_service.dart
│   └── masjid_service.dart
└── screens/
    ├── prayer/ (3 files)
    ├── quran/  (3 files)
    ├── hadis/  (1 file)
    ├── artikel/(2 files)
    ├── donasi/ (3 files)
    ├── auth/   (1 file)
    └── komunitas/ (2 files)

usholli_admin/index.html   ← Admin panel web (deploy ke Vercel)
supabase_setup.sql         ← SQL setup semua tabel + RLS + trigger
```

## Setup (4 Langkah)

### 1. Supabase
```
supabase.com → New Project → SQL Editor → paste supabase_setup.sql
Settings → API → catat Project URL dan anon key
Authentication → Providers → Phone → Enable → pilih Twilio/Fonnte
```

### 2. Ganti semua YOUR_* di kode
```
YOUR_PROJECT          → subdomain Supabase (cek Settings > API)
YOUR_ANON_KEY         → anon public key
YOUR_MASJID_UUID      → UUID masjid setelah insert ke tabel masjid
YOUR_MIDTRANS_SERVER_KEY → dari dashboard sandbox.midtrans.com
```
File yang perlu diubah: auth_service, masjid_service, komunitas_service,
artikel_service, donasi_service, donasi_provider, dan index.html admin.

### 3. Insert masjid pertama
Di Supabase Table Editor → masjid → Insert row dengan nama, alamat, kota,
latitude, longitude, dan admin_id (UUID kamu setelah login pertama).

### 4. Build
```bash
flutter pub get
flutter run
```

## Tambah ke pubspec.yaml
```yaml
url_launcher: ^6.2.5
```

## Biaya

Rp 0 untuk mulai — semua pakai free tier.
Midtrans: ~0.7% per transaksi donasi (saat production).
SMS OTP: gratis 10/hari via Twilio, atau Rp 150/SMS via Fonnte.
