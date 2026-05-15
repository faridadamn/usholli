import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/komunitas_models.dart';
import '../../models/prayer_time.dart';
import '../../services/location_service.dart';
import '../../services/masjid_service.dart';
import '../../services/prayer_provider.dart';
import '../../theme/app_theme.dart';
import '../hadis/hadis_screen.dart';
import '../masjid/masjid_detail_screen.dart';
import '../masjid/masjid_form_screen.dart';
import '../quran/quran_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MasjidService _masjidService = MasjidService();
  final LocationService _locationService = LocationService();
  List<Masjid> _masjids = [];
  LocationResult? _userLocation;
  bool _loadingMasjids = true;
  String? _masjidError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PrayerProvider>();
      if (provider.state == PrayerLoadState.idle) {
        provider.loadPrayers();
      }
      _loadMasjids();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Consumer<PrayerProvider>(
          builder: (context, provider, _) {
            final schedule = provider.schedule;
            final prayers = schedule?.markedPrayers ?? _fallbackPrayers();
            final nextPrayer = provider.nextPrayer ??
                prayers.firstWhere((p) => p.name == 'Dzuhur');

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _ExploreHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      children: [
                        _QuranPrayerCard(
                          prayers: prayers,
                          nextPrayer: nextPrayer,
                          dateLabel:
                              _dateLabel(schedule?.date ?? DateTime.now()),
                          hijriDate:
                              schedule?.hijriDate ?? '17 Dzulqaidah 1446 H',
                          countdown: provider.countdownString == '00m 00d'
                              ? '-01:22:45 menuju waktu'
                              : '-${provider.countdownString} menuju waktu',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.menu_book_rounded,
                                title: 'Baca Al-Qur' 'an',
                                description:
                                    'Dekatkan diri dengan firman Allah setiap hari.',
                                actionLabel: 'Lihat Semua Surah',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const QuranScreen()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.volunteer_activism_rounded,
                                title: 'Hadis Harian',
                                description:
                                    'Amalkan sunnah dan jadikan hidup lebih baik.',
                                actionLabel: 'Lihat Hadis Lainnya',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HadisScreen()),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _SectionTitle(title: 'Ayat Hari Ini'),
                        const SizedBox(height: 8),
                        const _DailyVerseCard(),
                        const SizedBox(height: 16),
                        _SectionTitle(
                          title: 'Masjid Terdekat',
                          actionLabel: 'Tambah',
                          onAction: _openCreateMasjid,
                        ),
                        const SizedBox(height: 8),
                        _MasjidListSection(
                          loading: _loadingMasjids,
                          error: _masjidError,
                          masjids: _masjids,
                          userLocation: _userLocation,
                          masjidService: _masjidService,
                          onRetry: _loadMasjids,
                          onAdd: _openCreateMasjid,
                          onOpen: _openDetailMasjid,
                        ),
                        const SizedBox(height: 12),
                        const _QiblaCard(),
                        const SizedBox(height: 12),
                        const _ReminderCard(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadMasjids() async {
    setState(() {
      _loadingMasjids = true;
      _masjidError = null;
    });

    try {
      final location = await _locationService.getGpsLocation();
      final masjids = await _masjidService.terdekat(
        lat: location.latitude,
        lng: location.longitude,
      );
      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _masjids = masjids;
        _loadingMasjids = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _masjidError = e.toString().replaceFirst('Exception: ', '');
        _loadingMasjids = false;
      });
    }
  }

  Future<void> _openCreateMasjid() async {
    final input = await Navigator.push<Masjid>(
      context,
      MaterialPageRoute(builder: (_) => const MasjidFormScreen()),
    );
    if (input == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyimpan masjid...'),
        duration: Duration(milliseconds: 900),
      ),
    );

    try {
      final saved = await _masjidService.tambah(input);
      if (!mounted) return;
      setState(() {
        _masjids = [saved, ..._masjids];
        if (_userLocation != null) {
          _masjids.sort((a, b) {
            final user = _userLocation!;
            final da = _masjidService.jarakKm(
              user.latitude,
              user.longitude,
              a.latitude,
              a.longitude,
            );
            final db = _masjidService.jarakKm(
              user.latitude,
              user.longitude,
              b.latitude,
              b.longitude,
            );
            return da.compareTo(db);
          });
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masjid berhasil ditambahkan'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openDetailMasjid(Masjid masjid) async {
    final updated = await Navigator.push<Masjid>(
      context,
      MaterialPageRoute(builder: (_) => MasjidDetailScreen(masjid: masjid)),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _masjids = _masjids
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
    });
  }

  List<PrayerTime> _fallbackPrayers() {
    final now = DateTime.now();
    return [
      _time('Imsak', now, 4, 31),
      _time('Subuh', now, 4, 41),
      _time('Dzuhur', now, 12, 3, isNext: true),
      _time('Ashar', now, 15, 24),
      _time('Maghrib', now, 17, 55),
      _time('Isya', now, 19, 8),
    ];
  }

  PrayerTime _time(String name, DateTime date, int hour, int minute,
      {bool isNext = false}) {
    return PrayerTime(
      name: name,
      nameAr: name,
      time: DateTime(date.year, date.month, date.day, hour, minute),
      isNext: isNext,
    );
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Usholli',
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.nightlight_round,
                        color: AppTheme.accent, size: 20),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Assalamu' 'alaikum, Farid',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              fixedSize: const Size(42, 42),
            ),
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
          ),
        ],
      ),
    );
  }
}

