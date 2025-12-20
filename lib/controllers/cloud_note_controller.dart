import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
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
  // isLoading is kept for initial load, isSyncing for background sync
  final isLoading = false.obs;
  final isSyncing = false.obs;
  final Rxn<DateTime> lastSyncedAt = Rxn<DateTime>();

  bool get canUseSupabase => _supabaseService.isReady;
  bool get _isOnline => _authController.isLoggedIn && canUseSupabase;
  String get _owner => _authController.currentUser.value?.id ?? 'local';

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    loadLocalNotes();

    // Monitor connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        // If we were stuck in syncing state or just came online, try to sync
        if (isSyncing.value || _authController.isLoggedIn) {
          _retrySync();
        }
      }
    });

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

  final _pendingDeleteIds = <String>{};

  Future<void> _retrySync() async {
    if (!_isOnline) return;
    try {
      // 1. Process pending deletes first
      if (_pendingDeleteIds.isNotEmpty) {
        final List<String> deleted = [];
        for (final id in _pendingDeleteIds) {
          try {
            await _supabaseService.deleteNote(id);
            deleted.add(id);
          } catch (e) {
            debugPrint('Failed to sync delete for $id: $e');
            // If 404/Not Found, it's effectively deleted, so we can remove from pending
            if (e.toString().contains('404')) deleted.add(id);
          }
        }
        _pendingDeleteIds.removeAll(deleted);
      }

      // 2. Push pending creates/updates
      await _pushLocalToCloud();

      // 3. Pull latest data
      await _syncFromCloud();

      isSyncing.value = false; // Success!
    } catch (e) {
      debugPrint('Retry sync failed: $e');
    }
  }

  Future<void> refreshNotes() async {
    isSyncing.value = true;
    if (!_isOnline) {
      await loadLocalNotes();
      return;
    }
    try {
      // Process pending deletes before pulling to avoid resurrection
      if (_pendingDeleteIds.isNotEmpty) {
        for (final id in _pendingDeleteIds.toList()) {
          await _supabaseService.deleteNote(id);
          _pendingDeleteIds.remove(id);
        }
      }

      await _pushLocalToCloud();
      await _syncFromCloud();
      isSyncing.value = false;
    } catch (e) {
      _showError('Gagal refresh', e);

      final isNetworkError =
          e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('Network is unreachable');

      if (isNetworkError || !_isOnline)
        isSyncing.value = true;
      else
        isSyncing.value = false;
    }
  }

  Future<void> loadLocalNotes() async {
    final cached = _hiveService.readNotes(owner: _owner);
    notes.assignAll(cached);
  }

  Future<void> _syncFromCloud() async {
    try {
      // isLoading.value = true; // Don't use isLoading, we use isSyncing
      final data = await _supabaseService.fetchNotes();
      await _hiveService.clearNotes(_owner);
      for (final note in data) {
        await _hiveService.saveNote(_owner, note.copyWith(synced: true));
      }
      final local = _hiveService.readNotes(owner: _owner);
      notes.assignAll(local);
      lastSyncedAt.value = DateTime.now();
    } catch (e) {
      throw e; // Let caller handle
    }
  }

  Future<void> _pushLocalToCloud() async {
    // strict check inside this logic not needed if caller checks, but safe to keep
    if (!_isOnline) return;

    final local = _hiveService.readNotes(owner: _owner);
    for (final note in local.where((n) => !n.synced)) {
      try {
        await _supabaseService.upsertNote(note, _owner);
        final syncedNote = note.copyWith(synced: true);
        await _hiveService.saveNote(_owner, syncedNote);
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<void> saveNote({
    String? id,
    required String title,
    required String content,
  }) async {
    isSyncing.value = true; // Start persistent loading
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
      synced: false, // Always start as unsynced locally
    );
    try {
      await _hiveService.saveNote(_owner, note);
      await loadLocalNotes();

      if (!_isOnline) {
        // Offline: Keep isSyncing = true
        return;
      }

      await _supabaseService.upsertNote(note, _owner);

      // Only now mark as synced
      final syncedNote = note.copyWith(synced: true);
      await _hiveService.saveNote(_owner, syncedNote);
      await loadLocalNotes();

      lastSyncedAt.value = DateTime.now();
      isSyncing.value = false; // Done
    } catch (e) {
      _showError('Gagal menyimpan catatan', e);
      // Check for network errors (String check to avoid importing dart:io/http)
      final isNetworkError =
          e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('Network is unreachable');

      if (isNetworkError || !_isOnline) {
        isSyncing.value = true; // Keep spinning if offline/network error
      } else {
        isSyncing.value =
            false; // Stop if it's a logic error (e.g. valid data invalid)
      }
    }
  }

  Future<void> deleteNote(String id) async {
    isSyncing.value = true;

    // Optimistic Update: Always delete locally first
    await _hiveService.deleteNote(_owner, id);
    await loadLocalNotes();

    // If offline, just mark as pending delete and return
    if (!_isOnline) {
      _pendingDeleteIds.add(id);
      // Keep isSyncing = true to show "working/pending" state
      return;
    }

    try {
      await _supabaseService.deleteNote(id);
      lastSyncedAt.value = DateTime.now();
      isSyncing.value = false;
    } catch (e) {
      _showError('Gagal menghapus catatan', e);

      final isNetworkError =
          e.toString().contains('SocketException') ||
          e.toString().contains('ClientException');

      if (isNetworkError) {
        // If delete failed due to network, queue it for retry
        _pendingDeleteIds.add(id);
        isSyncing.value = true;
      } else {
        isSyncing.value = false;
      }
    }
  }

  void _showError(String title, Object error) {
    // Suppress UI errors for offline/sync issues as requested.
    // Use debugPrint to log errors to the terminal instead.
    debugPrint('[$title]: $error');
  }

  void _subscribe() {
    _supabaseService.subscribeNotes((_) => refreshNotes());
  }

  void _unsubscribe() {
    _supabaseService.disposeChannel();
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    _unsubscribe();
    super.onClose();
  }
}
