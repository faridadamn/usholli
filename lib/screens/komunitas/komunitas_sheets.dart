import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/komunitas_provider.dart';
import '../../models/komunitas_models.dart';
import '../../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TITIP DOA SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class TitipDoaSheet extends StatefulWidget {
  final AuthProvider auth;
  const TitipDoaSheet({super.key, required this.auth});

  @override
  State<TitipDoaSheet> createState() => _TitipDoaSheetState();
}

class _TitipDoaSheetState extends State<TitipDoaSheet> {
  final _ctrl   = TextEditingController();
  bool _anonim  = false;
  bool _loading = false;
  bool _sent    = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: _sent ? _buildSukses() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 16),
      const Text('🤲 Titip Doa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Doamu akan dibacakan pengurus saat kajian atau Jumat.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      const SizedBox(height: 16),
      TextField(
        controller: _ctrl,
        maxLines: 5,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Tulis doamu di sini...\n\nContoh: Ya Allah, mohon kesembuhan untuk ibuku yang sedang sakit...',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          filled: true, fillColor: AppTheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider, width: 0.5)),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kirim Anonim', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Text('Namamu tidak akan ditampilkan', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ])),
        Switch.adaptive(value: _anonim, activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _anonim = v)),
      ]),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _loading ? null : _kirim,
        style: FilledButton.styleFrom(backgroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Kirim Doa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    ],
  );

  Widget _buildSukses() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 20),
      const Text('🤲', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 12),
      const Text('Doa Terkirim', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary)),
      const SizedBox(height: 8),
      const Text('Aamiin. Semoga doamu dikabulkan Allah SWT. 🌙',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        style: FilledButton.styleFrom(backgroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Tutup'),
      ),
    ],
  );

  Future<void> _kirim() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final komunitas = context.read<KomunitasProvider>();
    final auth = widget.auth;
    await komunitas.kirimDoa(
      masjidId: auth.masjidAktifId,
      userId: auth.user!.id,
      userName: auth.user!.nama,
      isiDoa: _ctrl.text.trim(),
      anonim: _anonim,
      token: auth.token!,
    );
    setState(() { _loading = false; _sent = true; });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BUAT UNDANGAN SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class BuatUndanganSheet extends StatefulWidget {
  final AuthProvider auth;
  const BuatUndanganSheet({super.key, required this.auth});

  @override
  State<BuatUndanganSheet> createState() => _BuatUndanganSheetState();
}

class _BuatUndanganSheetState extends State<BuatUndanganSheet> {
  final _judulCtrl   = TextEditingController();
  final _alamatCtrl  = TextEditingController();
  final _descCtrl    = TextEditingController();
  String _jenisId    = 'tahlilan';
  DateTime _waktu    = DateTime.now().add(const Duration(days: 1));
  bool _loading      = false;
  Undangan? _result;

