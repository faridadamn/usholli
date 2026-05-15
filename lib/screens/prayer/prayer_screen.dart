import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/komunitas_models.dart';
import '../../models/prayer_time.dart';
import '../../services/location_service.dart';
import '../../services/masjid_service.dart';
import '../../services/prayer_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';
import 'city_picker_sheet.dart';
import 'notification_settings_screen.dart';
import '../masjid/masjid_detail_screen.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerProvider>().loadPrayers();
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
            if (provider.state == PrayerLoadState.loading) {
              return const ShimmerPrayerLoader();
            }
            if (provider.state == PrayerLoadState.error) {
              return _ErrorState(provider: provider);
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHeader(
                    city: provider.location?.cityName ?? 'Jakarta Selatan',
                    onPickCity: () => _showCityPicker(context),
                    onNotifications: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: provider.schedule == null
                      ? const SizedBox.shrink()
                      : _HomeContent(provider: provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPickerSheet(
        onCitySelected: (city) {
          Navigator.pop(context);
          context.read<PrayerProvider>().switchToCity(city);
        },
        onUseGps: () {
          Navigator.pop(context);
          context.read<PrayerProvider>().loadPrayers();
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String city;
  final VoidCallback onPickCity;
  final VoidCallback onNotifications;

  const _HomeHeader({
    required this.city,
    required this.onPickCity,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                onPressed: onNotifications,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(42, 42),
                ),
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SearchPill(
                  icon: Icons.search,
                  text: 'Cari masjid atau lokasi',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              _LocationPill(city: city, onTap: onPickCity),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final PrayerProvider provider;

  const _HomeContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _HomeContentBody(provider: provider);
  }
}

class _HomeContentBody extends StatefulWidget {
  final PrayerProvider provider;

  const _HomeContentBody({required this.provider});

  @override
  State<_HomeContentBody> createState() => _HomeContentBodyState();
}

class _HomeContentBodyState extends State<_HomeContentBody> {
  final MasjidService _masjidService = MasjidService();
  final LocationService _locationService = LocationService();
  List<Masjid> _masjids = [];
  LocationResult? _location;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMasjids());
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final nextPrayer = provider.nextPrayer;
    final schedule = provider.schedule!;
    final prayers = schedule.markedPrayers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Column(
        children: [
          _PrayerTodayCard(
            prayers: prayers,
            hijriDate: schedule.hijriDate,
            gregorianDate: _formatDate(schedule.date),
            countdown: provider.countdownString,
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Masjid Terdekat'),
          const SizedBox(height: 8),
          _MosqueSection(
            loading: _loading,
            error: _error,
            masjids: _masjids,
            location: _location,
            masjidService: _masjidService,
            nextPrayer: nextPrayer,
            onRetry: _loadMasjids,
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Aktivitas Hari Ini'),
          const SizedBox(height: 8),
          _ActivityStrip(masjids: _masjids),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Masjid Favorit'),
          const SizedBox(height: 8),
          _FavoriteMosqueCard(
            masjid: _masjids.isNotEmpty ? _masjids.first : null,
            location: _location,
            masjidService: _masjidService,
            nextPrayer: nextPrayer,
          ),
        ],
      ),
    );
  }

  Future<void> _loadMasjids() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final location = await _locationService.getLocation();
      final masjids = await _masjidService.terdekat(
        lat: location.latitude,
        lng: location.longitude,
      );
      if (!mounted) return;
      setState(() {
        _location = location;
        _masjids = masjids;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _PrayerTodayCard extends StatelessWidget {
  final List<PrayerTime> prayers;
  final String hijriDate;
  final String gregorianDate;
  final String countdown;

  const _PrayerTodayCard({
    required this.prayers,
    required this.hijriDate,
    required this.gregorianDate,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jadwal Sholat Hari Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$gregorianDate | $hijriDate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFCDE4D8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const _TinyButton(
                  label: 'Lihat Semua', icon: Icons.calendar_month),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: prayers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prayer = prayers[index];
                return _PrayerTimeTile(
                  prayer: prayer,
                  countdown: prayer.isNext ? countdown : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerTimeTile extends StatelessWidget {
  final PrayerTime prayer;
  final String? countdown;

  const _PrayerTimeTile({required this.prayer, this.countdown});

  @override
  Widget build(BuildContext context) {
    final active = prayer.isNext;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: active ? 88 : 66,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1D7E55) : AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              active ? AppTheme.accent : Colors.white.withValues(alpha: 0.10),
          width: active ? 1.3 : 0.6,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _prayerIcon(prayer.name),
            color: active ? AppTheme.accent : const Color(0xFFCDE4D8),
            size: active ? 25 : 21,
          ),
          const SizedBox(height: 8),
          Text(
            prayer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: active ? 1 : 0.86),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prayer.timeString,
            style: TextStyle(
              color: active ? AppTheme.accent : Colors.white,
              fontSize: active ? 18 : 14,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          if (countdown != null) ...[
            const SizedBox(height: 4),
            Text(
              countdown!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFCDE4D8),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _prayerIcon(String name) => switch (name) {
        'Subuh' => Icons.wb_twilight_outlined,
        'Syuruq' => Icons.wb_sunny_outlined,
        'Dzuhur' => Icons.light_mode_outlined,
        'Ashar' => Icons.cloud_outlined,
        'Maghrib' => Icons.wb_twilight,
        'Isya' => Icons.nights_stay_outlined,
        _ => Icons.access_time,
      };
}

class _MosqueSection extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Masjid> masjids;
  final LocationResult? location;
  final MasjidService masjidService;
  final PrayerTime? nextPrayer;
  final VoidCallback onRetry;

  const _MosqueSection({
    required this.loading,
    required this.error,
    required this.masjids,
    required this.location,
    required this.masjidService,
    required this.nextPrayer,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _HomeMessageCard(
        icon: Icons.mosque_outlined,
        title: 'Memuat masjid terdekat',
        subtitle: 'Mengambil data masjid dari lokasi Anda...',
      );
    }
    if (error != null) {
      return _HomeMessageCard(
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat masjid',
        subtitle: error!,
        actionLabel: 'Coba Lagi',
        onAction: onRetry,
      );
    }
    if (masjids.isEmpty) {
      return const _HomeMessageCard(
        icon: Icons.mosque_outlined,
        title: 'Belum ada masjid',
        subtitle: 'Tambahkan masjid di menu Explore agar tampil di Beranda.',
      );
    }
    final masjid = masjids.first;
    return _MosqueCard(
      masjid: masjid,
      distance: _distance(masjid),
      nextPrayer: nextPrayer,
    );
  }

  String _distance(Masjid masjid) {
    final loc = location;
    if (loc == null || (masjid.latitude == 0 && masjid.longitude == 0)) {
      return 'Jarak belum tersedia';
    }
    return masjidService.jarakStr(
      loc.latitude,
      loc.longitude,
      masjid.latitude,
      masjid.longitude,
    );
  }
}

class _HomeMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _HomeMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
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
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _FavoriteMosqueCard extends StatelessWidget {
  final Masjid? masjid;
  final LocationResult? location;
  final MasjidService masjidService;
  final PrayerTime? nextPrayer;

  const _FavoriteMosqueCard({
    required this.masjid,
    required this.location,
    required this.masjidService,
    required this.nextPrayer,
  });

  @override
  Widget build(BuildContext context) {
    final item = masjid;
    if (item == null) {
      return const _HomeMessageCard(
        icon: Icons.favorite_border,
        title: 'Belum ada masjid favorit',
        subtitle: 'Masjid terdekat akan tampil setelah data tersedia.',
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _MosqueCard(
          masjid: item,
          distance: _distance(item),
          nextPrayer: nextPrayer,
        ),
        Positioned(
          top: -8,
          left: 10,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child:
                const Icon(Icons.favorite, color: Color(0xFFE64040), size: 17),
          ),
        ),
      ],
    );
  }

  String _distance(Masjid masjid) {
    final loc = location;
    if (loc == null || (masjid.latitude == 0 && masjid.longitude == 0)) {
      return 'Jarak belum tersedia';
    }
    return masjidService.jarakStr(
      loc.latitude,
      loc.longitude,
      masjid.latitude,
      masjid.longitude,
    );
  }
}

class _MosqueCard extends StatelessWidget {
  final Masjid masjid;
  final String distance;
  final PrayerTime? nextPrayer;

  const _MosqueCard({
    required this.masjid,
    required this.distance,
    required this.nextPrayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: double.infinity,
            child: Stack(
              children: [
                const Positioned.fill(child: _MosqueImageMock()),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me,
                            color: Colors.white, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          distance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    masjid.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeBlock(
                          label: nextPrayer == null
                              ? 'Jadwal berikutnya'
                              : 'Sholat ${nextPrayer!.name}',
                          value: nextPrayer?.timeString ?? '-',
                        ),
                      ),
                      Text(
                        '${masjid.jamaahCount} jamaah',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      _AmenityChip(icon: Icons.local_parking, text: 'Parkir'),
                      SizedBox(width: 4),
                      _AmenityChip(icon: Icons.ac_unit, text: 'AC'),
                      SizedBox(width: 4),
                      _AmenityChip(
                          icon: Icons.water_drop_outlined, text: 'Wudhu'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MasjidDetailScreen(masjid: masjid),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
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
                          fontWeight: FontWeight.w800,
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
    );
  }

  String get _address {
    final parts = [masjid.alamat, masjid.kota, masjid.provinsi]
        .where((value) => value.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Alamat belum tersedia' : parts.join(', ');
  }
}

class _ActivityStrip extends StatelessWidget {
  final List<Masjid> masjids;

  const _ActivityStrip({required this.masjids});

  @override
  Widget build(BuildContext context) {
    final firstMasjid =
        masjids.isNotEmpty ? masjids.first.nama : 'Masjid terdekat';
    final activities = [
      _ActivityData(
          Icons.menu_book, '07:00 - 08:00', 'Kajian Pagi', firstMasjid),
      _ActivityData(
          Icons.group, '13:00 - 14:00', 'Tahlil Al-Quran', firstMasjid),
      const _ActivityData(
          Icons.favorite, '16:00 - 17:00', 'Berbagi Berkah', 'Program Donasi'),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _ActivityCard(data: activities[index]),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _ActivityData data;

  const _ActivityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: AppTheme.primary, size: 17),
          ),
          const SizedBox(height: 8),
          Text(
            data.time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
          ),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 10, color: AppTheme.primary),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  data.place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 8.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

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
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryDark,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 3),
              Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SearchPill({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  final String city;
  final VoidCallback onTap;

  const _LocationPill({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        constraints: const BoxConstraints(maxWidth: 142),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppTheme.primary, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down,
                color: AppTheme.textSecondary, size: 15),
          ],
        ),
      ),
    );
  }
}

class _MosqueImageMock extends StatelessWidget {
  const _MosqueImageMock();

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
            top: 18,
            right: 12,
            child: Container(
              width: 18,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.nightlight_round,
                      size: 9, color: AppTheme.primary),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            child: Icon(
              Icons.mosque,
              color: Colors.white.withValues(alpha: 0.94),
              size: 74,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const _TinyButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.accent),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: AppTheme.accent),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final String value;

  const _TimeBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primaryDark,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AmenityChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 9, color: AppTheme.primary),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final PrayerProvider provider;

  const _ErrorState({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              provider.errorMsg ?? 'Terjadi kesalahan',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: provider.loadPrayers,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityData {
  final IconData icon;
  final String time;
  final String title;
  final String place;

  const _ActivityData(this.icon, this.time, this.title, this.place);
}
