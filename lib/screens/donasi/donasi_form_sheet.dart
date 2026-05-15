import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/donasi_provider.dart';
import '../../models/donasi_models.dart';
import '../../theme/app_theme.dart';

class DonasiFormSheet extends StatefulWidget {
  const DonasiFormSheet({super.key});

  @override
  State<DonasiFormSheet> createState() => _DonasiFormSheetState();
}

class _DonasiFormSheetState extends State<DonasiFormSheet> {
  final _nominalCtrl  = TextEditingController();
  final _namaCtrl     = TextEditingController();
  final _doaCtrl      = TextEditingController();
  bool _anonim        = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DonasiProvider>();
    _nominalCtrl.text = provider.nominal.toInt().toString();
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _namaCtrl.dispose();
    _doaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DonasiProvider>(
      builder: (ctx, provider, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: switch (provider.paymentState) {
              PaymentState.success         => _buildSuccess(ctx, provider),
              PaymentState.failed          => _buildFailed(ctx, provider),
              PaymentState.waitingPayment  => _buildWaiting(ctx, provider),
              PaymentState.processing      => _buildProcessing(),
              _                            => _buildForm(ctx, provider, controller),
            },
          ),
        );
      },
    );
  }

  // ── Form utama ────────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext ctx, DonasiProvider provider, ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Handle
        Center(child: Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
        )),

        // Header: program terpilih
        if (provider.selectedProgram != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text(provider.selectedProgram!.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Donasi untuk program', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      Text(provider.selectedProgram!.judul,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => provider.setProgram(null),
                  child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

        const Text('Jumlah Donasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),

        // Input nominal
        TextField(
          controller: _nominalCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          ),
          onChanged: (v) => provider.setNominal(double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 10),

        // Nominal cepat
        Wrap(
          spacing: 8, runSpacing: 8,
          children: nominalCepat.map((n) => GestureDetector(
            onTap: () {
              _nominalCtrl.text = n.toInt().toString();
              provider.setNominal(n);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: provider.nominal == n ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: provider.nominal == n ? AppTheme.primary : AppTheme.divider,
                  width: provider.nominal == n ? 0 : 0.5,
                ),
              ),
              child: Text(
                _formatNominalCepat(n),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: provider.nominal == n ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          )).toList(),
        ),

        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 20),

        // Metode pembayaran
        const Text('Metode Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            _MetodePill(label: 'QRIS', emoji: '📱', value: 'qris', selected: provider.metode == 'qris', onTap: () => provider.setMetode('qris')),
            const SizedBox(width: 8),
            _MetodePill(label: 'Transfer', emoji: '🏦', value: 'transfer', selected: provider.metode == 'transfer', onTap: () => provider.setMetode('transfer')),
            const SizedBox(width: 8),
            _MetodePill(label: 'E-Wallet', emoji: '💳', value: 'ewallet', selected: provider.metode == 'ewallet', onTap: () => provider.setMetode('ewallet')),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 20),

        // Anonim toggle
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Donasi Anonim', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Nama tidak ditampilkan di feed', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Switch.adaptive(
              value: _anonim,
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _anonim = v),
            ),
          ],
        ),

        if (!_anonim) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _namaCtrl,
            decoration: _inputDeco('Nama Donatur', 'Nama kamu (akan tampil di feed)'),
            onChanged: provider.setDonaturNama,
          ),
        ],

        const SizedBox(height: 16),

        // Pesan doa
        TextField(
          controller: _doaCtrl,
          maxLines: 3,
          decoration: _inputDeco('Pesan / Doa (opsional)', 'Titip doa untuk masjid atau jamaah...'),
          onChanged: provider.setPesanDoa,
        ),

        if (provider.paymentError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(provider.paymentError!, style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
            ]),
          ),
        ],

        const SizedBox(height: 24),

        FilledButton(
          onPressed: () => _prosesdonasi(ctx, provider),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            '💚 Donasi ${formatRupiahFull(provider.nominal)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),

        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 13, color: AppTheme.textSecondary),
            SizedBox(width: 4),
            Text('Aman · Diproses oleh Midtrans', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  // ── State: Processing ─────────────────────────────────────────────────────

  Widget _buildProcessing() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: AppTheme.primary),
      SizedBox(height: 16),
      Text('Memproses donasi...', style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
    ]),
  );

  // ── State: Waiting payment (redirect ke Midtrans) ─────────────────────────

  Widget _buildWaiting(BuildContext ctx, DonasiProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('⏳', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('Menunggu Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Selesaikan pembayaran ${formatRupiahFull(provider.nominal)} melalui halaman yang sudah terbuka.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 24),
        if (provider.lastTx?.paymentUrl != null)
          FilledButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Buka Halaman Pembayaran'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => launchUrl(Uri.parse(provider.lastTx!.paymentUrl!),
                mode: LaunchMode.externalApplication),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.check_circle_outline, color: AppTheme.primary),
          label: const Text('Saya sudah bayar', style: TextStyle(color: AppTheme.primary)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: AppTheme.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: provider.konfirmasiPembayaran,
        ),
      ]),
    );
  }

  // ── State: Success ────────────────────────────────────────────────────────

  Widget _buildSuccess(BuildContext ctx, DonasiProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🎉', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        const Text('Jazakallahu Khairan!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        const SizedBox(height: 8),
        Text(
          'Donasi ${formatRupiahFull(provider.nominal)} berhasil.\nSemoga menjadi amal jariyah yang mengalir terus. 🤲',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.7),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () {
            provider.resetPayment();
            Navigator.pop(ctx);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Kembali', style: TextStyle(fontSize: 15)),
        ),
      ]),
    );
  }

  // ── State: Failed ─────────────────────────────────────────────────────────

  Widget _buildFailed(BuildContext ctx, DonasiProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('😔', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('Pembayaran Gagal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Donasi belum berhasil. Silakan coba lagi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: provider.resetPayment,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Coba Lagi'),
        ),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _prosesdonasi(BuildContext ctx, DonasiProvider provider) async {
    if (_anonim) provider.setDonaturNama('');
    final url = await provider.prosesdonasi();
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  InputDecoration _inputDeco(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: AppTheme.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider, width: 0.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
  );

  String _formatNominalCepat(double n) {
    if (n >= 1000000) return 'Rp ${(n/1000000).toStringAsFixed(0)} Jt';
    if (n >= 1000)    return 'Rp ${(n/1000).toStringAsFixed(0)} Rb';
    return 'Rp ${n.toInt()}';
  }
}

// ── Metode pill ───────────────────────────────────────────────────────────────

class _MetodePill extends StatelessWidget {
  final String label, emoji, value;
  final bool selected;
  final VoidCallback onTap;

  const _MetodePill({required this.label, required this.emoji, required this.value,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
          )),
        ]),
      ),
    );
  }
}
