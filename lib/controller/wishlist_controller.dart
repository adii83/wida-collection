import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/wishlist_item.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import 'auth_controller.dart';

class WishlistController extends GetxController {
  WishlistController(this._hiveService, this._supabaseService, this._auth);

  final HiveService _hiveService;
  final SupabaseService _supabaseService;
  final AuthController _auth;
  final _uuid = const Uuid();

  final wishlist = <WishlistItem>[].obs;
  final isSyncing = false.obs;

  bool get canSync => _supabaseService.isReady && _auth.isLoggedIn;
  String get _activeOwner => _auth.currentUser.value?.id ?? HiveOwnerKeys.local;

  @override
  void onInit() {
    super.onInit();
    loadLocal();
    ever(_auth.currentUser, (_) => _handleAuthChange());
    _handleAuthChange();
  }

  void _handleAuthChange() {
    loadLocal();
    if (canSync) {
      _supabaseService.subscribeWishlist((_) => syncFromCloud());
      syncFromCloud();
    } else {
      _supabaseService.disposeChannel();
    }
  }

  Future<void> loadLocal() async {
    final data = _hiveService.readWishlist(owner: _activeOwner);
    wishlist.assignAll(data);
  }

  bool isFavorite(String productId) {
    return wishlist.any((item) => item.productId == productId);
  }

  Future<void> toggleWishlist(Product product) async {
    WishlistItem? existing;
    for (final item in wishlist) {
      if (item.productId == product.id) {
        existing = item;
        break;
      }
    }
    if (existing != null) {
      await _hiveService.deleteWishlistItem(existing.id);
      wishlist.remove(existing);
      if (canSync) {
        await _supabaseService.deleteWishlistItem(existing.id);
      }
      return;
    }

    final now = DateTime.now();
    final item = WishlistItem(
      id: _uuid.v4(),
      productId: product.id,
      name: product.name,
      image: product.image,
      price: product.price,
      ownerId: _activeOwner,
      createdAt: now,
      updatedAt: now,
      restockAlert: true,
      synced: false,
    );
    await _hiveService.saveWishlistItem(item);
    await loadLocal();
    if (canSync) {
      await _supabaseService.upsertWishlistItem(item, _activeOwner);
      await syncFromCloud();
    }
  }

  Future<void> syncFromCloud() async {
    if (!canSync) return;
    try {
      isSyncing.value = true;
      final data = await _supabaseService.fetchWishlist(_activeOwner);
      for (final item in data) {
        await _hiveService.saveWishlistItem(
          item.copyWith(synced: true, ownerId: _activeOwner),
        );
      }
      wishlist.assignAll(_hiveService.readWishlist(owner: _activeOwner));
    } finally {
      isSyncing.value = false;
    }
  }
}
