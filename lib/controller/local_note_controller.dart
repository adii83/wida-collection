import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../services/hive_service.dart';

class LocalNoteController extends GetxController {
  LocalNoteController(this._hiveService);

  final HiveService _hiveService;
  final _uuid = const Uuid();

  final notes = <NoteModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  Future<void> loadNotes() async {
    isLoading.value = true;
    try {
      final sw = Stopwatch()..start();
      final data = _hiveService.readNotes();
      sw.stop();
      debugPrint('Hive read: ${sw.elapsedMilliseconds} ms');
      notes.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveNote({
    String? id,
    required String title,
    required String content,
  }) async {
    final now = DateTime.now();
    NoteModel? existing;
    if (id != null) {
      for (final note in notes) {
        if (note.id == id) {
          existing = note;
          break;
        }
      }
    }
    final note = NoteModel(
      id: id ?? _uuid.v4(),
      title: title,
      content: content,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      synced: false,
    );
    final sw = Stopwatch()..start();
    await _hiveService.saveNote(note);
    sw.stop();
    debugPrint('Hive write: ${sw.elapsedMilliseconds} ms');
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _hiveService.deleteNote(id);
    await loadNotes();
  }

  Future<void> deleteAll() async {
    await _hiveService.clear();
    await loadNotes();
  }
}
