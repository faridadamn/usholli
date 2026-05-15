import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class CityPickerSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onCitySelected;
  final VoidCallback onUseGps;

  const CityPickerSheet({
    super.key,
    required this.onCitySelected,
    required this.onUseGps,
  });

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  String _search = '';

  List<Map<String, dynamic>> get _filtered => LocationService.indonesiaCities
      .where((c) => (c['name'] as String)
          .toLowerCase()
          .contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Icon(Icons.location_city, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Pilih Kota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // GPS button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: widget.onUseGps,
              icon: const Icon(Icons.gps_fixed, color: AppTheme.primary),
              label: const Text('Gunakan lokasi GPS saya', style: TextStyle(color: AppTheme.primary)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('atau pilih kota', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Cari kota...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // List kota
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final city = _filtered[i];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppTheme.textSecondary),
                  title: Text(city['name'] as String),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  onTap: () => widget.onCitySelected(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
