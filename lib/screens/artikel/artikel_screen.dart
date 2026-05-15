import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/artikel_provider.dart';
import '../../models/artikel_models.dart';
import '../../theme/app_theme.dart';
import 'artikel_detail_screen.dart';

class ArtikelScreen extends StatefulWidget {
  const ArtikelScreen({super.key});

  @override
  State<ArtikelScreen> createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArtikelProvider>().loadArtikel(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Consumer<ArtikelProvider>(
        builder: (ctx, provider, _) => CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildKategoriFilter(provider)),
            if (provider.listState == ArtikelLoadState.loading && provider.artikelList.isEmpty)
              const SliverToBoxAdapter(child: _ArtikelShimmer()),
            if (provider.listState == ArtikelLoadState.error)
              SliverFillRemaining(child: _buildError(provider)),
            if (provider.artikelList.isNotEmpty) ...[
              // Artikel utama (featured) — card besar
              SliverToBoxAdapter(
                child: _FeaturedCard(
                  artikel: provider.artikelList.first,
                  onTap: () => _buka(ctx, provider, provider.artikelList.first),
                ),
              ),
              // Sisa artikel — list kompak
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.builder(
                  itemCount: provider.artikelList.length - 1 + (provider.hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == provider.artikelList.length - 1) {
                      // Load more trigger
                      provider.loadMore();
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
                      );
                    }
                    final artikel = provider.artikelList[i + 1];
                    return _ArtikelTile(
                      artikel: artikel,
                      onTap: () => _buka(ctx, provider, artikel),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() => SliverAppBar(
    pinned: true,
    backgroundColor: AppTheme.primary,
    foregroundColor: Colors.white,
    title: const Text('Artikel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
  );

  Widget _buildKategoriFilter(ArtikelProvider provider) {
    final selected = provider.filterKategori;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          // Chip "Semua"
          _FilterChip(
            label: 'Semua',
            emoji: '📋',
            selected: selected == null,
            onTap: () => provider.setFilter(null),
          ),
          ...ArtikelKategori.all.map((k) => _FilterChip(
            label: k.nama,
            emoji: k.emoji,
            selected: selected == k.id,
            onTap: () => provider.setFilter(k.id),
          )),
        ],
      ),
    );
  }

  Widget _buildError(ArtikelProvider provider) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        Text(provider.listError ?? 'Gagal memuat artikel',
            style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => provider.loadArtikel(refresh: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Coba Lagi'),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
        ),
      ],
    ),
  );

  void _buka(BuildContext ctx, ArtikelProvider provider, Artikel artikel) {
    provider.loadDetail(artikel.id);
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => ArtikelDetailScreen(artikel: artikel),
    ));
  }
}

// ── Filter chip kategori ──────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label, emoji;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.emoji, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider, width: selected ? 0 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppTheme.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Featured card (artikel pertama, besar) ────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final Artikel artikel;
  final VoidCallback onTap;

  const _FeaturedCard({required this.artikel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: artikel.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: artikel.thumbnailUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(height: 180, color: AppTheme.divider),
                      errorWidget: (_, __, ___) => _PlaceholderThumb(height: 180, kategori: artikel.kategori),
                    )
                  : _PlaceholderThumb(height: 180, kategori: artikel.kategori),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori + masjid
                  Row(
                    children: [
                      _KategoriPill(kategori: artikel.kategori),
                      const Spacer(),
                      Text(artikel.masjidNama,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(artikel.judul,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35)),
                  const SizedBox(height: 6),
                  Text(artikel.ringkasan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
                  const SizedBox(height: 12),
                  _ArticleFooter(artikel: artikel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Artikel tile (list kompak) ────────────────────────────────────────────────

class _ArtikelTile extends StatelessWidget {
  final Artikel artikel;
  final VoidCallback onTap;

  const _ArtikelTile({required this.artikel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail kecil
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: artikel.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: artikel.thumbnailUrl!,
                      width: 76, height: 76,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _PlaceholderThumb(height: 76, width: 76, kategori: artikel.kategori),
                    )
                  : _PlaceholderThumb(height: 76, width: 76, kategori: artikel.kategori),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KategoriPill(kategori: artikel.kategori, small: true),
                  const SizedBox(height: 4),
                  Text(artikel.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35)),
                  const SizedBox(height: 6),
                  _ArticleFooter(artikel: artikel, compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _KategoriPill extends StatelessWidget {
  final ArtikelKategori kategori;
  final bool small;
  const _KategoriPill({required this.kategori, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${kategori.emoji} ${kategori.nama}',
        style: TextStyle(
          fontSize: small ? 10 : 11,
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ArticleFooter extends StatelessWidget {
  final Artikel artikel;
  final bool compact;
  const _ArticleFooter({required this.artikel, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 3),
        Flexible(child: Text(artikel.penulisNama,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
        const SizedBox(width: 8),
        const Icon(Icons.access_time, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text(artikel.waktuPublikasi, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        if (!compact) ...[
          const Spacer(),
          const Icon(Icons.favorite_border, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text('${artikel.likeCount}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(width: 8),
          const Icon(Icons.remove_red_eye_outlined, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text('${artikel.viewCount}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ],
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  final double height;
  final double? width;
  final ArtikelKategori kategori;

  const _PlaceholderThumb({required this.height, required this.kategori, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, width: width ?? double.infinity,
      color: AppTheme.primary.withOpacity(0.08),
      child: Center(
        child: Text(kategori.emoji, style: TextStyle(fontSize: height > 100 ? 48 : 28)),
      ),
    );
  }
}

class _ArtikelShimmer extends StatelessWidget {
  const _ArtikelShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(height: 240, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 90,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
          )),
        ],
      ),
    );
  }
}
