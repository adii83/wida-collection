import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../config/design_tokens.dart';
import '../models/user_address.dart';
import '../services/location_service.dart';
import '../widgets/gradient_button.dart';

class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({super.key, this.initial});

  final UserAddress? initial;

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _streetController;
  late final TextEditingController _extraController;

  LatLng? _markerPosition;
  bool _isLocating = false;
  bool _isLoadingMap = true;
  final MapController _mapController = MapController();
  double _currentZoom = 16;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _provinceController = TextEditingController(text: initial?.province ?? '');
    _cityController = TextEditingController(text: initial?.city ?? '');
    _districtController = TextEditingController(text: initial?.district ?? '');
    _postalCodeController = TextEditingController(
      text: initial?.postalCode ?? '',
    );
    _streetController = TextEditingController(text: initial?.street ?? '');
    _extraController = TextEditingController(text: initial?.extraDetail ?? '');

    if (initial?.latitude != null && initial?.longitude != null) {
      // Jika sedang mengedit alamat yang sudah punya koordinat, langsung pakai itu
      _markerPosition = LatLng(initial!.latitude!, initial.longitude!);
      _isLoadingMap = false;
    } else {
      // Untuk alamat baru, tunggu GPS dulu sebelum menampilkan peta
      _markerPosition = null;
      _isLoadingMap = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initLocationMarker();
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    _streetController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  Future<void> _initLocationMarker() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMap = true;
    });

    const fallback = LatLng(-6.200000, 106.816666); // Jakarta
    try {
      final position = await LocationService().getCurrentPosition(useGps: true);
      if (position != null && mounted) {
        setState(() {
          _markerPosition = LatLng(position.latitude, position.longitude);
          _isLoadingMap = false;
        });
        return;
      }
    } catch (_) {
      // Abaikan error dan gunakan fallback
    }

    if (mounted) {
      setState(() {
        _markerPosition = fallback;
        _isLoadingMap = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_markerPosition == null) return;

    setState(() {
      _isLocating = true;
    });

    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        _markerPosition!.latitude,
        _markerPosition!.longitude,
        localeIdentifier: 'id_ID',
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        if ((p.administrativeArea ?? '').isNotEmpty) {
          _provinceController.text = p.administrativeArea!;
        }
        final city =
            p.subAdministrativeArea ?? p.locality ?? p.administrativeArea;
        if ((city ?? '').isNotEmpty) {
          _cityController.text = city!;
        }
        if ((p.subLocality ?? '').isNotEmpty) {
          _districtController.text = p.subLocality!;
        }
        if ((p.postalCode ?? '').isNotEmpty) {
          _postalCodeController.text = p.postalCode!;
        }
        final streetParts = <String>[];
        if ((p.street ?? '').isNotEmpty) streetParts.add(p.street!);
        if ((p.subThoroughfare ?? '').isNotEmpty) {
          streetParts.add(p.subThoroughfare!);
        }
        if (streetParts.isNotEmpty && _streetController.text.isEmpty) {
          _streetController.text = streetParts.join(', ');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final addr = UserAddress(
      id: id,
      label: _labelController.text.trim().isEmpty
          ? null
          : _labelController.text.trim(),
      province: _provinceController.text.trim().isEmpty
          ? null
          : _provinceController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      district: _districtController.text.trim().isEmpty
          ? null
          : _districtController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      street: _streetController.text.trim().isEmpty
          ? null
          : _streetController.text.trim(),
      extraDetail: _extraController.text.trim().isEmpty
          ? null
          : _extraController.text.trim(),
      latitude: _markerPosition?.latitude,
      longitude: _markerPosition?.longitude,
      isDefault: widget.initial?.isDefault ?? false,
    );

    Navigator.of(context).pop(addr);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final center =
        _markerPosition ?? const LatLng(-6.200000, 106.816666); // Jakarta
    final height = MediaQuery.of(context).size.height * 0.75;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // FIXED HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tambah alamat',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.charcoal,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // SCROLLABLE BODY
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _labelController,
                          decoration: const InputDecoration(
                            labelText: 'Nama alamat (mis: Rumah, Kantor)',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Provinsi, Kota, Kecamatan, Kode pos',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.blush,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _provinceController,
                                decoration: const InputDecoration(
                                  labelText: 'Provinsi',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'Kota / Kabupaten',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _districtController,
                                decoration: const InputDecoration(
                                  labelText: 'Kecamatan',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _postalCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Kode pos',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _streetController,
                          decoration: const InputDecoration(
                            labelText: 'Nama jalan, gedung, no. rumah',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _extraController,
                          decoration: const InputDecoration(
                            labelText: 'Detail lainnya (blok/patokan)',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isLocating
                                  ? null
                                  : _useCurrentLocation,
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                    ),
                              label: const Text(
                                'Gunakan lokasi saya',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _isLoadingMap
                            ? AspectRatio(
                                aspectRatio: 1.7,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.blush,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryPink,
                                    ),
                                  ),
                                ),
                              )
                            : AspectRatio(
                                aspectRatio: 1.7,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Stack(
                                    children: [
                                      FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: center,
                                          initialZoom: _currentZoom,
                                          onTap: (tapPos, point) {
                                            setState(() {
                                              _markerPosition = point;
                                            });
                                          },
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'com.winda.collection',
                                          ),
                                          if (_markerPosition != null)
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: _markerPosition!,
                                                  width: 60,
                                                  height: 60,
                                                  alignment:
                                                      Alignment.topCenter,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.location_on,
                                                        color: AppColors
                                                            .primaryPink,
                                                        size: 40,
                                                      ),
                                                      Container(
                                                        width: 18,
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black26,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                999,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 24),
                        GradientButton(
                          label: 'Simpan Alamat',
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
