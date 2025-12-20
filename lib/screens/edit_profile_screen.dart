import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../controllers/auth_controller.dart';
import '../models/user_address.dart';
import '../services/location_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/rounded_icon_button.dart';
import '../widgets/success_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final AuthController _auth = Get.find<AuthController>();

  Future<void> _openAddressForm({UserAddress? existing}) async {
    final result = await showModalBottomSheet<UserAddress?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressFormSheet(initial: existing),
    );

    if (!mounted || result == null) return;

    final success = await _auth.upsertAddress(result);
    if (success) {
      SuccessDialog.show(
        title: 'Berhasil!',
        subtitle: 'Alamat kamu berhasil disimpan.',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: _auth.profile.value?.fullName ?? '',
    );
    _usernameController = TextEditingController(
      text: _auth.profile.value?.username ?? '',
    );
    _phoneController = TextEditingController(
      text: _auth.profile.value?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await _auth.updateProfile(
      fullName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (success) {
      SuccessDialog.show(
        title: 'Berhasil!',
        subtitle: 'Profil kamu berhasil diperbarui.',
        onPressed: () {
          Get.back(); // Close dialog
          Get.back(); // Close screen
        },
      );
    }
  }

  Future<void> _setDefaultAddress(UserAddress addr) async {
    await _auth.setDefaultAddress(addr.id);
  }

  Future<void> _deleteAddress(UserAddress addr) async {
    await _auth.deleteAddress(addr.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(gradient: AppGradients.hero),
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: RoundedIconButton(
                              icon: Icons.arrow_back,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const Text(
                            'Edit Profil',
                            style: TextStyle(
                              color: AppColors.charcoal,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vHero,
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: AppShadows.card,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama lengkap wajib diisi';
                                }
                                return null;
                              },
                            ),
                            AppSpacing.vItem,
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Username wajib diisi';
                                }
                                return null;
                              },
                            ),
                            AppSpacing.vItem,
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'No. HP (opsional)',
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Alamat Saya',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _openAddressForm(),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primaryPink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 8),
                            Obx(() {
                              if (_auth.addresses.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.blush,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Belum ada alamat pengiriman. Tambahkan alamat baru dengan ikon + di kanan.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.softGray,
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: _auth.addresses.map((addr) {
                                  final title = addr.label?.isNotEmpty == true
                                      ? addr.label!
                                      : (addr.city ?? 'Alamat');
                                  final line1 = [addr.street, addr.extraDetail]
                                      .whereType<String>()
                                      .where((t) => t.isNotEmpty)
                                      .join(', ');
                                  final line2 =
                                      [
                                            addr.district,
                                            addr.city,
                                            addr.province,
                                            addr.postalCode,
                                          ]
                                          .whereType<String>()
                                          .where((t) => t.isNotEmpty)
                                          .join(', ');
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: addr.isDefault
                                              ? AppColors.primaryPink
                                              : AppColors.primaryPinkLight,
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              if (addr.isDefault)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.primaryPink,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'Utama',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (line1.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              line1,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.charcoal,
                                              ),
                                            ),
                                          ],
                                          if (line2.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              line2,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.softGray,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _setDefaultAddress(addr),
                                                icon: Icon(
                                                  addr.isDefault
                                                      ? Icons
                                                            .radio_button_checked
                                                      : Icons.radio_button_off,
                                                  size: 18,
                                                  color: AppColors.primaryPink,
                                                ),
                                                label: const Text(
                                                  'Jadikan utama',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.primaryPink,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        _openAddressForm(
                                                          existing: addr,
                                                        ),
                                                    child: const Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.softGray,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        _deleteAddress(addr),
                                                    child: const Text(
                                                      'Hapus',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.softGray,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }),
                            const SizedBox(height: 24),
                            Obx(
                              () => GradientButton(
                                label: 'Simpan',
                                onPressed: _auth.isLoading.value ? null : _save,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Column(
                                          children: [
                                            _buildZoomButton(
                                              icon: Icons.add,
                                              onTap: () {
                                                setState(() {
                                                  _currentZoom += 1;
                                                  _mapController.move(
                                                    _markerPosition ?? center,
                                                    _currentZoom,
                                                  );
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            _buildZoomButton(
                                              icon: Icons.remove,
                                              onTap: () {
                                                setState(() {
                                                  _currentZoom -= 1;
                                                  _mapController.move(
                                                    _markerPosition ?? center,
                                                    _currentZoom,
                                                  );
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // FIXED FOOTER
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Simpan alamat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: AppColors.charcoal),
        ),
      ),
    );
  }
}
