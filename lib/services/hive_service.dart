import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/wishlist_item.dart';
import '../models/cart_item_model.dart';

class HiveService extends GetxService {
  static const wishlistBoxName = 'wishlist_box';

  Box<WishlistItem>? _wishlistBox;
  Box<CartItemModel>? _cartBox;

  Future<HiveService> init() async {
    if (!Hive.isAdapterRegistered(WishlistItemAdapter().typeId)) {
      Hive.registerAdapter(WishlistItemAdapter());
    }
    _wishlistBox = await Hive.openBox<WishlistItem>(wishlistBoxName);

    if (!Hive.isAdapterRegistered(CartItemModelAdapter().typeId)) {
      Hive.registerAdapter(CartItemModelAdapter());
    }
    _cartBox = await Hive.openBox<CartItemModel>('cart_box');
    return this;
  }

  bool get isReady => _wishlistBox?.isOpen ?? false;

  List<WishlistItem> readWishlist({String? owner}) {
    final values = _wishlistBox?.values.toList() ?? [];
    final normalized =
        values
            .map(
              (item) => item.ownerId.isEmpty
                  ? item.copyWith(ownerId: HiveOwnerKeys.local)
                  : item,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (owner == null) {
      return normalized;
    }
    return normalized.where((item) => item.ownerId == owner).toList();
  }

  Future<void> saveWishlistItem(WishlistItem item) async {
    await _wishlistBox?.put(item.id, item);
  }

  Future<void> deleteWishlistItem(String id) async {
    await _wishlistBox?.delete(id);
  }

  Future<void> clearWishlist() async {
    await _wishlistBox?.clear();
  }

  // Cart related methods
  List<CartItemModel> readCart({String? owner}) {
    final values = _cartBox?.values.toList() ?? [];
    final normalized = values
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (owner == null) return normalized;
    return normalized.where((item) => item.ownerId == owner).toList();
  }

  Future<void> saveCartItem(CartItemModel item) async {
    await _cartBox?.put(item.id, item);
  }

  Future<void> deleteCartItem(String id) async {
    await _cartBox?.delete(id);
  }

  Future<void> clearCart() async {
    await _cartBox?.clear();
  }
}
