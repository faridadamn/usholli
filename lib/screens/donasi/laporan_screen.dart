import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/donasi_provider.dart';
import '../../models/donasi_models.dart';
import '../../theme/app_theme.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Laporan Keuangan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<DonasiProvider>(
        builder: (ctx, provider, _) {
          if (provider.laporanState == DonasiLoadState.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (provider.laporan.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('📊', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada laporan keuangan',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pengurus masjid belum mengunggah laporan',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.laporan.length,
            itemBuilder: (_, i) =>
                _LaporanCard(laporan: provider.laporan[i]),
          );
        },
      ),
    );
  }
}

// ================= CARD =================

class _LaporanCard extends StatefulWidget {
  final LaporanBulan laporan;
  const _LaporanCard({required this.laporan});

  @override
  State<_LaporanCard> createState() => _LaporanCardState();
}

class _LaporanCardState extends State<_LaporanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.laporan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('📅', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.bulanStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Saldo: ${_fmtRp(l.saldo)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: l.saldo >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _SummaryBox(
                          label: 'Pemasukan',
                          nominal: l.totalPemasukan,
                          color: Colors.green,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryBox(
                          label: 'Pengeluaran',
                          nominal: l.totalPengeluaran,
                          color: Colors.red,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...l.pemasukan
                      .map((e) => _ItemRow(item: e, isIncome: true)),
                  ...l.pengeluaran
                      .map((e) => _ItemRow(item: e, isIncome: false)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtRp(double n) {
    if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)} Jt';
    if (n >= 1000) return 'Rp ${(n / 1000).toStringAsFixed(0)} Rb';
    return 'Rp ${n.toStringAsFixed(0)}';
  }
}

// ================= SUMMARY =================

class _SummaryBox extends StatelessWidget {
  final String label;
  final double nominal;
  final Color color;
  final IconData icon;

  const _SummaryBox({
    required this.label,
    required this.nominal,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label\n${_fmtRp(nominal)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtRp(double n) {
    if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)} Jt';
    if (n >= 1000) return 'Rp ${(n / 1000).toStringAsFixed(0)} Rb';
    return 'Rp ${n.toStringAsFixed(0)}';
  }
}

// ================= ITEM =================

class _ItemRow extends StatelessWidget {
  final ItemLaporan item;
  final bool isIncome;

  const _ItemRow({required this.item, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              item.tglStr,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.keterangan,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            item.nominalStr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}