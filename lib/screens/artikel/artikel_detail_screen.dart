import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/artikel_provider.dart';
import '../../models/artikel_models.dart';
import '../../theme/app_theme.dart';

class ArtikelDetailScreen extends StatelessWidget {
  final Artikel artikel; // data awal (untuk header langsung tampil)

  const ArtikelDetailScreen({super.key, required this.artikel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ArtikelProvider>(
        builder: (ctx, provider, _) {
          final detail = provider.detail ?? artikel;
          final isLoading = provider.detailState == ArtikelLoadState.loading;

          return CustomScrollView(
            slivers: [
              _buildAppBar(ctx, provider, detail),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(detail),
                    _buildKonten(detail, isLoading),
                    _buildLikeBar(ctx, provider, detail),
                    const Divider(height: 1),
                    _buildKomentar(ctx, provider, detail),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext ctx, ArtikelProvider provider, Artikel detail) {
    return SliverAppBar(
      expandedHeight: detail.thumbnailUrl != null ? 220 : 0,
      pinned: true,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: detail.thumbnailUrl != null
          ? FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: detail.thumbnailUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: AppTheme.primary),
              ),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {}, // TODO: share_plus
        ),
      ],
    );
  }

  Widget _buildHeader(Artikel detail) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori + masjid
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${detail.kategori.emoji} ${detail.kategori.nama}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(detail.masjidNama,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Judul
          Text(detail.judul,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 14),

          // Penulis + waktu + view
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: Text(
                  detail.penulisNama.isNotEmpty ? detail.penulisNama[0].toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.penulisNama,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(detail.waktuPublikasi,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('${detail.viewCount}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),

          // Tags
          if (detail.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: detail.tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider, width: 0.5),
                ),
                child: Text('#$t', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              )).toList(),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKonten(Artikel detail, bool isLoading) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(5, (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
      );
    }

    // Render konten teks (Markdown-lite: baris kosong = paragraf)
    final paragraphs = detail.konten.split('\n\n');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.map((p) {
          // Heading sederhana: baris dimulai dengan "# "
          if (p.startsWith('# ')) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 6),
              child: Text(p.substring(2),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
            );
          }
          if (p.startsWith('## ')) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(p.substring(3),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
            );
          }
          // Kutipan: dimulai dengan "> "
          if (p.startsWith('> ')) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                border: Border(left: BorderSide(color: AppTheme.primary, width: 3)),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(p.substring(2),
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic, height: 1.7)),
            );
          }
          // Paragraf biasa
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(p, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.85)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLikeBar(BuildContext ctx, ArtikelProvider provider, Artikel detail) {
    final liked = provider.isLiked(detail.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => provider.toggleLike(detail.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: liked ? Colors.red.shade50 : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: liked ? Colors.red.shade200 : AppTheme.divider,
                    width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(liked ? Icons.favorite : Icons.favorite_border,
                      size: 18, color: liked ? Colors.red : AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('${detail.likeCount}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: liked ? Colors.red : AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.comment_outlined, size: 17, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text('${provider.komentar.length} komentar',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKomentar(BuildContext ctx, ArtikelProvider provider, Artikel detail) {
    final komentarList = provider.komentar;
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Komentar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),

          // Form komentar
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
                    hintStyle: const TextStyle(fontSize: 14),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.divider, width: 0.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // TODO: pakai auth token dari Supabase Auth
                  if (controller.text.trim().isEmpty) return;
                  provider.tambahKomentar(
                    artikelId: detail.id,
                    userId:    'guest',
                    userName:  'Jamaah',
                    isi:       controller.text.trim(),
                    token:     'USER_TOKEN',
                  );
                  controller.clear();
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // List komentar
          if (komentarList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada komentar. Jadilah yang pertama! 🙂',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            )
          else
            ...komentarList.map((k) => _KomentarTile(komentar: k)),
        ],
      ),
    );
  }
}

class _KomentarTile extends StatelessWidget {
  final Komentar komentar;
  const _KomentarTile({required this.komentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary.withOpacity(0.12),
            child: Text(
              komentar.userName.isNotEmpty ? komentar.userName[0].toUpperCase() : 'J',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(komentar.userName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        _formatWaktu(komentar.createdAt),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(komentar.isi,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWaktu(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24)   return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
  }
}
