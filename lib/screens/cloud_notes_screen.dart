import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/design_tokens.dart';
import '../controllers/cloud_note_controller.dart';
import '../models/note_model.dart';

class CloudNotesScreen extends StatefulWidget {
  const CloudNotesScreen({super.key});

  @override
  State<CloudNotesScreen> createState() => _CloudNotesScreenState();
}

class _CloudNotesScreenState extends State<CloudNotesScreen> {
  late final CloudNoteController cloudController =
      Get.find<CloudNoteController>();

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
                existing == null
                    ? 'Catatan baru untuk koleksi kamu'
                    : 'Perbarui catatan',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  hintText: 'Contoh: Reminder styling, drop date, dsb.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText:
                      'Tulis detail penting: konsep foto, warna, kode produk...',
                ),
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
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(existing == null ? 'Simpan' : 'Perbarui'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Halaman catatan tidak menampilkan form login apa pun.

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
              const Icon(Icons.style, size: 64, color: AppColors.primaryPink),
              const SizedBox(height: 12),
              const Text(
                'Belum ada catatan fashion-mu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Simpan ide styling, jadwal drop, atau catatan photoshoot di satu tempat yang rapi.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openNoteSheet(),
                icon: const Icon(Icons.add),
                label: const Text('Catat sekarang'),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: cloudController.notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final note = cloudController.notes[index];
          final unsynced = !note.synced;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
              border: Border.all(
                color: unsynced
                    ? AppColors.warning.withOpacity(0.7)
                    : Colors.transparent,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: unsynced
                    ? AppColors.warning.withOpacity(0.18)
                    : AppColors.primaryPinkLight.withOpacity(0.25),
                child: Icon(
                  unsynced ? Icons.offline_pin : Icons.check,
                  color: unsynced ? AppColors.warning : AppColors.primaryPink,
                ),
              ),
              title: Text(
                note.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
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
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100), // Lift above CustomNavBar
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryPink,
          onPressed: () => _openNoteSheet(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Catatan', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => cloudController.refreshNotes(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              decoration: const BoxDecoration(
                gradient: AppGradients.pill,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Catatan Koleksi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Kumpulkan ide outfit menarik.',
                                style: TextStyle(
                                  color: Color.fromARGB(214, 255, 255, 255),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => cloudController.refreshNotes(),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'Segarkan',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Persistent loading indicator for sync
                    Obx(() {
                      if (cloudController.isSyncing.value) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const LinearProgressIndicator(
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                              minHeight: 4,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sedang Menyimpan...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildNotesList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
