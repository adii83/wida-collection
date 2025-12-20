import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../models/note_model.dart';
import '../models/wishlist_item.dart';
import '../models/cart_item_model.dart';
import '../models/user_profile.dart';
import '../models/user_address.dart';
import '../models/order_model.dart';

class SupabaseService extends GetxService {
  SupabaseClient? _client;
  RealtimeChannel? _notesChannel;
  RealtimeChannel? _wishlistChannel;
  RealtimeChannel? _cartChannel;
  bool _initialized = false;

  SupabaseClient? get client => _client;
  bool get isReady => _initialized && _client != null;

  Stream<AuthState> get authStateChanges {
    if (!isReady) {
      return const Stream<AuthState>.empty();
    }
    return _client!.auth.onAuthStateChange;
  }

  /// Convenience getter for current authenticated user's id (nullable)
  String? get currentUserId => _client?.auth.currentUser?.id;

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

  Future<AuthResponse?> signUp(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    if (!isReady) return null;
    return _client!.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() async {
    if (!isReady) return;
    await _client!.auth.signOut();
  }

  // User profile helpers (profiles table)
  Future<UserProfile?> fetchProfile(String userId) async {
    if (!isReady) return null;
    final data = await _client!
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(
      Map<String, dynamic>.from(data as Map<dynamic, dynamic>),
    );
  }

  Future<UserProfile?> upsertProfile(UserProfile profile) async {
    if (!isReady) return null;
    final payload = await _client!
        .from('profiles')
        .upsert(profile.toMap())
        .select()
        .single();
    return UserProfile.fromMap(
      Map<String, dynamic>.from(payload as Map<dynamic, dynamic>),
    );
  }

  Future<void> updateFcmToken(String userId, String token) async {
    if (!isReady) return;
    await _client!
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
  }

  /// Resolve login identifier (email or username) to an email
  /// so we can still use Supabase's email+password auth.
  Future<String?> resolveEmailForLogin(String identifier) async {
    if (!isReady) return null;
    // If looks like an email, use it directly
    if (identifier.contains('@')) return identifier;

    // Otherwise treat as username and look up in profiles
    final data = await _client!
        .from('profiles')
        .select('email')
        .eq('username', identifier)
        .maybeSingle();

    if (data == null) return null;
    final map = Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
    return map['email'] as String?;
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

  // Storage
  Future<String?> uploadAvatar(File file, String path) async {
    if (!isReady) return null;
    try {
      final sw = Stopwatch()..start();
      await _client!.storage
          .from('avatars')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      sw.stop();
      debugPrint('Supabase upload: ${sw.elapsedMilliseconds} ms');

      final publicUrl = _client!.storage.from('avatars').getPublicUrl(path);
      // Hack: Add timestamp to force flutter to reload image if URL is same but content changed (though path usually unique)
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  Future<String?> uploadProductImage(
    File file, {
    required String productId,
  }) async {
    if (!isReady) return null;
    try {
      final ext = () {
        final p = file.path;
        final dot = p.lastIndexOf('.');
        if (dot == -1 || dot == p.length - 1) return '';
        final e = p.substring(dot).toLowerCase();
        // Basic allowlist
        if (e == '.jpg' || e == '.jpeg' || e == '.png' || e == '.webp')
          return e;
        return '';
      }();

      final contentType = () {
        switch (ext) {
          case '.png':
            return 'image/png';
          case '.webp':
            return 'image/webp';
          case '.jpg':
          case '.jpeg':
          default:
            return 'image/jpeg';
        }
      }();

      const bucket = 'product-images';
      final objectPath =
          'products/$productId/${const Uuid().v4()}${ext.isEmpty ? '.jpg' : ext}';

      final sw = Stopwatch()..start();
      await _client!.storage
          .from(bucket)
          .upload(
            objectPath,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: contentType,
            ),
          );
      sw.stop();
      debugPrint('Supabase upload: ${sw.elapsedMilliseconds} ms');

      final publicUrl = _client!.storage.from(bucket).getPublicUrl(objectPath);
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Upload product image failed: $e');
      return null;
    }
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
    _cartChannel?.unsubscribe();
    _cartChannel = null;
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

  Future<List<CartItemModel>> fetchCart(String owner) async {
    if (!isReady) return [];
    final data = await _client!
        .from('carts')
        .select()
        .eq('owner', owner)
        .order('updated_at', ascending: false);
    return (data as List<dynamic>)
        .map(
          (row) => CartItemModel.fromMap(
            Map<String, dynamic>.from(row as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  Future<CartItemModel?> upsertCartItem(
    CartItemModel item,
    String owner,
  ) async {
    if (!isReady) return null;
    final payload = await _client!
        .from('carts')
        .upsert(item.toMap(owner: owner))
        .select()
        .single();
    return CartItemModel.fromMap(
      Map<String, dynamic>.from(payload as Map<dynamic, dynamic>),
    );
  }

  Future<void> deleteCartItem(String id) async {
    if (!isReady) return;
    await _client!.from('carts').delete().eq('id', id);
  }

  void subscribeCart(void Function(PostgresChangePayload payload) onChange) {
    if (!isReady) return;
    _cartChannel?.unsubscribe();
    _cartChannel = _client!.channel('public:carts')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'carts',
        callback: onChange,
      )
      ..subscribe();
  }

  // User addresses (addresses table)
  Future<List<UserAddress>> fetchAddresses(String owner) async {
    if (!isReady) return [];
    final data = await _client!
        .from('addresses')
        .select()
        .eq('owner', owner)
        .order('is_default', ascending: false)
        .order('updated_at', ascending: false);
    return (data as List<dynamic>)
        .map(
          (row) => UserAddress.fromMap(
            Map<String, dynamic>.from(row as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  Future<UserAddress?> upsertAddress(UserAddress address, String owner) async {
    if (!isReady) return null;
    final payload = await _client!
        .from('addresses')
        .upsert(address.toMap(owner: owner))
        .select()
        .single();
    return UserAddress.fromMap(
      Map<String, dynamic>.from(payload as Map<dynamic, dynamic>),
    );
  }

  Future<void> deleteAddress(String id) async {
    if (!isReady) return;
    await _client!.from('addresses').delete().eq('id', id);
  }

  Future<void> setDefaultAddress(String id, String owner) async {
    if (!isReady) return;
    final client = _client!;
    await client
        .from('addresses')
        .update({'is_default': false})
        .eq('owner', owner);
    await client
        .from('addresses')
        .update({'is_default': true})
        .eq('id', id)
        .eq('owner', owner);
  }

  // Orders (orders table)
  Future<OrderModel?> createOrder(OrderModel order) async {
    if (!isReady) return null;
    final client = _client!;
    final payload = Map<String, dynamic>.from(order.toJson());

    // Your Supabase schema uses `owner` as UUID FK -> auth.users.
    // Ensure we always send a non-null UUID for `owner`.
    payload['owner'] ??= currentUserId;

    // Some schemas require a NOT NULL `invoice` column.
    // Use a UUID string which works for both TEXT and UUID column types.
    payload['invoice'] ??= const Uuid().v4();

    // If the database column `orders.id` is UUID, ensure we send a UUID.
    // Sending a UUID string is also compatible with TEXT ids.
    final id = payload['id'];
    if (id is String) {
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (!uuidRegex.hasMatch(id)) {
        payload['id'] = const Uuid().v4();
      }
    }

    try {
      final inserted = await client
          .from('orders')
          .insert(payload)
          .select()
          .single();
      return OrderModel.fromJson(
        Map<String, dynamic>.from(inserted as Map<dynamic, dynamic>),
      );
    } on PostgrestException catch (e) {
      // Common mismatch: database uses UUID for orders.id, but app sends 'ORDxxxxxx'
      final looksLikeUuidIdIssue =
          e.code == '22P02' &&
          ((e.message.toLowerCase().contains('uuid')) ||
              (e.details?.toString().toLowerCase().contains('uuid') ?? false));

      if (looksLikeUuidIdIssue) {
        // If DB expects UUID for `orders.id`, replace any non-UUID id with a UUID.
        final retryPayload = Map<String, dynamic>.from(payload);
        retryPayload['id'] = const Uuid().v4();
        final inserted = await client
            .from('orders')
            .insert(retryPayload)
            .select()
            .single();
        return OrderModel.fromJson(
          Map<String, dynamic>.from(inserted as Map<dynamic, dynamic>),
        );
      }
      rethrow;
    }
  }
}
