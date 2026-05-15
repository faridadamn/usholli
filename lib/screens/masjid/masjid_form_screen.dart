import 'package:flutter/material.dart';
import '../../models/komunitas_models.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class MasjidFormScreen extends StatefulWidget {
  final Masjid? initialMasjid;

  const MasjidFormScreen({super.key, this.initialMasjid});

  @override
  State<MasjidFormScreen> createState() => _MasjidFormScreenState();
}

class _MasjidFormScreenState extends State<MasjidFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();
  late final TextEditingController _nama;
  late final TextEditingController _alamat;
  late final TextEditingController _kota;
  late final TextEditingController _provinsi;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _fotoUrl;
  late final TextEditingController _pengumuman;
  late final TextEditingController _jamaahCount;
  late final TextEditingController _adminId;
  bool _terverifikasi = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final masjid = widget.initialMasjid;
    _nama = TextEditingController(text: masjid?.nama ?? '');
    _alamat = TextEditingController(text: masjid?.alamat ?? '');
    _kota = TextEditingController(text: masjid?.kota ?? '');
    _provinsi = TextEditingController(text: masjid?.provinsi ?? '');
    _latitude = TextEditingController(text: _numText(masjid?.latitude));
    _longitude = TextEditingController(text: _numText(masjid?.longitude));
    _fotoUrl = TextEditingController(text: masjid?.fotoUrl ?? '');
    _pengumuman = TextEditingController(text: masjid?.pengumumanSingkat ?? '');
    _jamaahCount = TextEditingController(text: '${masjid?.jamaahCount ?? 0}');
    _adminId = TextEditingController(text: masjid?.adminId ?? '');
    _terverifikasi = masjid?.terverifikasi ?? false;

    if (masjid == null || (masjid.latitude == 0 && masjid.longitude == 0)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _fillCurrentLocation());
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _kota.dispose();
    _provinsi.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _fotoUrl.dispose();
    _pengumuman.dispose();
    _jamaahCount.dispose();
    _adminId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialMasjid != null;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Masjid' : 'Input Masjid Baru'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _SectionCard(
                title: 'Informasi Utama',
                children: [
                  _Field(
                    controller: _nama,
                    label: 'Nama masjid',
                    hint: 'Masjid Agung Al-Azhar',
                    icon: Icons.mosque_outlined,
                    validator: _required,
                  ),
                  _Field(
                    controller: _alamat,
                    label: 'Alamat',
                    hint: 'Jl. Sisingamangaraja No. 1',
                    icon: Icons.location_on_outlined,
                    minLines: 2,
                    validator: _required,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _kota,
                          label: 'Kota',
                          hint: 'Jakarta Selatan',
                          icon: Icons.location_city_outlined,
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Field(
                          controller: _provinsi,
                          label: 'Provinsi',
                          hint: 'DKI Jakarta',
                          icon: Icons.map_outlined,
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Lokasi & Media',
                children: [
                  _LocationButton(
                    loading: _isLocating,
                    onPressed: _fillCurrentLocation,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _latitude,
                          label: 'Latitude',
                          hint: '-6.2352',
                          icon: Icons.my_location_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          validator: _doubleRequired,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Field(
                          controller: _longitude,
                          label: 'Longitude',
                          hint: '106.7995',
                          icon: Icons.explore_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          validator: _doubleRequired,
                        ),
                      ),
                    ],
                  ),
                  _Field(
                    controller: _fotoUrl,
                    label: 'Foto URL',
                    hint: 'https://...',
                    icon: Icons.image_outlined,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Status & Admin',
                children: [
                  _Field(
                    controller: _pengumuman,
                    label: 'Pengumuman singkat',
                    hint: 'Kajian rutin setiap Ahad pagi',
                    icon: Icons.campaign_outlined,
                    minLines: 3,
                  ),
                  _Field(
                    controller: _jamaahCount,
                    label: 'Jumlah jamaah',
                    hint: '1250',
                    icon: Icons.groups_outlined,
                    keyboardType: TextInputType.number,
                    validator: _intRequired,
                  ),
                  _Field(
                    controller: _adminId,
                    label: 'Admin ID',
                    hint: 'UUID admin masjid',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                  SwitchListTile.adaptive(
                    value: _terverifikasi,
                    onChanged: (value) =>
                        setState(() => _terverifikasi = value),
                    activeThumbColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Masjid terverifikasi',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Tampilkan badge verifikasi di detail masjid',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    isEdit ? 'Simpan Perubahan' : 'Simpan Masjid',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final masjid = Masjid(
      id: widget.initialMasjid?.id ??
          'local-${DateTime.now().millisecondsSinceEpoch}',
      nama: _nama.text.trim(),
      alamat: _alamat.text.trim(),
      kota: _kota.text.trim(),
      provinsi: _provinsi.text.trim(),
      latitude: double.parse(_latitude.text.trim()),
      longitude: double.parse(_longitude.text.trim()),
      fotoUrl: _emptyToNull(_fotoUrl.text),
      pengumumanSingkat: _emptyToNull(_pengumuman.text),
      jamaahCount: int.parse(_jamaahCount.text.trim()),
      terverifikasi: _terverifikasi,
      adminId: _adminId.text.trim(),
    );

    Navigator.pop(context, masjid);
  }

  Future<void> _fillCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final location = await _locationService.getGpsLocation();
      if (!mounted) return;
      _latitude.text = location.latitude.toStringAsFixed(7);
      _longitude.text = location.longitude.toStringAsFixed(7);
      if (_kota.text.trim().isEmpty) {
        _kota.text = location.cityName;
      }
      if (_provinsi.text.trim().isEmpty && location.provinceName.isNotEmpty) {
        _provinsi.text = location.provinceName;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat lokasi berhasil diambil'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return null;
  }

  String? _doubleRequired(String? value) {
    final required = _required(value);
    if (required != null) return required;
    if (double.tryParse(value!.trim()) == null) {
      return 'Format angka tidak valid';
    }
    return null;
  }

  String? _intRequired(String? value) {
    final required = _required(value);
    if (required != null) return required;
    if (int.tryParse(value!.trim()) == null) return 'Format angka tidak valid';
    return null;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _numText(double? value) {
    if (value == null || value == 0) return '';
    return value.toString();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int minLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.minLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: minLines > 1 ? minLines + 1 : 1,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 19),
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _LocationButton({
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location_rounded, size: 18),
        label: Text(
          loading ? 'Mengambil koordinat...' : 'Ambil Lokasi Saya',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryDark,
          side: const BorderSide(color: AppTheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
