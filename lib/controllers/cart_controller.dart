import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/wishlist_item.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import 'auth_controller.dart';

class CartController extends GetxController {
  CartController(this._hiveService, this._supabaseService, this._auth);

  final HiveService _hiveService;
  final SupabaseService _supabaseService;
  final AuthController _auth;
  final _uuid = const Uuid();

  final items = <CartItemModel>[].obs;
  final isSyncing = false.obs;

  bool get canSync => _supabaseService.isReady && _auth.isLoggedIn;

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
      _supabaseService.subscribeCart((_) => syncFromCloud());
      pushLocalToCloud();
      syncFromCloud();
    } else {
      _supabaseService.disposeChannel();
    }
  }

  Future<void> loadLocal() async {
    final owner = _auth.currentUser.value?.id ?? HiveOwnerKeys.local;
    final data = _hiveService.readCart(owner: owner);
    items.assignAll(data);
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    final owner = _auth.currentUser.value?.id ?? HiveOwnerKeys.local;
    // Check existing
    CartItemModel? existing;
    for (final it in items) {
      if (it.productId == product.id && it.ownerId == owner) {
        existing = it;
        break;
      }
    }
    if (existing != null) {
      existing.quantity = (existing.quantity + quantity).clamp(1, 99);
      existing.updatedAt = DateTime.now();
      existing.synced = false;
      await _hiveService.saveCartItem(existing);
      items.refresh();
    } else {
      final now = DateTime.now();
      final item = CartItemModel(
        id: _uuid.v4(),
        productId: product.id,
        name: product.name,
        image: product.image,
        price: product.price,
        quantity: quantity,
        ownerId: owner,
        createdAt: now,
        updatedAt: now,
        synced: false,
      );
      await _hiveService.saveCartItem(item);
      await loadLocal();
    }

    if (canSync) {
      await pushLocalToCloud();
    }
  }

  Future<void> removeItem(String id) async {
    await _hiveService.deleteCartItem(id);
    items.removeWhere((i) => i.id == id);
    if (canSync) {
      await _supabaseService.deleteCartItem(id);
    }
  }

  Future<void> updateQuantity(String id, int quantity) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    items[idx].quantity = quantity.clamp(1, 99);
    items[idx].updatedAt = DateTime.now();
    items[idx].synced = false;
    await _hiveService.saveCartItem(items[idx]);
    items.refresh();
    if (canSync) {
      await pushLocalToCloud();
    }
  }

  double get subtotal => items.fold(0.0, (s, i) => s + i.price * i.quantity);

  Future<void> syncFromCloud() async {
    if (!canSync) return;
    try {
      isSyncing.value = true;
      final owner = _auth.currentUser.value!.id;
      final data = await _supabaseService.fetchCart(owner);
      // Save cloud items to local (mark as synced)
      for (final item in data) {
        final local = item.copyWith(synced: true, ownerId: owner);
        await _hiveService.saveCartItem(local);
      }
      items.assignAll(_hiveService.readCart(owner: owner));
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> pushLocalToCloud() async {
    if (!canSync) return;
    final owner = _auth.currentUser.value!.id;
    final localItems = _hiveService
        .readCart(owner: owner)
        .where((i) => !i.synced)
        .toList();
    for (final item in localItems) {
      try {
        final serverItem = await _supabaseService.upsertCartItem(item, owner);
        if (serverItem != null) {
          final updated = item.copyWith(
            id: serverItem.id,
            quantity: serverItem.quantity,
            updatedAt: serverItem.updatedAt,
            synced: true,
            ownerId: owner,
          );
          await _hiveService.saveCartItem(updated);
        }
      } catch (_) {
        // ignore and retry later
      }
    }
    // reload
    items.assignAll(_hiveService.readCart(owner: owner));
  }

  Future<void> clearCart() async {
    final owner = _auth.currentUser.value?.id ?? HiveOwnerKeys.local;
    // delete local
    final local = _hiveService.readCart(owner: owner);
    for (final it in local) {
      await _hiveService.deleteCartItem(it.id);
      if (canSync) {
        try {
          await _supabaseService.deleteCartItem(it.id);
        } catch (_) {}
      }
    }
    items.clear();
  }
}
