import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/wishlist_item.dart';
import '../models/cart_item_model.dart';
import '../models/note_model.dart';

class HiveService extends GetxService {
  static const wishlistBoxName = 'wishlist_box';
  static const notesBoxName = 'notes_box';

  Box<WishlistItem>? _wishlistBox;
  Box<CartItemModel>? _cartBox;
  Box<NoteModel>? _notesBox;

  Future<HiveService> init() async {
    if (!Hive.isAdapterRegistered(WishlistItemAdapter().typeId)) {
      Hive.registerAdapter(WishlistItemAdapter());
    }
    _wishlistBox = await Hive.openBox<WishlistItem>(wishlistBoxName);

    if (!Hive.isAdapterRegistered(CartItemModelAdapter().typeId)) {
      Hive.registerAdapter(CartItemModelAdapter());
    }
    _cartBox = await Hive.openBox<CartItemModel>('cart_box');

    if (!Hive.isAdapterRegistered(NoteModelAdapter().typeId)) {
      Hive.registerAdapter(NoteModelAdapter());
    }
    _notesBox = await Hive.openBox<NoteModel>(notesBoxName);
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

  // Notes related methods (per owner key)
  String _noteKey(String owner, String id) => '$owner::$id';

  List<NoteModel> readNotes({required String owner}) {
    if (_notesBox == null) return [];
    final result = <NoteModel>[];
    for (final key in _notesBox!.keys) {
      if (key is String && key.startsWith('$owner::')) {
        final value = _notesBox!.get(key);
        if (value != null) {
          result.add(value);
        }
      }
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Future<void> saveNote(String owner, NoteModel note) async {
    await _notesBox?.put(_noteKey(owner, note.id), note);
  }

  Future<void> deleteNote(String owner, String id) async {
    await _notesBox?.delete(_noteKey(owner, id));
  }

  Future<void> clearNotes(String owner) async {
    if (_notesBox == null) return;
    final keys = _notesBox!.keys
        .whereType<String>()
        .where((k) => k.startsWith('$owner::'))
        .toList();
    await _notesBox!.deleteAll(keys);
  }
}
