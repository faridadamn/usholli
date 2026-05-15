import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/donasi_provider.dart';
import '../../models/donasi_models.dart';
import '../../theme/app_theme.dart';
import 'donasi_form_sheet.dart';
import 'laporan_screen.dart';

class DonasiScreen extends StatefulWidget {
  const DonasiScreen({super.key});

  @override
  State<DonasiScreen> createState() => _DonasiScreenState();
}

class _DonasiScreenState extends State<DonasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonasiProvider>().loadPrograms();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Consumer<DonasiProvider>(
        builder: (ctx, provider, _) => CustomScrollView(
          slivers: [
            _buildAppBar(ctx),
            SliverToBoxAdapter(child: _buildHeroCard(ctx, provider)),
            SliverToBoxAdapter(
              child: TabBar(
                controller: _tabs,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                tabs: const [Tab(text: 'Program Donasi'), Tab(text: 'Donasi Terbaru')],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ProgramTab(provider: provider),
                  _FeedTab(provider: provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext ctx) => SliverAppBar(
    pinned: true,
    backgroundColor: AppTheme.primary,
    foregroundColor: Colors.white,
    title: const Text('Donasi & Infaq', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    actions: [
      IconButton(
        icon: const Icon(Icons.bar_chart_outlined),
        tooltip: 'Laporan keuangan',
        onPressed: () {
          ctx.read<DonasiProvider>().loadLaporan();
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LaporanScreen()));
        },
      ),
    ],
  );

  Widget _buildHeroCard(BuildContext ctx, DonasiProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Infaq / Sedekah', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          const Text(
            '"Perumpamaan orang yang menginfakkan hartanya di jalan Allah\nseperti sebutir biji yang menumbuhkan tujuh tangkai."',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 4),
          const Text('(QS. Al-Baqarah: 261)', style: TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _bukaForm(ctx, provider, null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('💚', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text('Donasi Sekarang', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _bukaForm(BuildContext ctx, DonasiProvider provider, DonasiProgram? program) {
    provider.setProgram(program);
    provider.resetPayment();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DonasiFormSheet(),
    );
  }
}

// ── Tab: Program Donasi ───────────────────────────────────────────────────────

class _ProgramTab extends StatelessWidget {
  final DonasiProvider provider;
  const _ProgramTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.programState == DonasiLoadState.loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (provider.programs.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🕌', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Belum ada program donasi', style: TextStyle(color: AppTheme.textSecondary)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: provider.programs.length,
      itemBuilder: (ctx, i) => _ProgramCard(
        program: provider.programs[i],
        onDonasi: () {
          provider.setProgram(provider.programs[i]);
          provider.resetPayment();
          showModalBottomSheet(
            context: ctx,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const DonasiFormSheet(),
          );
        },
      ),
    );
  }
}

// ── Tab: Donasi Terbaru ───────────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  final DonasiProvider provider;
  const _FeedTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final feed = provider.feed;
    if (feed.isEmpty) {
      return const Center(
        child: Text('Belum ada donasi terbaru', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: feed.length,
      itemBuilder: (_, i) => _FeedTile(tx: feed[i]),
    );
  }
}

// ── Program card ──────────────────────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  final DonasiProgram program;
  final VoidCallback onDonasi;
  const _ProgramCard({required this.program, required this.onDonasi});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(program.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(program.judul, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(program.deskripsi, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress bar
          if (program.targetNominal != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(program.terkumpulStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                Text('dari ${program.targetStr}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: program.persentase / 100,
                backgroundColor: AppTheme.divider,
                color: AppTheme.primary,
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 4),
            Text('${program.persentase.toStringAsFixed(0)}% terkumpul',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ] else ...[
            Row(children: [
              const Icon(Icons.volunteer_activism, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text('Terkumpul: ${program.terkumpulStr}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ]),
          ],

          if (program.deadline != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.timer_outlined, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('Sampai ${_formatTgl(program.deadline!)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDonasi,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('💚 Donasi untuk program ini'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTgl(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${d.day} ${m[d.month-1]} ${d.year}';
  }
}

// ── Feed tile ─────────────────────────────────────────────────────────────────

class _FeedTile extends StatelessWidget {
  final DonasiTransaksi tx;
  const _FeedTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              (tx.donaturNama ?? 'H')[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.donaturNama ?? 'Hamba Allah',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (tx.pesanDoa != null && tx.pesanDoa!.isNotEmpty)
                  Text('"${tx.pesanDoa}"',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tx.nominalStr, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              Text(_waktu(tx.createdAt),
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _waktu(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24)   return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
  }
}
