import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/quran_provider.dart';
import '../../models/quran_models.dart';
import '../../theme/app_theme.dart';
import 'surah_reader_screen.dart';

class QuranBookmarkScreen extends StatelessWidget {
  const QuranBookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Bookmark Ayat'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<QuranProvider>(
        builder: (ctx, provider, _) {
          final bookmarks = provider.getBookmarks();

          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, size: 72, color: AppTheme.divider),
                  const SizedBox(height: 16),
                  const Text('Belum ada ayat yang disimpan',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Tekan ikon bookmark saat membaca ayat',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            itemBuilder: (_, i) {
              final b = bookmarks[i];
              return _BookmarkTile(
                bookmark: b,
                onTap: () => _openAyah(ctx, provider, b),
                onDelete: () => _delete(ctx, provider, b),
              );
            },
          );
        },
      ),
    );
  }

  void _openAyah(BuildContext ctx, QuranProvider provider, QuranBookmark b) {
    final surah = provider.surahList.firstWhere((s) => s.number == b.surahNumber);
    provider.openSurah(surah);
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => SurahReaderScreen(surah: surah, jumpToAyah: b.ayahNumber),
    ));
  }

  void _delete(BuildContext ctx, QuranProvider provider, QuranBookmark b) {
    provider.getBookmarks(); // trigger re-read
    b.delete();
    // ignore: invalid_use_of_protected_member
    (provider as dynamic).notifyListeners();
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Bookmark dihapus'),
          behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final QuranBookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkTile({required this.bookmark, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('${bookmark.surahNumber}_${bookmark.ayahNumber}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bookmark, color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bookmark.surahName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('Ayat ${bookmark.ayahNumber}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
