import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/hadis_models.dart';
import '../../services/hadis_provider.dart';
import '../../theme/app_theme.dart';

class HadisScreen extends StatefulWidget {
  const HadisScreen({super.key});

  @override
  State<HadisScreen> createState() => _HadisScreenState();
}

class _HadisScreenState extends State<HadisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HadisProvider>().loadHariIni();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Consumer<HadisProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HadisHeader(),
                        const SizedBox(height: 18),
                        _DailyHadisCard(provider: provider),
                        const SizedBox(height: 18),
                        const Text(
                          'Jelajahi Hadis',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _HadisCategoryList(provider: provider),
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
}

class _HadisHeader extends StatelessWidget {
  const _HadisHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
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
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.nightlight_round,
                      color: AppTheme.accent, size: 19),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Assalamu\'alaikum, Farid',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Hadis',
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Belajar dari sabda Rasulullah ﷺ',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            IconButton.filled(
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                fixedSize: const Size(40, 40),
              ),
              icon: const Icon(Icons.notifications_none_rounded, size: 21),
            ),
            const SizedBox(height: 18),
            const _BookStackIllustration(),
          ],
        ),
      ],
    );
  }
}

class _DailyHadisCard extends StatelessWidget {
  final HadisProvider provider;

  const _DailyHadisCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final hadis = provider.hadisHariIni;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: switch (provider.hariIniState) {
        HadisLoadState.loading => const SizedBox(
            height: 190,
            child: Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 2)),
          ),
        HadisLoadState.error => _HadisError(
            message: provider.hariIniError ?? 'Gagal memuat hadis',
            onRetry: provider.loadHariIni,
          ),
        _ => hadis == null
            ? _HadisError(
                message: 'Hadis belum tersedia', onRetry: provider.loadHariIni)
            : _HadisContent(hadis: hadis, provider: provider),
      },
    );
  }
}

class _HadisContent extends StatelessWidget {
  final Hadis hadis;
  final HadisProvider provider;

  const _HadisContent({required this.hadis, required this.provider});

  @override
  Widget build(BuildContext context) {
    final saved = provider.isSaved(hadis);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: AppTheme.primaryDark, size: 17),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Hadis Harian',
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              _dateLabel(),
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          hadis.arab.isEmpty
              ? 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى'
              : hadis.arab,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: AppTheme.primaryDark,
            fontFamily: 'serif',
            fontSize: 22,
            height: 1.9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hadis.terjemahan.isEmpty
              ? '"Sesungguhnya setiap amal itu tergantung niatnya, dan setiap orang akan mendapatkan sesuai dengan apa yang ia niatkan."'
              : hadis.terjemahan,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          hadis.sumber,
          style: const TextStyle(
            color: AppTheme.primaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _HadisAction(
                icon: saved ? Icons.bookmark : Icons.bookmark_border_rounded,
                label: saved ? 'Tersimpan' : 'Simpan',
                onTap: () => provider.toggleSave(hadis),
              ),
            ),
            Expanded(
              child: _HadisAction(
                icon: Icons.share_outlined,
                label: 'Bagikan',
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: '${hadis.terjemahan}\n\n${hadis.sumber}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hadis disalin untuk dibagikan'),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _dateLabel() {
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
    final now = DateTime.now();
    return 'Kamis, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _HadisCategoryList extends StatelessWidget {
  final HadisProvider provider;

  const _HadisCategoryList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final items = [
      _CategoryItem(
          Icons.star_border_rounded,
          'Hadis Pilihan',
          'Kumpulan hadis-hadis shahih pilihan',
          AppTheme.primaryDark,
          HadisKitab.all[2]),
      _CategoryItem(
          Icons.spa_outlined,
          'Tema Akhlak',
          'Hadis tentang budi pekerti dan karakter',
          AppTheme.accent,
          HadisKitab.all[8]),
      _CategoryItem(
          Icons.mosque_outlined,
          'Ibadah',
          'Hadis tentang ibadah sehari-hari',
          AppTheme.primary,
          HadisKitab.all[6]),
      _CategoryItem(
          Icons.family_restroom_outlined,
          'Keluarga',
          'Hadis tentang keluarga dan hubungan',
          const Color(0xFFE39B35),
          HadisKitab.all[4]),
      _CategoryItem(
          Icons.volunteer_activism_outlined,
          'Doa',
          'Kumpulan doa dari Al-Qur\'an & Hadis',
          const Color(0xFF0F5F58),
          HadisKitab.all[0]),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CategoryTile(
                item: item,
                onTap: () => _openCategory(context, item.kitab),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _openCategory(BuildContext context, HadisKitab kitab) async {
    await provider.selectKitab(kitab);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HadisListSheet(provider: provider, kitab: kitab),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _CategoryItem item;
  final VoidCallback onTap;

  const _CategoryTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.primaryDark),
          ],
        ),
      ),
    );
  }
}

class _HadisListSheet extends StatelessWidget {
  final HadisProvider provider;
  final HadisKitab kitab;

  const _HadisListSheet({required this.provider, required this.kitab});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Consumer<HadisProvider>(
            builder: (context, provider, _) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    kitab.keterangan,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (provider.jelajahState == HadisLoadState.loading &&
                      provider.hadisJelajah.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primary)),
                    )
                  else if (provider.hadisJelajah.isEmpty)
                    const _HadisError(
                        message: 'Belum ada hadis pada kategori ini.')
                  else
                    ...provider.hadisJelajah
                        .take(10)
                        .map((hadis) => _HadisPreview(hadis: hadis)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _HadisPreview extends StatelessWidget {
  final Hadis hadis;

  const _HadisPreview({required this.hadis});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hadis.sumber,
            style: const TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            hadis.terjemahan,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _HadisAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HadisAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryDark, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HadisError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _HadisError({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppTheme.textSecondary, size: 32),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookStackIllustration extends StatelessWidget {
  const _BookStackIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 7,
            right: 8,
            child: Transform.rotate(
              angle: -0.08,
              child: Icon(Icons.menu_book_rounded,
                  color: AppTheme.primaryDark.withValues(alpha: 0.95),
                  size: 48),
            ),
          ),
          Positioned(
            bottom: 18,
            right: 24,
            child: Container(width: 36, height: 9, color: AppTheme.accent),
          ),
          Positioned(
            bottom: 4,
            right: 18,
            child:
                Container(width: 42, height: 8, color: const Color(0xFF996C36)),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final HadisKitab kitab;

  const _CategoryItem(
      this.icon, this.title, this.subtitle, this.color, this.kitab);
}
