import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notif = NotificationService();

  final List<Map<String, dynamic>> _prayers = [
    {'name': 'Subuh',   'icon': '🌙', 'desc': 'Sebelum matahari terbit'},
    {'name': 'Dzuhur',  'icon': '☀️',  'desc': 'Tengah hari'},
    {'name': 'Ashar',   'icon': '🌤️', 'desc': 'Sore hari'},
    {'name': 'Maghrib', 'icon': '🌇', 'desc': 'Saat matahari terbenam'},
    {'name': 'Isya',    'icon': '✨', 'desc': 'Malam hari'},
  ];

  final Map<String, bool> _states = {};

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    for (final p in _prayers) {
      final enabled = await _notif.isPrayerEnabled(p['name'] as String);
      setState(() => _states[p['name'] as String] = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Adzan'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Notifikasi akan berbunyi dengan suara adzan saat waktu salat masuk.',
                    style: TextStyle(fontSize: 13, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Aktifkan per waktu salat',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ),

          // Toggle cards
          ..._prayers.map((p) {
            final name = p['name'] as String;
            final enabled = _states[name] ?? true;
            return _buildToggleCard(name, p['icon'] as String, p['desc'] as String, enabled);
          }),

          const SizedBox(height: 24),

          // Master toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _setAll(false),
                icon: const Icon(Icons.notifications_off_outlined, size: 16),
                label: const Text('Nonaktifkan semua'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
              FilledButton.icon(
                onPressed: () => _setAll(true),
                icon: const Icon(Icons.notifications_active, size: 16),
                label: const Text('Aktifkan semua'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard(String name, String icon, String desc, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeColor: AppTheme.primary,
            onChanged: (v) async {
              setState(() => _states[name] = v);
              await _notif.togglePrayer(name, v);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setAll(bool value) async {
    for (final p in _prayers) {
      final name = p['name'] as String;
      setState(() => _states[name] = value);
      await _notif.togglePrayer(name, value);
    }
  }
}
