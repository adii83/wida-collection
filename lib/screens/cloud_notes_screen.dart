import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cloud_note_controller.dart';
import '../models/note_model.dart';

class CloudNotesScreen extends StatefulWidget {
  const CloudNotesScreen({super.key});

  @override
  State<CloudNotesScreen> createState() => _CloudNotesScreenState();
}

class _CloudNotesScreenState extends State<CloudNotesScreen> {
  late final AuthController authController = Get.find<AuthController>();
  late final CloudNoteController cloudController =
      Get.find<CloudNoteController>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _openNoteSheet({NoteModel? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(
      text: existing?.content ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existing == null ? 'Catatan Cloud' : 'Perbarui Catatan',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Catatan'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (titleController.text.isEmpty ||
                      contentController.text.isEmpty) {
                    Get.snackbar(
                      'Validasi',
                      'Judul dan catatan wajib diisi',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  cloudController.saveNote(
                    id: existing?.id,
                    title: titleController.text,
                    content: contentController.text,
                  );
                  Navigator.of(ctx).pop();
                },
                child: Text(existing == null ? 'Simpan' : 'Perbarui'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthCard() {
    return Obx(
      () => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masuk ke Supabase',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: authController.isLoading.value
                          ? null
                          : () => authController
                                .signIn(
                                  emailController.text,
                                  passwordController.text,
                                )
                                .then((success) {
                                  if (!success) {
                                    Get.snackbar(
                                      'Login gagal',
                                      authController.lastError.value ??
                                          'Unknown error',
                                    );
                                  }
                                }),
                      child: authController.isLoading.value
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Masuk'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : () => authController
                              .signUp(
                                emailController.text,
                                passwordController.text,
                              )
                              .then((success) {
                                if (success) {
                                  Get.snackbar(
                                    'Registrasi Berhasil',
                                    'Silakan periksa email untuk verifikasi jika diperlukan.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } else {
                                  Get.snackbar(
                                    'Registrasi gagal',
                                    authController.lastError.value ??
                                        'Unknown error',
                                  );
                                }
                              }),
                    child: const Text('Daftar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    return Obx(() {
      if (cloudController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (cloudController.notes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Belum ada catatan di Supabase.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _openNoteSheet(),
                child: const Text('Tambah Catatan Cloud'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          if (cloudController.lastSyncedAt.value != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sinkron terakhir: ${cloudController.lastSyncedAt.value}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cloudController.notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final note = cloudController.notes[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_done),
                    title: Text(note.title),
                    subtitle: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openNoteSheet(existing: note);
                        } else if (value == 'delete') {
                          cloudController.deleteNote(note.id);
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Cloud (Supabase)'),
        actions: [
          Obx(
            () => authController.isLoggedIn
                ? IconButton(
                    tooltip: 'Keluar',
                    icon: const Icon(Icons.logout),
                    onPressed: authController.signOut,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => authController.isLoggedIn
            ? FloatingActionButton.extended(
                onPressed: () => _openNoteSheet(),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Catatan Cloud'),
              )
            : const SizedBox.shrink(),
      ),
      body: Builder(
        builder: (context) {
          if (!cloudController.canUseSupabase) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Text(
                  'Supabase belum dikonfigurasi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Isi nilai SUPABASE_URL dan SUPABASE_ANON_KEY menggunakan --dart-define saat menjalankan aplikasi atau ubah file supabase_config.dart. Setelah itu fitur cloud akan aktif.',
                ),
              ],
            );
          }

          return Obx(
            () => authController.isLoggedIn
                ? _buildNotesList()
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildAuthCard(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Gunakan akun yang sama di dua perangkat untuk menjalankan eksperimen multi-device. Perubahan catatan akan tersinkronisasi otomatis lewat real-time channel Supabase setelah pengguna melakukan refresh atau saat payload real-time diterima.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
