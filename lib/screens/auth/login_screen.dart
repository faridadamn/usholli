import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _hpCtrl  = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();

  @override
  void dispose() {
    _hpCtrl.dispose();
    _otpCtrl.dispose();
    _namaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) => Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: switch (auth.state) {
            AuthState.otpSent => _buildOtpStep(ctx, auth),
            _                 => _buildHpStep(ctx, auth),
          },
        ),
      ),
    );
  }

  // ── Step 1: Input nomor HP ────────────────────────────────────────────────

  Widget _buildHpStep(BuildContext ctx, AuthProvider auth) {
    final loading = auth.state == AuthState.loading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text('🕌', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          const Text('Masuk ke Usholli', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Masukkan nomor HP kamu.\nKode verifikasi akan dikirim via SMS.',
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6)),
          const SizedBox(height: 36),

          const Text('Nomor HP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _hpCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
            autofocus: true,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '08xx-xxxx-xxxx',
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Text('🇮🇩 +62', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.divider, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
            onSubmitted: (_) => _kirimOtp(ctx, auth),
          ),

          if (auth.error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(msg: auth.error!),
          ],

          const SizedBox(height: 24),

          FilledButton(
            onPressed: loading ? null : () => _kirimOtp(ctx, auth),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Kirim Kode OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),

          const SizedBox(height: 20),
          const Center(
            child: Text('Dengan masuk, kamu menyetujui\nSyarat & Ketentuan Usholli.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.6)),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Input OTP + nama (jika baru) ─────────────────────────────────

  Widget _buildOtpStep(BuildContext ctx, AuthProvider auth) {
    final loading = auth.state == AuthState.loading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text('📱', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          const Text('Masukkan Kode OTP', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Kode 6 digit telah dikirim ke\n${_hpCtrl.text}',
            style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 36),

          const Text('Kode OTP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 12),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.divider, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          ),

          const SizedBox(height: 20),

          const Text('Nama kamu (opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _namaCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Contoh: Ahmad Fauzi',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.divider, width: 0.5)),
            ),
          ),

          if (auth.error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(msg: auth.error!),
          ],

          const SizedBox(height: 24),

          FilledButton(
            onPressed: loading ? null : () => _verifyOtp(ctx, auth),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Verifikasi & Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: auth.kembaliKeInput,
              child: const Text('Ganti nomor HP', style: TextStyle(color: AppTheme.primary)),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => _kirimOtp(ctx, auth), // kirim ulang
              child: const Text('Kirim ulang OTP', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  void _kirimOtp(BuildContext ctx, AuthProvider auth) {
    final hp = _hpCtrl.text.trim();
    if (hp.length < 9) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor HP yang valid'), backgroundColor: Colors.red),
      );
      return;
    }
    auth.kirimOtp(hp);
  }

  void _verifyOtp(BuildContext ctx, AuthProvider auth) {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Kode OTP harus 6 digit'), backgroundColor: Colors.red),
      );
      return;
    }
    auth.verifyOtp(otp, nama: _namaCtrl.text.trim().isNotEmpty ? _namaCtrl.text.trim() : null)
        .then((_) {
      if (auth.state == AuthState.authenticated) {
        widget.onLoginSuccess?.call();
      }
    });
  }
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200)),
    child: Row(children: [
      Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
    ]),
  );
}
