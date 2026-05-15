import 'package:flutter/material.dart';
import '../../models/komunitas_models.dart';
import '../../services/location_service.dart';
import '../../services/masjid_service.dart';
import '../../theme/app_theme.dart';
import 'masjid_form_screen.dart';

class MasjidDetailScreen extends StatefulWidget {
  final Masjid masjid;

  const MasjidDetailScreen({super.key, required this.masjid});

  @override
  State<MasjidDetailScreen> createState() => _MasjidDetailScreenState();
}

class _MasjidDetailScreenState extends State<MasjidDetailScreen> {
  final MasjidService _service = MasjidService();
  final LocationService _locationService = LocationService();
  late Masjid _masjid;
  LocationResult? _userLocation;

  @override
  void initState() {
    super.initState();
    _masjid = widget.masjid;
    _loadUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onBack: () => Navigator.pop(context, _masjid)),
                    const SizedBox(height: 14),
                    _ProfileCard(
                      masjid: _masjid,
                      distance: _distanceText(),
                      onOpenProfile: _openEditForm,
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Kelola Masjid'),
                    const SizedBox(height: 10),
                    _ManagementGrid(onEditProfile: _openEditForm),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Ringkasan Masjid'),
                    const SizedBox(height: 10),
                    _SummaryGrid(masjid: _masjid),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                            child: _SectionTitle(title: 'Agenda Mendatang')),
                        _SeeAllButton(onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _AgendaCard(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                            child: _SectionTitle(title: 'Aktivitas Terbaru')),
                        _SeeAllButton(onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _ActivityList(),
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditForm() async {
    final updated = await Navigator.push<Masjid>(
      context,
      MaterialPageRoute(
        builder: (_) => MasjidFormScreen(initialMasjid: _masjid),
      ),
    );
    if (updated == null || !mounted) return;

    try {
      final saved = await _service.update(updated);
      if (!mounted) return;
      setState(() => _masjid = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data masjid berhasil diperbarui'),
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

  Future<void> _loadUserLocation() async {
    try {
      final location = await _locationService.getGpsLocation();
      if (!mounted) return;
      setState(() => _userLocation = location);
    } catch (_) {}
  }

  String _distanceText() {
    final location = _userLocation;
    if (location == null || (_masjid.latitude == 0 && _masjid.longitude == 0)) {
      return 'Jarak belum tersedia';
    }
    return _service.jarakStr(
      location.latitude,
      location.longitude,
      _masjid.latitude,
      _masjid.longitude,
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 34,
            height: 34,
            child:
                Icon(Icons.arrow_back, color: AppTheme.primaryDark, size: 22),
          ),
        ),
        const SizedBox(width: 4),
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
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.nightlight_round,
                      color: AppTheme.accent, size: 18),
                ],
              ),
              SizedBox(height: 3),
              Text(
                'Dashboard DKM',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
            fixedSize: const Size(40, 40),
          ),
          icon: const Icon(Icons.notifications_none_rounded, size: 21),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Masjid masjid;
  final String distance;
  final VoidCallback onOpenProfile;

  const _ProfileCard({
    required this.masjid,
    required this.distance,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 126,
            height: double.infinity,
            child: masjid.fotoUrl != null && masjid.fotoUrl!.isNotEmpty
                ? Image.network(
                    masjid.fotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _MosquePhotoMock(),
                  )
                : const _MosquePhotoMock(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (masjid.terverifikasi)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: AppTheme.primaryDark, size: 11),
                          SizedBox(width: 3),
                          Text(
                            'Terverifikasi',
                            style: TextStyle(
                              color: AppTheme.primaryDark,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    masjid.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD7E7DE),
                      fontSize: 10,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.near_me_outlined,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          distance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
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
                    child: OutlinedButton(
                      onPressed: onOpenProfile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.42)),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lihat Profil Masjid',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.chevron_right, size: 14),
                        ],
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

class _ManagementGrid extends StatelessWidget {
  final VoidCallback onEditProfile;

  const _ManagementGrid({required this.onEditProfile});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(Icons.mosque_outlined, 'Profil Masjid', onEditProfile),
      _MenuItem(Icons.menu_book_outlined, 'Kajian', () {}),
      _MenuItem(Icons.calendar_month_outlined, 'Kegiatan', () {}),
      _MenuItem(Icons.volunteer_activism_outlined, 'Donasi', () {}),
      _MenuItem(Icons.groups_outlined, 'Jamaah', () {}),
      _MenuItem(Icons.campaign_outlined, 'Pengumuman', () {}),
      _MenuItem(Icons.account_tree_outlined, 'Struktur DKM', () {}),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) => _MenuTile(item: items[index]),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: AppTheme.primary, size: 23),
            const SizedBox(height: 7),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 9.5,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final Masjid masjid;

  const _SummaryGrid({required this.masjid});

  @override
  Widget build(BuildContext context) {
    final jamaah = masjid.jamaahCount <= 0 ? 0 : masjid.jamaahCount;
    final items = [
      _SummaryItem(Icons.groups_outlined, _formatNumber(jamaah), 'Total Jamaah',
          '+86\nvs bulan lalu'),
      const _SummaryItem(Icons.calendar_month_outlined, '12',
          'Kegiatan Bulanan', '+3\nvs bulan lalu'),
      const _SummaryItem(Icons.volunteer_activism_outlined, 'Rp 48.750.000',
          'Donasi Terkumpul', '+12%\nvs bulan lalu'),
      const _SummaryItem(
          Icons.schedule_outlined, '7', 'Permintaan Menunggu', 'Aproval'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) => _SummaryTile(item: items[index]),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      final thousands = value ~/ 1000;
      final rest = value.remainder(1000).toString().padLeft(3, '0');
      return '$thousands.$rest';
    }
    return '$value';
  }
}

class _SummaryTile extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Icon(item.icon, color: AppTheme.primary, size: 18),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.value,
              maxLines: 1,
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 8.5,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            item.delta,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 8,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('16',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                Text('MEI',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kajian Tafsir Al-Quran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Jumat, 16 Mei 2026',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                ),
                SizedBox(height: 3),
                Text(
                  '19:30 - 21:00',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                ),
                SizedBox(height: 7),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 11, color: AppTheme.primary),
                    SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        'Masjid Agung Al-Azhar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    const items = [
      _ActivityItem(Icons.volunteer_activism_outlined,
          'Donasi masuk sebesar Rp 500.000', '5 jam yang lalu'),
      _ActivityItem(Icons.calendar_month_outlined,
          'Kegiatan "Kajian Subuh" ditambahkan', '2 jam yang lalu'),
      _ActivityItem(Icons.campaign_outlined,
          'Pengumuman "Libur Maulid" dipublikasikan', '3 jam yang lalu'),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 10),
            child: _ActivityRow(item: items[index]),
          );
        }),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(item.icon, color: AppTheme.primary, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.time,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8.5),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.primaryDark,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SeeAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryDark,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 26),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'Lihat Semua',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MosquePhotoMock extends StatelessWidget {
  const _MosquePhotoMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDCEBF0), Color(0xFFF1D2A2), Color(0xFF2F6C55)],
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 15,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            child: Icon(
              Icons.mosque,
              color: Colors.white.withValues(alpha: 0.92),
              size: 78,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem(this.icon, this.label, this.onTap);
}

class _SummaryItem {
  final IconData icon;
  final String value;
  final String label;
  final String delta;

  const _SummaryItem(this.icon, this.value, this.label, this.delta);
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String time;

  const _ActivityItem(this.icon, this.title, this.time);
}
