import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../services/supabase_service.dart';
import 'auth_controller.dart';

class CloudNoteController extends GetxController {
  CloudNoteController(this._supabaseService, this._authController);

  final SupabaseService _supabaseService;
  final AuthController _authController;
  final _uuid = const Uuid();

  final notes = <NoteModel>[].obs;
  final isLoading = false.obs;
  final Rxn<DateTime> lastSyncedAt = Rxn<DateTime>();

  bool get canUseSupabase => _supabaseService.isReady;

  @override
  void onInit() {
    super.onInit();
    ever(_authController.currentUser, (user) {
      if (user != null) {
        loadNotes();
        _supabaseService.subscribeNotes((_) => loadNotes());
      } else {
        notes.clear();
        _supabaseService.disposeChannel();
      }
    });

    if (_authController.isLoggedIn) {
      loadNotes();
      _supabaseService.subscribeNotes((_) => loadNotes());
    }
  }

  Future<void> loadNotes() async {
    if (!_authController.isLoggedIn || !_supabaseService.isReady) return;
    try {
      isLoading.value = true;
      final data = await _supabaseService.fetchNotes();
      notes.assignAll(data);
      lastSyncedAt.value = DateTime.now();
    } catch (e) {
      _showError('Gagal memuat catatan', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveNote({
    String? id,
    required String title,
    required String content,
  }) async {
    if (!_authController.isLoggedIn || !_supabaseService.isReady) return;
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
      synced: true,
    );
    try {
      await _supabaseService.upsertNote(
        note,
        _authController.currentUser.value!.id,
      );
      await loadNotes();
    } catch (e) {
      _showError('Gagal menyimpan catatan', e);
    }
  }

  Future<void> deleteNote(String id) async {
    if (!_authController.isLoggedIn || !_supabaseService.isReady) return;
    try {
      await _supabaseService.deleteNote(id);
      await loadNotes();
    } catch (e) {
      _showError('Gagal menghapus catatan', e);
    }
  }

  void _showError(String title, Object error) {
    Get.snackbar(title, error.toString(), snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void onClose() {
    _supabaseService.disposeChannel();
    super.onClose();
  }
}
