import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/lookbook_entry.dart';
import '../services/hive_service.dart';

class LookbookController extends GetxController {
  LookbookController(this._hiveService);

  final HiveService _hiveService;
  final _uuid = const Uuid();

  final entries = <LookbookEntry>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEntries();
  }

  Future<void> loadEntries() async {
    isLoading.value = true;
    try {
      entries.assignAll(_hiveService.readLookbook());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveEntry({
    String? id,
    required String title,
    required String occasion,
    required String mood,
    required String notes,
    required String imagePath,
  }) async {
    final now = DateTime.now();
    LookbookEntry? previous;
    if (id != null) {
      for (final entry in entries) {
        if (entry.id == id) {
          previous = entry;
          break;
        }
      }
    }

    final entry = LookbookEntry(
      id: id ?? _uuid.v4(),
      title: title,
      occasion: occasion,
      mood: mood,
      notes: notes,
      imagePath: imagePath,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
    await _hiveService.saveLookbookEntry(entry);
    await loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await _hiveService.deleteLookbookEntry(id);
    await loadEntries();
  }
}
