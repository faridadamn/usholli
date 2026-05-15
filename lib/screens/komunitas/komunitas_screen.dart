import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/komunitas_provider.dart';
import '../../models/komunitas_models.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'titip_doa_sheet.dart';
import 'buat_undangan_sheet.dart';
import 'undangan_detail_screen.dart';
import 'pilih_masjid_screen.dart';

class KomunitasScreen extends StatefulWidget {
  const KomunitasScreen({super.key});

  @override
  State<KomunitasScreen> createState() => _KomunitasScreenState();
}

class _KomunitasScreenState extends State<KomunitasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth     = context.read<AuthProvider>();
    final komunitas = context.read<KomunitasProvider>();
    if (!auth.isLoggedIn) return;
    komunitas.loadDoa(auth.user!.id, auth.masjidAktifId, auth.token!);
    komunitas.loadUndangan(auth.user!.id, auth.token!);
    if (auth.user!.masjidIds.isNotEmpty) {
      komunitas.loadMasjidSaya(auth.user!.masjidIds);
    }
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        if (!auth.isLoggedIn) return _buildGuestWall(ctx, auth);

        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Komunitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text('Halo, ${auth.namaDisplay} 👋',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '🤲 Titip Doa'),
                Tab(text: '📅 Undangan'),
                Tab(text: '🕌 Masjid Saya'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _TitipDoaTab(auth: auth),
              _UndanganTab(auth: auth),
              _MasjidSayaTab(auth: auth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestWall(BuildContext ctx, AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Komunitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤲', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              const Text('Masuk untuk bergabung', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text(
                'Titip doa, buat undangan tahlilan & acara,\nserta ikuti masjid favorit kamu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => LoginScreen(onLoginSuccess: () { Navigator.pop(ctx); _load(); }),
                )),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Masuk dengan Nomor HP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab: Titip Doa ────────────────────────────────────────────────────────────

class _TitipDoaTab extends StatelessWidget {
  final AuthProvider auth;
  const _TitipDoaTab({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Consumer<KomunitasProvider>(
      builder: (ctx, komunitas, _) => Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: const Row(children: [
              Text('🤲', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Titip doa kamu kepada pengurus masjid. Doa akan dibacakan saat kajian atau salat Jumat.',
                style: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
              )),
            ]),
          ),
          // FAB
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Titipkan Doa Baru'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TitipDoaSheet(auth: auth),
              ),
            ),
          ),
          // List doa
          Expanded(
            child: komunitas.doaList.isEmpty
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('🤲', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Belum ada doa yang dititipkan', style: TextStyle(color: AppTheme.textSecondary)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: komunitas.doaList.length,
                    itemBuilder: (_, i) => _DoaTile(doa: komunitas.doaList[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Undangan ─────────────────────────────────────────────────────────────

class _UndanganTab extends StatelessWidget {
  final AuthProvider auth;
  const _UndanganTab({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Consumer<KomunitasProvider>(
      builder: (ctx, komunitas, _) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Undangan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => showModalBottomSheet(
                    context: ctx,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BuatUndanganSheet(auth: auth),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppTheme.primary),
                label: const Text('Join Kode', style: TextStyle(color: AppTheme.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 46),
                ),
                onPressed: () => _joinKode(ctx, komunitas, auth),
              ),
            ]),
          ),
          Expanded(
            child: komunitas.undanganList.isEmpty
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('📅', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Belum ada undangan', style: TextStyle(color: AppTheme.textSecondary)),
                      SizedBox(height: 6),
                      Text('Buat undangan tahlilan, syukuran, aqiqah, dll.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: komunitas.undanganList.length,
                    itemBuilder: (_, i) => _UndanganTile(
                      undangan: komunitas.undanganList[i],
                      userId: auth.user!.id,
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(
                        builder: (_) => UndanganDetailScreen(
                          undangan: komunitas.undanganList[i],
                          auth: auth,
                        ),
                      )),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _joinKode(BuildContext ctx, KomunitasProvider komunitas, AuthProvider auth) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Masukkan Kode Undangan'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: const InputDecoration(hintText: 'XXXXXX', counterText: ''),
          style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              final u = await komunitas.cariByKode(ctrl.text.trim().toUpperCase());
              if (!ctx.mounted) return;
              if (u != null) {
                Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => UndanganDetailScreen(undangan: u, auth: auth),
                ));
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Kode undangan tidak ditemukan'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Masjid Saya ──────────────────────────────────────────────────────────

class _MasjidSayaTab extends StatelessWidget {
  final AuthProvider auth;
  const _MasjidSayaTab({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Consumer<KomunitasProvider>(
      builder: (ctx, komunitas, _) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FilledButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Cari & Ikuti Masjid'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => PilihMasjidScreen(auth: auth),
              )),
            ),
          ),
          Expanded(
            child: komunitas.masjidSaya.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🕌', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      const Text('Belum mengikuti masjid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text('Cari dan ikuti masjid di sekitar kamu', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: komunitas.masjidSaya.length,
                    itemBuilder: (_, i) => _MasjidTile(
                      masjid: komunitas.masjidSaya[i],
                      isAktif: komunitas.masjidSaya[i].id == auth.masjidAktifId,
                      onSetAktif: () => auth.setMasjidAktif(komunitas.masjidSaya[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Tile widgets ──────────────────────────────────────────────────────────────

class _DoaTile extends StatelessWidget {
  final TitipDoa doa;
  const _DoaTile({required this.doa});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(doa.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(doa.statusLabel,
                  style: TextStyle(fontSize: 11, color: _statusColor(doa.status), fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Text(_waktu(doa.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Text(doa.isiDoa, style: const TextStyle(fontSize: 14, height: 1.6)),
          if (doa.status == DoaStatus.dibacakan) ...[
            const SizedBox(height: 6),
            const Row(children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text('Doa sudah dibacakan, Aamiin 🤲', style: TextStyle(fontSize: 12, color: Colors.green)),
            ]),
          ],
        ],
      ),
    );
  }

  Color _statusColor(DoaStatus s) => switch (s) {
    DoaStatus.menunggu   => AppTheme.accent,
    DoaStatus.dibacakan  => Colors.green,
    DoaStatus.ditolak    => Colors.red,
  };

  String _waktu(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
  }
}

class _UndanganTile extends StatelessWidget {
  final Undangan undangan;
  final String userId;
  final VoidCallback onTap;
  const _UndanganTile({required this.undangan, required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBuat = undangan.pembuatId == userId;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isBuat ? AppTheme.primary.withOpacity(0.3) : AppTheme.divider,
            width: isBuat ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(undangan.jenis.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(undangan.judul, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(undangan.waktuStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text(undangan.alamat, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isBuat) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Kamu', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.people_outline, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 3),
                  Text('${undangan.jumlahPeserta}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MasjidTile extends StatelessWidget {
  final Masjid masjid;
  final bool isAktif;
  final VoidCallback onSetAktif;
  const _MasjidTile({required this.masjid, required this.isAktif, required this.onSetAktif});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAktif ? AppTheme.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isAktif ? AppTheme.primary : AppTheme.divider, width: isAktif ? 1.5 : 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('🕌', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(masjid.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                  if (masjid.terverifikasi) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 14, color: AppTheme.primary),
                  ],
                ]),
                Text(masjid.lokasi, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (isAktif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('Aktif', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
            )
          else
            TextButton(
              onPressed: onSetAktif,
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: const Text('Set Aktif', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
