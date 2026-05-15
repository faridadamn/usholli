import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/komunitas_provider.dart';
import '../../models/komunitas_models.dart';
import '../../theme/app_theme.dart';

class PilihMasjidScreen extends StatefulWidget {
  final AuthProvider auth;

  const PilihMasjidScreen({
    super.key,
    required this.auth,
  });

  @override
  State<PilihMasjidScreen> createState() => _PilihMasjidScreenState();
}

class _PilihMasjidScreenState extends State<PilihMasjidScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Cari Masjid'),
      ),
      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari nama masjid atau kota...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.divider, width: 0.5),
                ),
              ),
              onChanged: (val) {
                context.read<KomunitasProvider>().cariMasjid(val);
              },
            ),
          ),

          // 📋 Result
          Expanded(
            child: Consumer<KomunitasProvider>(
              builder: (ctx, komunitas, _) {
                // kosong
                if (_searchCtrl.text.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔍', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                          'Ketik nama masjid atau kota',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                // loading
                if (komunitas.masjidState == KomunitasLoadState.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                // tidak ada hasil
                if (komunitas.masjidList.isEmpty) {
                  return const Center(
                    child: Text(
                      'Masjid tidak ditemukan',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                // list
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: komunitas.masjidList.length,
                  itemBuilder: (_, i) {
                    final m = komunitas.masjidList[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('🕌', style: TextStyle(fontSize: 24)),
                          ),
                        ),

                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.nama,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (m.terverifikasi)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified,
                                    size: 14, color: AppTheme.primary),
                              ),
                          ],
                        ),

                        subtitle: Text(
                          m.lokasi,
                          style: const TextStyle(fontSize: 12),
                        ),

                        trailing: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            minimumSize: const Size(60, 34),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            await widget.auth.setMasjidAktif(m.id);

                            await ctx
                                .read<KomunitasProvider>()
                                .loadMasjidSaya(widget.auth.user!.masjidIds);

                            if (!ctx.mounted) return;

                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('${m.nama} ditambahkan!'),
                                backgroundColor: AppTheme.primary,
                              ),
                            );

                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Ikuti',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}