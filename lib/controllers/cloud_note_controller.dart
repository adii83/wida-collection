import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import 'auth_controller.dart';

class CloudNoteController extends GetxController {
  CloudNoteController(
    this._supabaseService,
    this._authController,
    this._hiveService,
  );

  final SupabaseService _supabaseService;
  final AuthController _authController;
  final HiveService _hiveService;
  final _uuid = const Uuid();

  final notes = <NoteModel>[].obs;
  final isLoading = false.obs;
  final Rxn<DateTime> lastSyncedAt = Rxn<DateTime>();

  bool get canUseSupabase => _supabaseService.isReady;
  bool get _isOnline => _authController.isLoggedIn && canUseSupabase;
  String get _owner => _authController.currentUser.value?.id ?? 'local';

  @override
  void onInit() {
    super.onInit();
    loadLocalNotes();
    ever(_authController.currentUser, (user) {
      _unsubscribe();
      loadLocalNotes();
      if (user != null) {
        _subscribe();
        refreshNotes();
      }
    });

    if (_authController.isLoggedIn) {
      _subscribe();
      refreshNotes();
    }
  }

  Future<void> refreshNotes() async {
    if (!_isOnline) {
      await loadLocalNotes();
      return;
    }
    await _pushLocalToCloud();
    await _syncFromCloud();
  }

  Future<void> loadLocalNotes() async {
    final cached = _hiveService.readNotes(owner: _owner);
    notes.assignAll(cached);
  }

  Future<void> _syncFromCloud() async {
    try {
      isLoading.value = true;
      final data = await _supabaseService.fetchNotes();
      await _hiveService.clearNotes(_owner);
      for (final note in data) {
        await _hiveService.saveNote(_owner, note.copyWith(synced: true));
      }
      final local = _hiveService.readNotes(owner: _owner);
      notes.assignAll(local);
      lastSyncedAt.value = DateTime.now();
    } catch (e) {
      _showError('Gagal memuat catatan', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _pushLocalToCloud() async {
    if (!_isOnline) return;
    final local = _hiveService.readNotes(owner: _owner);
    for (final note in local.where((n) => !n.synced)) {
      try {
        await _supabaseService.upsertNote(note, _owner);
        final syncedNote = note.copyWith(synced: true);
        await _hiveService.saveNote(_owner, syncedNote);
      } catch (_) {
        // keep offline state; user will see unsynced badge
      }
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
      synced: _isOnline,
    );
    try {
      await _hiveService.saveNote(_owner, note);
      await loadLocalNotes();
      if (_isOnline) {
        await _supabaseService.upsertNote(note, _owner);
        final syncedNote = note.copyWith(synced: true);
        await _hiveService.saveNote(_owner, syncedNote);
        await loadLocalNotes();
        lastSyncedAt.value = DateTime.now();
      }
    } catch (e) {
      _showError('Gagal menyimpan catatan', e);
    }
  }

  Future<void> deleteNote(String id) async {
    NoteModel? removed;
    for (final note in notes) {
      if (note.id == id) {
        removed = note;
        break;
      }
    }
    try {
      await _hiveService.deleteNote(_owner, id);
      await loadLocalNotes();
      if (_isOnline) {
        await _supabaseService.deleteNote(id);
        lastSyncedAt.value = DateTime.now();
      }
    } catch (e) {
      if (removed != null) {
        await _hiveService.saveNote(_owner, removed);
        await loadLocalNotes();
      }
      _showError('Gagal menghapus catatan', e);
    }
  }

  void _showError(String title, Object error) {
    Get.snackbar(title, error.toString(), snackPosition: SnackPosition.BOTTOM);
  }

  void _subscribe() {
    _supabaseService.subscribeNotes((_) => refreshNotes());
  }

  void _unsubscribe() {
    _supabaseService.disposeChannel();
  }

  @override
  void onClose() {
    _unsubscribe();
    super.onClose();
  }
}
