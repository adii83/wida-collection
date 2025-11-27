import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../controller/auth_controller.dart';
import '../widgets/gradient_button.dart';
import '../widgets/rounded_icon_button.dart';

enum AuthMode { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthMode.login});

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _rememberMe = false;

  late AuthMode _mode = widget.initialMode;

  AuthController get _auth => Get.find<AuthController>();

  bool get _isLogin => _mode == AuthMode.login;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_auth.canUseSupabase) {
      Get.snackbar(
        'Supabase belum siap',
        'Pastikan kredensial Supabase terisi di .env lalu restart aplikasi.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isLogin && password != _confirmPasswordController.text.trim()) {
      Get.snackbar('Cek Ulang', 'Konfirmasi password belum sama');
      return;
    }

    final success = _isLogin
        ? await _auth.signIn(email, password)
        : await _auth.signUp(email, password);

    if (success && mounted) {
      Get.snackbar(
        _isLogin ? 'Selamat datang kembali!' : 'Akun berhasil dibuat',
        'Wishlist Anda kini terhubung ke Supabase.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(gradient: AppGradients.hero),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Obx(() {
                if (_auth.isLoggedIn) {
                  final user = _auth.currentUser.value;
                  return _AccountSummary(
                    email: user?.email ?? '-',
                    onSignOut: () async {
                      final navigator = Navigator.of(context);
                      await _auth.signOut();
                      if (!mounted) return;
                      if (navigator.canPop()) {
                        navigator.pop();
                      }
                    },
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.heroTop,
                    AppSpacing.page,
                    48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RoundedIconButton(
                            icon: Icons.arrow_back,
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                          TextButton(
                            onPressed: () => _switchMode(
                              _isLogin ? AuthMode.signup : AuthMode.login,
                            ),
                            child: Text(
                              _isLogin
                                  ? 'Daftar sekarang'
                                  : 'Sudah punya akun?',
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vHero,
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: AppColors.primaryPink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Wida Collection',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      AppSpacing.vSection,
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Create Account',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _isLogin
                            ? 'Login untuk melanjutkan belanja'
                            : 'Daftar untuk mulai berbelanja',
                        style: const TextStyle(color: AppColors.softGray),
                      ),
                      AppSpacing.vSection,
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
                            children: [
                              if (!_isLogin) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Lengkap',
                                  ),
                                  validator: (value) {
                                    if (!_isLogin &&
                                        (value == null || value.isEmpty)) {
                                      return 'Nama wajib diisi';
                                    }
                                    return null;
                                  },
                                ),
                                AppSpacing.vItem,
                              ],
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email wajib diisi';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              AppSpacing.vItem,
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                              if (!_isLogin) ...[
                                AppSpacing.vItem,
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: const InputDecoration(
                                    labelText: 'Konfirmasi Password',
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (!_isLogin &&
                                        (value == null || value.isEmpty)) {
                                      return 'Konfirmasi password wajib diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) => setState(
                                      () => _rememberMe = value ?? false,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _isLogin
                                          ? 'Remember me'
                                          : 'Saya setuju dengan Terms & Privacy',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (_isLogin)
                                    TextButton(
                                      onPressed: () => Get.snackbar(
                                        'Info',
                                        'Hubungi admin untuk reset password',
                                      ),
                                      child: const Text('Lupa password?'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                () => GradientButton(
                                  label: _isLogin ? 'Login' : 'Daftar',
                                  onPressed: _auth.isLoading.value
                                      ? null
                                      : _submit,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: const [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('atau login dengan'),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.g_mobiledata,
                                        size: 28,
                                      ),
                                      label: const Text('Google'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.facebook_rounded),
                                      label: const Text('Facebook'),
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.vItem,
                              Obx(
                                () => _auth.lastError.value == null
                                    ? const SizedBox.shrink()
                                    : Text(
                                        _auth.lastError.value!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.email, required this.onSignOut});

  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user,
            size: 48,
            color: AppColors.primaryPink,
          ),
          AppSpacing.vItem,
          Text('Sudah Masuk', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(email, style: Theme.of(context).textTheme.bodyLarge),
          AppSpacing.vItem,
          const Text(
            'Wishlist Anda otomatis tampil sesuai akun ini di semua perangkat.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GradientButton(label: 'Keluar', onPressed: onSignOut),
        ],
      ),
    );
  }
}