class _QuranPrayerCard extends StatelessWidget {
  final List<PrayerTime> prayers;
  final PrayerTime nextPrayer;
  final String dateLabel;
  final String hijriDate;
  final String countdown;

  const _QuranPrayerCard({
    required this.prayers,
    required this.nextPrayer,
    required this.dateLabel,
    required this.hijriDate,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jadwal Sholat & Qur' 'an',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kamis, $dateLabel / $hijriDate',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sholat ${nextPrayer.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextPrayer.timeString,
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            countdown,
                            style: const TextStyle(
                              color: Color(0xFFCDE4D8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _MosqueSilhouette(),
                    const SizedBox(width: 8),
                    const Icon(Icons.wb_sunny_outlined,
                        color: AppTheme.accent, size: 24),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: prayers.take(6).map((prayer) {
                    return Expanded(child: _MiniPrayer(prayer: prayer));
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _MiniPrayer extends StatelessWidget {
  final PrayerTime prayer;

  const _MiniPrayer({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final active = prayer.isNext;
    return Column(
      children: [
        Icon(
          _icon(prayer.name),
          color: active ? AppTheme.accent : const Color(0xFFCDE4D8),
          size: 16,
        ),
        const SizedBox(height: 5),
        Text(
          prayer.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? AppTheme.accent : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          prayer.timeString,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  IconData _icon(String name) => switch (name) {
        'Imsak' => Icons.wb_twilight_outlined,
        'Subuh' => Icons.wb_twilight_outlined,
        'Syuruq' => Icons.wb_sunny_outlined,
        'Dzuhur' => Icons.light_mode_outlined,
        'Ashar' => Icons.cloud_outlined,
        'Maghrib' => Icons.wb_twilight,
        'Isya' => Icons.nights_stay_outlined,
        _ => Icons.access_time,
      };
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 19),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9.5,
                height: 1.25,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppTheme.primaryDark, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyVerseCard extends StatelessWidget {
  const _DailyVerseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _VerseNumber(),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontFamily: 'serif',
                    fontSize: 18,
                    height: 1.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Wa may yattaqillaaha yaj`al lahuu makhrajaa, wa yarzuqhu min haytsu laa yahtasib.',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '"Barangsiapa bertakwa kepada Allah, niscaya Dia akan membukakan jalan keluar baginya, dan memberinya rezeki dari arah yang tidak disangka-sangkanya."',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '(QS. At-Talaq: 2)',
            style: TextStyle(
              color: AppTheme.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaCard extends StatelessWidget {
  const _QiblaCard();

  @override
  Widget build(BuildContext context) {
    return _ActionBanner(
      icon: Icons.explore,
      title: 'Arah Kiblat',
      subtitle: 'Ketuk untuk melihat arah kiblat Anda',
      trailing: Icons.chevron_right,
      onTap: () {},
    );
  }
}

class _MasjidListSection extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Masjid> masjids;
  final LocationResult? userLocation;
  final MasjidService masjidService;
  final VoidCallback onRetry;
  final VoidCallback onAdd;
  final ValueChanged<Masjid> onOpen;

  const _MasjidListSection({
    required this.loading,
    required this.error,
    required this.masjids,
    required this.userLocation,
    required this.masjidService,
    required this.onRetry,
    required this.onAdd,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 132,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (error != null) {
      return _MasjidMessageCard(
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat masjid',
        subtitle: error!,
        actionLabel: 'Coba Lagi',
        onAction: onRetry,
      );
    }

    if (masjids.isEmpty) {
      return _MasjidMessageCard(
        icon: Icons.mosque_outlined,
        title: 'Belum ada masjid',
        subtitle: 'Tambahkan masjid pertama agar tampil di menu Explore.',
        actionLabel: 'Tambah Masjid',
        onAction: onAdd,
      );
    }

    return Column(
      children: masjids
          .map(
            (masjid) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExploreMosqueCard(
                masjid: masjid,
                distanceText: _distanceText(masjid),
                onTap: () => onOpen(masjid),
              ),
            ),
          )
          .toList(),
    );
  }

  String _distanceText(Masjid masjid) {
    final location = userLocation;
    if (location == null || (masjid.latitude == 0 && masjid.longitude == 0)) {
      return 'Jarak belum tersedia';
    }
    return '${masjidService.jarakStr(
      location.latitude,
      location.longitude,
      masjid.latitude,
      masjid.longitude,
    )} dari lokasi Anda';
  }
}

class _MasjidMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _MasjidMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryDark),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreMosqueCard extends StatelessWidget {
  final Masjid masjid;
  final String distanceText;
  final VoidCallback onTap;

  const _ExploreMosqueCard({
    required this.masjid,
    required this.distanceText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            const SizedBox(
              width: 110,
              height: double.infinity,
              child: _MosqueCardImage(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            masjid.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (masjid.terverifikasi)
                          const Icon(Icons.verified_rounded,
                              color: AppTheme.accent, size: 16),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${masjid.alamat}, ${masjid.kota}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.near_me_outlined,
                            color: AppTheme.primary, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            distanceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 30,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryDark,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengingat Sholat',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Atur pengingat agar tidak terlewat sholat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                ),
              ],
            ),
          ),
          const Text(
            'Aktif',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right,
              color: AppTheme.primaryDark, size: 18),
        ],
      ),
    );
  }
}

class _ActionBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;

  const _ActionBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accent),
              ),
              child: Icon(icon, color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFFCDE4D8), fontSize: 9.5),
                  ),
                ],
              ),
            ),
            Icon(trailing, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.actionLabel = 'Lihat Semua',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction ?? () {},
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryDark,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            children: [
              Text(
                actionLabel,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _MosqueCardImage extends StatelessWidget {
  const _MosqueCardImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDCEBF0), Color(0xFFF6D5A9), Color(0xFF2F6C55)],
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 14,
            right: 12,
            child: Container(
              width: 16,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Icon(
              Icons.mosque,
              color: Colors.white.withValues(alpha: 0.94),
              size: 70,
            ),
          ),
        ],
      ),
    );
  }
}

class _MosqueSilhouette extends StatelessWidget {
  const _MosqueSilhouette();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 62,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            right: 8,
            child: Icon(
              Icons.mosque,
              color: const Color(0xFFCDE4D8).withValues(alpha: 0.32),
              size: 64,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 8,
            child: Container(
              width: 7,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFCDE4D8).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 5,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFCDE4D8).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseNumber extends StatelessWidget {
  const _VerseNumber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Center(
        child: Text(
          '2',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
