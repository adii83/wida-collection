import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;

  AuthController get _auth => Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

    final success = _isLoginMode
        ? await _auth.signIn(email, password)
        : await _auth.signUp(email, password);

    if (success && mounted) {
      Get.snackbar(
        _isLoginMode ? 'Berhasil Masuk' : 'Berhasil Daftar',
        'Wishlist Anda kini terhubung ke Supabase.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login & Signup Supabase'),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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

              return Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLoginMode
                              ? Icons.lock_open
                              : Icons.person_add_alt_1,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isLoginMode ? 'Masuk Akun' : 'Daftar Akun Baru',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Supabase auth akan menyimpan wishlist tiap pengguna secara terpisah.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _auth.isLoading.value ? null : _submit,
                              icon: _auth.isLoading.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _isLoginMode
                                          ? Icons.login
                                          : Icons.app_registration,
                                    ),
                              label: Text(_isLoginMode ? 'Masuk' : 'Daftar'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                            });
                          },
                          child: Text(
                            _isLoginMode
                                ? 'Belum punya akun? Daftar di sini'
                                : 'Sudah punya akun? Masuk di sini',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(
                          () => _auth.lastError.value == null
                              ? const SizedBox.shrink()
                              : Text(
                                  _auth.lastError.value!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, size: 48),
            const SizedBox(height: 12),
            Text('Sudah Masuk', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(email, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            const Text(
              'Wishlist Anda otomatis tampil sesuai akun ini di semua perangkat.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
