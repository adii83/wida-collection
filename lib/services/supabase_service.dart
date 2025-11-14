import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/note_model.dart';
import '../models/wishlist_item.dart';

class SupabaseService extends GetxService {
  SupabaseClient? _client;
  RealtimeChannel? _notesChannel;
  RealtimeChannel? _wishlistChannel;
  bool _initialized = false;

  SupabaseClient? get client => _client;
  bool get isReady => _initialized && _client != null;

  Future<SupabaseService> init() async {
    if (!SupabaseConfig.isConfigured) {
      return this;
    }

    if (!_initialized) {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
    }
    return this;
  }

  Future<AuthResponse?> signIn(String email, String password) async {
    if (!isReady) return null;
    return _client!.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse?> signUp(String email, String password) async {
    if (!isReady) return null;
    return _client!.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    if (!isReady) return;
    await _client!.auth.signOut();
  }

  Future<List<NoteModel>> fetchNotes() async {
    if (!isReady) return [];
    final sw = Stopwatch()..start();
    final data = await _client!
        .from('notes')
        .select()
        .order('updated_at', ascending: false);
    sw.stop();
    debugPrint('Supabase read: ${sw.elapsedMilliseconds} ms');
    return (data as List<dynamic>)
        .map(
          (row) => NoteModel.fromMap(
            Map<String, dynamic>.from(row as Map<dynamic, dynamic>),
          ),
        )
        .map((note) => note.copyWith(synced: true))
        .toList();
  }

  Future<NoteModel?> upsertNote(NoteModel note, String userId) async {
    if (!isReady) return null;
    final sw = Stopwatch()..start();
    final payload = await _client!
        .from('notes')
        .upsert({
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'created_at': note.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'owner': userId,
        })
        .select()
        .single();
    sw.stop();
    debugPrint('Supabase write: ${sw.elapsedMilliseconds} ms');
    return NoteModel.fromMap(
      Map<String, dynamic>.from(payload as Map<dynamic, dynamic>),
    ).copyWith(synced: true);
  }

  Future<void> deleteNote(String id) async {
    if (!isReady) return;
    final sw = Stopwatch()..start();
    await _client!.from('notes').delete().eq('id', id);
    sw.stop();
    debugPrint('Supabase delete: ${sw.elapsedMilliseconds} ms');
  }

  void subscribeNotes(void Function(PostgresChangePayload payload) onChange) {
    if (!isReady) return;
    _notesChannel?.unsubscribe();
    _notesChannel = _client!.channel('public:notes')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notes',
        callback: onChange,
      )
      ..subscribe();
  }

  void disposeChannel() {
    _notesChannel?.unsubscribe();
    _notesChannel = null;
    _wishlistChannel?.unsubscribe();
    _wishlistChannel = null;
  }

  Future<List<WishlistItem>> fetchWishlist(String owner) async {
    if (!isReady) return [];
    final data = await _client!
        .from('wishlists')
        .select()
        .eq('owner', owner)
        .order('updated_at', ascending: false);
    return (data as List<dynamic>)
        .map(
          (row) => WishlistItem.fromMap(
            Map<String, dynamic>.from(row as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  Future<WishlistItem?> upsertWishlistItem(
    WishlistItem item,
    String owner,
  ) async {
    if (!isReady) return null;
    final payload = await _client!
        .from('wishlists')
        .upsert(item.toMap(owner: owner))
        .select()
        .single();
    return WishlistItem.fromMap(
      Map<String, dynamic>.from(payload as Map<dynamic, dynamic>),
    );
  }

  Future<void> deleteWishlistItem(String id) async {
    if (!isReady) return;
    await _client!.from('wishlists').delete().eq('id', id);
  }

  void subscribeWishlist(
    void Function(PostgresChangePayload payload) onChange,
  ) {
    if (!isReady) return;
    _wishlistChannel?.unsubscribe();
    _wishlistChannel = _client!.channel('public:wishlists')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'wishlists',
        callback: onChange,
      )
      ..subscribe();
  }
}
