import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/quran_provider.dart';
import '../../models/quran_models.dart';
import '../../theme/app_theme.dart';

class SurahReaderScreen extends StatefulWidget {
  final Surah surah;
  final int? jumpToAyah;

  const SurahReaderScreen({super.key, required this.surah, this.jumpToAyah});

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final ScrollController _scroll = ScrollController();
  late GlobalKey<AnimatedListState> _listKey;
  final Map<int, GlobalKey> _ayahKeys = {};

  @override
  void initState() {
    super.initState();
    _listKey = GlobalKey<AnimatedListState>();
    // Auto-scroll ke ayat terakhir dibaca
    if (widget.jumpToAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(widget.jumpToAyah!));
    }
  }

  void _jumpTo(int ayahNum) {
    Future.delayed(const Duration(milliseconds: 400), () {
      final key = _ayahKeys[ayahNum];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(key!.currentContext!, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (ctx, provider, _) {
        final dark = provider.isDarkMode;

        return Theme(
          data: dark ? ThemeData.dark() : ThemeData.light(),
          child: Scaffold(
            backgroundColor: dark ? const Color(0xFF1A1A2E) : AppTheme.surface,
            appBar: _buildAppBar(ctx, provider, dark),
            body: switch (provider.readState) {
              QuranLoadState.loading => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              QuranLoadState.error   => _buildError(provider),
              QuranLoadState.loaded  => _buildReader(provider, dark),
              _                      => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext ctx, QuranProvider provider, bool dark) {
    return AppBar(
      backgroundColor: dark ? const Color(0xFF16213E) : AppTheme.primary,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.surah.nameId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('${widget.surah.ayahCount} ayat · ${widget.surah.revelation}',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
      actions: [
        // Font size
        IconButton(
          icon: const Icon(Icons.text_decrease, size: 20),
          onPressed: provider.decreaseFontSize,
        ),
        IconButton(
          icon: const Icon(Icons.text_increase, size: 20),
          onPressed: provider.increaseFontSize,
        ),
        // Toggle terjemahan
        IconButton(
          icon: Icon(provider.showTranslation ? Icons.translate : Icons.translate_outlined, size: 20),
          onPressed: provider.toggleTranslation,
          tooltip: provider.showTranslation ? 'Sembunyikan terjemahan' : 'Tampilkan terjemahan',
        ),
        // Dark mode
        IconButton(
          icon: Icon(dark ? Icons.light_mode : Icons.dark_mode, size: 20),
          onPressed: provider.toggleDarkMode,
        ),
      ],
    );
  }

  Widget _buildReader(QuranProvider provider, bool dark) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: provider.ayahs.length + 1, // +1 untuk header bismillah
      itemBuilder: (ctx, index) {
        if (index == 0) return _buildBismillah(dark);
        final ayah = provider.ayahs[index - 1];
        _ayahKeys[ayah.ayahNumber] = GlobalKey();
        return _AyahCard(
          key: _ayahKeys[ayah.ayahNumber],
          ayah: ayah,
          surahName: widget.surah.nameId,
          provider: provider,
          dark: dark,
          onLastRead: () {
            provider.markLastRead(ayah);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Terakhir dibaca: ${widget.surah.nameId} : ${ayah.ayahNumber}'),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBismillah(bool dark) {
    // Surah At-Taubah (9) tidak diawali Bismillah
    if (widget.surah.number == 9) return const SizedBox(height: 8);
    // Surah Al-Fatihah bismillah sudah ada di ayat pertama
    if (widget.surah.number == 1) return const SizedBox(height: 8);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? Colors.white12 : AppTheme.divider, width: 0.5),
      ),
      child: const Center(
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'serif',
            color: AppTheme.primary,
            height: 2,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildError(QuranProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(provider.readError ?? 'Gagal memuat surah'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => provider.openSurah(widget.surah),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

// ── AyahCard ─────────────────────────────────────────────────────────────────

class _AyahCard extends StatefulWidget {
  final Ayah ayah;
  final String surahName;
  final QuranProvider provider;
  final bool dark;
  final VoidCallback onLastRead;

  const _AyahCard({
    super.key,
    required this.ayah,
    required this.surahName,
    required this.provider,
    required this.dark,
    required this.onLastRead,
  });

  @override
  State<_AyahCard> createState() => _AyahCardState();
}

class _AyahCardState extends State<_AyahCard> {
  bool _showTafsir  = false;
  String? _tafsirText;
  bool _loadingTafsir = false;

  Future<void> _loadTafsir() async {
    if (_tafsirText != null) {
      setState(() => _showTafsir = !_showTafsir);
      return;
    }
    setState(() { _showTafsir = true; _loadingTafsir = true; });
    final text = await widget.provider.getTafsir(
      widget.ayah.surahNumber, widget.ayah.ayahNumber,
    );
    if (mounted) setState(() { _tafsirText = text; _loadingTafsir = false; });
  }

  @override
  Widget build(BuildContext context) {
    final dark      = widget.dark;
    final ayah      = widget.ayah;
    final provider  = widget.provider;
    final isPlaying = provider.playingKey == ayah.globalKey && provider.isPlaying;
    final isBookmarked = provider.isBookmarked(ayah.surahNumber, ayah.ayahNumber);

    final cardColor    = dark ? const Color(0xFF16213E) : Colors.white;
    final borderColor  = dark ? Colors.white12 : AppTheme.divider;
    final textColor    = dark ? Colors.white : AppTheme.textPrimary;
    final subColor     = dark ? Colors.white60 : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: isPlaying ? AppTheme.primary.withOpacity(0.06) : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? AppTheme.primary.withOpacity(0.4) : borderColor,
          width: isPlaying ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Header: nomor ayat + tombol aksi ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 4),
            child: Row(
              children: [
                // Nomor ayat
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text('${ayah.ayahNumber}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ),
                ),
                const Spacer(),
                // Play audio
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle_outline,
                    color: isPlaying ? AppTheme.primary : subColor,
                    size: 26,
                  ),
                  onPressed: () => provider.playAudio(ayah),
                  tooltip: isPlaying ? 'Pause' : 'Putar murottal',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // Bookmark
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? AppTheme.accent : subColor,
                    size: 22,
                  ),
                  onPressed: () => provider.toggleBookmark(ayah),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // Tandai terakhir dibaca
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: subColor, size: 20),
                  onSelected: (v) {
                    if (v == 'last_read') widget.onLastRead();
                    if (v == 'copy') _copyAyah();
                    if (v == 'tafsir') _loadTafsir();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'last_read', child: Row(children: [Icon(Icons.bookmark_added_outlined, size: 18), SizedBox(width: 8), Text('Tandai terakhir dibaca')])),
                    const PopupMenuItem(value: 'tafsir',    child: Row(children: [Icon(Icons.menu_book_outlined, size: 18),       SizedBox(width: 8), Text('Lihat tafsir')])),
                    const PopupMenuItem(value: 'copy',      child: Row(children: [Icon(Icons.copy_outlined, size: 18),             SizedBox(width: 8), Text('Salin ayat')])),
                  ],
                ),
              ],
            ),
          ),

          // ── Teks Arab ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              ayah.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: widget.provider.arabicFontSize,
                fontFamily: 'serif',
                color: textColor,
                height: 2.2,
              ),
            ),
          ),

          // ── Terjemahan ────────────────────────────────────────────────────
          if (widget.provider.showTranslation)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                '${ayah.ayahNumber}. ${ayah.translation}',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  color: subColor,
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // ── Tafsir (collapsible) ──────────────────────────────────────────
          if (_showTafsir) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _loadingTafsir
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)))
                  : _tafsirText != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.menu_book, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text('Tafsir Kemenag RI', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _showTafsir = false),
                                child: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text(_tafsirText!, style: TextStyle(fontSize: 13, color: subColor, height: 1.7)),
                          ],
                        )
                      : Text('Tafsir tidak tersedia untuk ayat ini.',
                            style: TextStyle(fontSize: 13, color: subColor, fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }

  void _copyAyah() {
    final text = '${widget.ayah.arabic}\n\n${widget.ayah.translation}\n(QS. ${widget.surahName}: ${widget.ayah.ayahNumber})';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayat disalin'), backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)),
    );
  }
}