  @override
  void dispose() {
    _judulCtrl.dispose(); _alamatCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _result != null ? _buildHasil() : _buildForm(ctrl),
        ),
      ),
    );
  }

  Widget _buildForm(ScrollController ctrl) => ListView(
    controller: ctrl,
    padding: const EdgeInsets.all(24),
    children: [
      Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 16),
      const Text('📅 Buat Undangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),

      // Jenis acara
      const Text('Jenis Acara', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      SizedBox(height: 44, child: ListView(
        scrollDirection: Axis.horizontal,
        children: JenisAcara.all.map((j) => GestureDetector(
          onTap: () => setState(() => _jenisId = j.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _jenisId == j.id ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _jenisId == j.id ? AppTheme.primary : AppTheme.divider, width: 0.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(j.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(j.nama, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: _jenisId == j.id ? Colors.white : AppTheme.textSecondary)),
            ]),
          ),
        )).toList(),
      )),
      const SizedBox(height: 16),

      _field(_judulCtrl, 'Judul Acara *', 'Tahlilan 40 hari Bapak Ahmad'),
      const SizedBox(height: 12),
      _field(_alamatCtrl, 'Alamat *', 'Jl. Mawar No. 5, RT 03/04, Kel. Sukamaju'),
      const SizedBox(height: 12),
      _field(_descCtrl, 'Keterangan (opsional)', 'Mohon kehadirannya...', maxLines: 3),
      const SizedBox(height: 16),

      // Waktu
      const Text('Waktu Acara', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pilihWaktu,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider, width: 0.5),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text(_formatWaktu(_waktu), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ]),
        ),
      ),

      const SizedBox(height: 24),
      FilledButton(
        onPressed: _loading ? null : _buat,
        style: FilledButton.styleFrom(backgroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Buat Undangan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    ],
  );

  Widget _buildHasil() {
    final u = _result!;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(u.jenis.emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('Undangan Dibuat! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        const SizedBox(height: 8),
        Text(u.judul, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        Text(u.waktuStr, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),

        // Kode undangan
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
          child: Column(children: [
            const Text('Kode Undangan', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(u.kodeUndangan, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 8, color: AppTheme.primary)),
            const SizedBox(height: 8),
            const Text('Bagikan kode atau link ke tamu undangan', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ),
        const SizedBox(height: 16),

        // Tombol share
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16, color: AppTheme.primary),
            label: const Text('Salin Kode', style: TextStyle(color: AppTheme.primary)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 46)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: u.kodeUndangan));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode disalin!'), backgroundColor: AppTheme.primary));
            },
          )),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.icon(
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Bagikan Link'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 46)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: u.shareLink));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link disalin!'), backgroundColor: AppTheme.primary));
            },
          )),
        ]),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Selesai')),
      ]),
    );
  }

  Future<void> _pilihWaktu() async {
    final date = await showDatePicker(context: context, initialDate: _waktu,
        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_waktu));
    if (time == null) return;
    setState(() => _waktu = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _buat() async {
    if (_judulCtrl.text.trim().isEmpty || _alamatCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final komunitas = context.read<KomunitasProvider>();
    final auth = widget.auth;
    final u = await komunitas.buatUndangan(
      pembuatId:   auth.user!.id,
      pembuatNama: auth.user!.nama,
      token:       auth.token!,
      masjidId:    auth.masjidAktifId.isNotEmpty ? auth.masjidAktifId : null,
      data: {
        'jenis_id':    _jenisId,
        'judul':       _judulCtrl.text.trim(),
        'alamat':      _alamatCtrl.text.trim(),
        'deskripsi':   _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        'waktu_mulai': _waktu.toIso8601String(),
      },
    );
    setState(() { _loading = false; _result = u; });
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) =>
      TextField(controller: ctrl, maxLines: maxLines,
        decoration: InputDecoration(labelText: label, hintText: hint,
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider, width: 0.5)),
        ),
      );

  String _formatWaktu(DateTime d) {
    const days   = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final jam    = '${d.hour.toString().padLeft(2,'0')}.${d.minute.toString().padLeft(2,'0')}';
    return '${days[d.weekday-1]}, ${d.day} ${months[d.month-1]} ${d.year} · $jam WIB';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UNDANGAN DETAIL SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class UndanganDetailScreen extends StatelessWidget {
  final Undangan undangan;
  final AuthProvider auth;
  const UndanganDetailScreen({super.key, required this.undangan, required this.auth});

  @override
  Widget build(BuildContext context) {
    final isBuat    = undangan.pembuatId == auth.user?.id;
    final sudahJoin = undangan.pesertaIds.contains(auth.user?.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        title: Text(undangan.jenis.nama),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Clipboard.setData(ClipboardData(text: undangan.shareLink)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Text(undangan.jenis.emoji, style: const TextStyle(fontSize: 72))),
          const SizedBox(height: 16),
          Center(child: Text(undangan.judul, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
          const SizedBox(height: 20),

          _InfoRow(icon: Icons.person_outline, label: 'Oleh', value: undangan.pembuatNama),
          _InfoRow(icon: Icons.calendar_today, label: 'Waktu', value: undangan.waktuStr),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Tempat', value: undangan.alamat),
          _InfoRow(icon: Icons.people_outline, label: 'Peserta', value: '${undangan.jumlahPeserta} orang'),
          if (undangan.deskripsi != null)
            _InfoRow(icon: Icons.notes, label: 'Keterangan', value: undangan.deskripsi!),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider, width: 0.5)),
            child: Column(children: [
              const Text('Kode Undangan', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text(undangan.kodeUndangan, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 8, color: AppTheme.primary)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: undangan.shareLink)),
                child: Text(undangan.shareLink, style: const TextStyle(fontSize: 11, color: AppTheme.primary, decoration: TextDecoration.underline)),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          if (!isBuat && !sudahJoin && auth.isLoggedIn)
            Consumer<KomunitasProvider>(
              builder: (ctx, komunitas, _) => FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Saya Hadir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => komunitas.bergabung(undangan.id, auth.user!.id, undangan.pesertaIds, auth.token!),
              ),
            ),
          if (sudahJoin)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Kamu sudah konfirmasi hadir 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: AppTheme.primary),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 14, height: 1.4)),
      ])),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PILIH MASJID SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class PilihMasjidScreen extends StatefulWidget {
  final AuthProvider auth;
  const PilihMasjidScreen({super.key, required this.auth});

  @override
  State<PilihMasjidScreen> createState() => _PilihMasjidScreenState();
}

class _PilihMasjidScreenState extends State<PilihMasjidScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        title: const Text('Cari Masjid'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Cari nama masjid atau kota...',
              prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider, width: 0.5)),
            ),
            onChanged: (v) => context.read<KomunitasProvider>().cariMasjid(v),
          ),
        ),
        Expanded(
          child: Consumer<KomunitasProvider>(
            builder: (ctx, komunitas, _) {
              if (_ctrl.text.isEmpty) {
                return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('🔍', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Ketik nama masjid atau kota', style: TextStyle(color: AppTheme.textSecondary)),
                ]));
              }
              if (komunitas.masjidState == KomunitasLoadState.loading) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }
              if (komunitas.masjidList.isEmpty) {
                return const Center(child: Text('Masjid tidak ditemukan', style: TextStyle(color: AppTheme.textSecondary)));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: komunitas.masjidList.length,
                itemBuilder: (_, i) {
                  final m = komunitas.masjidList[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider, width: 0.5)),
                    child: ListTile(
                      leading: Container(width: 44, height: 44,
                          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                          child: const Center(child: Text('🕌', style: TextStyle(fontSize: 24)))),
                      title: Row(children: [
                        Flexible(child: Text(m.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                        if (m.terverifikasi) const Padding(padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified, size: 14, color: AppTheme.primary)),
                      ]),
                      subtitle: Text(m.lokasi, style: const TextStyle(fontSize: 12)),
                      trailing: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primary,
                            minimumSize: const Size(60, 34), padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () async {
                          await widget.auth.setMasjidAktif(m.id);
                          await ctx.read<KomunitasProvider>().loadMasjidSaya(widget.auth.user!.masjidIds);
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('${m.nama} ditambahkan!'), backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ));
                          Navigator.pop(ctx);
                        },
                        child: const Text('Ikuti', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
