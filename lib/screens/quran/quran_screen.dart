import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quran_models.dart';
import '../../services/quran_provider.dart';
import '../../theme/app_theme.dart';
import 'quran_bookmark_screen.dart';
import 'surah_reader_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().loadSurahList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Consumer<QuranProvider>(
          builder: (context, provider, _) {
            final surahList = _visibleSurah(provider);
            final featured = _featuredSurah(provider);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _QuranHeader(),
                        const SizedBox(height: 16),
                        _FeaturedSurahCard(
                          surah: featured,
                          onOpen: featured == null
                              ? null
                              : () => _openSurah(context, provider, featured),
                        ),
                        const SizedBox(height: 14),
                        _Tabs(
                          selected: _tab,
                          onChanged: (value) => setState(() => _tab = value),
                        ),
                        const SizedBox(height: 10),
                        if (provider.listState == QuranLoadState.loading)
                          const _QuranLoading()
                        else if (provider.listState == QuranLoadState.error)
                          _QuranMessage(
                            icon: Icons.wifi_off_rounded,
                            title: 'Gagal memuat surah',
                            subtitle: provider.listError ??
                                'Periksa koneksi internet.',
                            onRetry: provider.loadSurahList,
                          )
                        else if (surahList.isEmpty)
                          const _QuranMessage(
                            icon: Icons.menu_book_outlined,
                            title: 'Belum ada data',
                            subtitle: 'Daftar surah belum tersedia.',
                          )
                        else
                          _SurahList(
                            surahs: surahList,
                            provider: provider,
                            onOpen: (surah) =>
                                _openSurah(context, provider, surah),
                          ),
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

  List<Surah> _visibleSurah(QuranProvider provider) {
    final all = provider.surahList;
    if (_tab == 1) {
      final lastRead = provider.lastRead;
      if (lastRead == null) return all.take(5).toList();
      return all
          .where((surah) => surah.number == lastRead.surahNumber)
          .toList();
    }
    if (_tab == 2) {
      final bookmarks = provider.getBookmarks();
      if (bookmarks.isEmpty) return all.take(5).toList();
      final numbers = bookmarks.map((item) => item.surahNumber).toSet();
      return all.where((surah) => numbers.contains(surah.number)).toList();
    }
    return all.take(8).toList();
  }

  Surah? _featuredSurah(QuranProvider provider) {
    if (provider.surahList.isEmpty) return null;
    return provider.surahList.firstWhere(
      (surah) => surah.number == 18,
      orElse: () => provider.surahList.first,
    );
  }

  void _openSurah(BuildContext context, QuranProvider provider, Surah surah) {
    provider.openSurah(surah);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurahReaderScreen(surah: surah)),
    );
  }
}

class _QuranHeader extends StatelessWidget {
  const _QuranHeader();

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
                'Al-Qur\'an',
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Baca, pahami, dan renungkan firman Allah',
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
            const _BookIllustration(),
          ],
        ),
      ],
    );
  }
}

class _FeaturedSurahCard extends StatelessWidget {
  final Surah? surah;
  final VoidCallback? onOpen;

  const _FeaturedSurahCard({required this.surah, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final item = surah;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Surah Hari Ini',
                      style: TextStyle(
                        color: Color(0xFFD7E7DE),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item?.nameId ?? 'Al-Kahfi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item == null ? '18:1-10' : '${item.number}:1-10',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Membaca Al-Qur\'an membawa ketenangan hati.',
                      style: TextStyle(
                        color: Color(0xFFD7E7DE),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const _MosqueSilhouette(),
              const SizedBox(width: 8),
              _RoundIcon(icon: Icons.play_arrow_rounded, onTap: onOpen),
              const SizedBox(width: 7),
              _RoundIcon(
                icon: Icons.bookmark_border_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const QuranBookmarkScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _VerseBadge(number: '1'),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الحمد لله الذي أنزل على عبده الكتاب ولم يجعل له عوجا',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontFamily: 'serif',
                          fontSize: 18,
                          height: 1.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Segala puji bagi Allah yang telah menurunkan Kitab kepada hamba-Nya dan Dia tidak menjadikan padanya sesuatu yang bengkok.',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Alhamdu lillaahil-ladzii anzala \'alaa `abdihil kitaaba wa lam yaj`al lahuu `iwajaa.',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 10.5,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '(QS. Al-Kahfi: 1)',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _Tabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Semua Surah', 'Terakhir Dibaca', 'Favorit'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = selected == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? AppTheme.primaryDark : AppTheme.divider),
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : AppTheme.primaryDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SurahList extends StatelessWidget {
  final List<Surah> surahs;
  final QuranProvider provider;
  final ValueChanged<Surah> onOpen;

  const _SurahList({
    required this.surahs,
    required this.provider,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: List.generate(surahs.length, (index) {
          return _SurahRow(
            surah: surahs[index],
            showDivider: index != surahs.length - 1,
            onOpen: () => onOpen(surahs[index]),
          );
        }),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  final Surah surah;
  final bool showDivider;
  final VoidCallback onOpen;

  const _SurahRow({
    required this.surah,
    required this.showDivider,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 10, 10, 10),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppTheme.divider))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${surah.number}',
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.revelation} - ${surah.ayahCount} ayat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.play_circle_outline_rounded,
                  color: AppTheme.primaryDark, size: 22),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border_rounded,
                  color: AppTheme.textSecondary, size: 21),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranLoading extends StatelessWidget {
  const _QuranLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        6,
        (_) => Container(
          height: 58,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
        ),
      ),
    );
  }
}

class _QuranMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _QuranMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
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
          Icon(icon, color: AppTheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _VerseBadge extends StatelessWidget {
  final String number;

  const _VerseBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.divider),
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            color: AppTheme.primaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _BookIllustration extends StatelessWidget {
  const _BookIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.35,
            child: Icon(Icons.menu_book_rounded,
                color: AppTheme.accent.withValues(alpha: 0.88), size: 58),
          ),
          const Positioned(
            bottom: 4,
            child: Icon(Icons.keyboard_arrow_up_rounded,
                color: AppTheme.primaryDark, size: 34),
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
      width: 70,
      height: 58,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Icon(
              Icons.mosque,
              color: const Color(0xFFD7E7DE).withValues(alpha: 0.20),
              size: 62,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 0,
            child: Container(
              width: 6,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFD7E7DE).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
