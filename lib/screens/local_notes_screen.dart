import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/local_note_controller.dart';
import '../models/note_model.dart';

class LocalNotesScreen extends GetView<LocalNoteController> {
  const LocalNotesScreen({super.key});

  void _openNoteSheet(BuildContext context, {NoteModel? existing}) {
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
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existing == null ? 'Catatan Baru (Hive)' : 'Perbarui Catatan',
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
                  controller.saveNote(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline (Hive)'),
        actions: [
          IconButton(
            tooltip: 'Bersihkan semua catatan',
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Semua Catatan?'),
                  content: const Text(
                    'Tindakan ini hanya berlaku pada penyimpanan lokal Hive dan tidak bisa dibatalkan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await controller.deleteAll();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteSheet(context),
        icon: const Icon(Icons.note_add),
        label: const Text('Catatan Baru'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum ada catatan di Hive.'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => _openNoteSheet(context),
                  child: const Text('Tambahkan Catatan Pertama'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, index) {
            final note = controller.notes[index];
            return Card(
              child: ListTile(
                title: Text(note.title),
                subtitle: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: const Icon(Icons.offline_pin, color: Colors.green),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openNoteSheet(context, existing: note);
                    } else if (value == 'delete') {
                      controller.deleteNote(note.id);
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
      }),
    );
  }
}
