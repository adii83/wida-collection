import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/lookbook_controller.dart';

class LookbookScreen extends GetView<LookbookController> {
  const LookbookScreen({super.key});

  void _openSheet(BuildContext context, {LookbookEntryForm? existing}) {
    final title = TextEditingController(text: existing?.title ?? '');
    final occasion = TextEditingController(text: existing?.occasion ?? '');
    final mood = TextEditingController(text: existing?.mood ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    final image = TextEditingController(text: existing?.imagePath ?? '');

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
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                existing == null ? 'Outfit Baru' : 'Edit Outfit',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Judul Look'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: occasion,
                decoration: const InputDecoration(labelText: 'Acara / Kondisi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mood,
                decoration: const InputDecoration(labelText: 'Mood'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan styling'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: image,
                decoration: const InputDecoration(
                  labelText: 'Path/URL foto (opsional)',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  controller.saveEntry(
                    id: existing?.id,
                    title: title.text,
                    occasion: occasion.text,
                    mood: mood.text,
                    notes: notes.text,
                    imagePath: image.text,
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
      appBar: AppBar(title: const Text('Lookbook & Jurnal Gaya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(context),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Tambah Look'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.entries.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada look tersimpan. Dokumentasikan OOTD terbaikmu!',
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: controller.entries.length,
          itemBuilder: (context, index) {
            final entry = controller.entries[index];
            return GestureDetector(
              onLongPress: () => controller.deleteEntry(entry.id),
              onTap: () => _openSheet(
                context,
                existing: LookbookEntryForm(
                  id: entry.id,
                  title: entry.title,
                  occasion: entry.occasion,
                  mood: entry.mood,
                  notes: entry.notes,
                  imagePath: entry.imagePath,
                ),
              ),
              child: Card(
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: entry.imagePath.isEmpty
                          ? Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Center(child: Icon(Icons.style)),
                            )
                          : entry.imagePath.startsWith('assets/')
                          ? Image.asset(
                              entry.imagePath,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              entry.imagePath,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Center(child: Icon(Icons.broken_image)),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(entry.occasion),
                          Text('Mood: ${entry.mood}'),
                        ],
                      ),
                    ),
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

class LookbookEntryForm {
  LookbookEntryForm({
    required this.id,
    required this.title,
    required this.occasion,
    required this.mood,
    required this.notes,
    required this.imagePath,
  });

  final String id;
  final String title;
  final String occasion;
  final String mood;
  final String notes;
  final String imagePath;
}
