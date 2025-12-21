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
import '../widgets/address_form_sheet.dart';

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
