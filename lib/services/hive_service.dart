import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/note_model.dart';
import '../models/wishlist_item.dart';
import '../models/lookbook_entry.dart';
import '../models/capsule_plan.dart';

class HiveService extends GetxService {
  static const notesBoxName = 'local_notes_box';
  static const wishlistBoxName = 'wishlist_box';
  static const lookbookBoxName = 'lookbook_box';
  static const capsuleBoxName = 'capsule_box';

  Box<NoteModel>? _notesBox;
  Box<WishlistItem>? _wishlistBox;
  Box<LookbookEntry>? _lookbookBox;
  Box<CapsulePlan>? _capsuleBox;

  Future<HiveService> init() async {
    if (!Hive.isAdapterRegistered(NoteModelAdapter().typeId)) {
      Hive.registerAdapter(NoteModelAdapter());
    }
    if (!Hive.isAdapterRegistered(WishlistItemAdapter().typeId)) {
      Hive.registerAdapter(WishlistItemAdapter());
    }
    if (!Hive.isAdapterRegistered(LookbookEntryAdapter().typeId)) {
      Hive.registerAdapter(LookbookEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(CapsulePlanAdapter().typeId)) {
      Hive.registerAdapter(CapsulePlanAdapter());
    }
    _notesBox = await Hive.openBox<NoteModel>(notesBoxName);
    _wishlistBox = await Hive.openBox<WishlistItem>(wishlistBoxName);
    _lookbookBox = await Hive.openBox<LookbookEntry>(lookbookBoxName);
    _capsuleBox = await Hive.openBox<CapsulePlan>(capsuleBoxName);
    return this;
  }

  bool get isReady => _notesBox?.isOpen ?? false;

  List<NoteModel> readNotes() {
    final values = _notesBox?.values.toList() ?? [];
    values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  Future<void> saveNote(NoteModel note) async {
    await _notesBox?.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _notesBox?.delete(id);
  }

  Future<void> clear() async {
    await _notesBox?.clear();
  }

  List<WishlistItem> readWishlist() {
    final values = _wishlistBox?.values.toList() ?? [];
    values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
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

  List<LookbookEntry> readLookbook() {
    final values = _lookbookBox?.values.toList() ?? [];
    values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  Future<void> saveLookbookEntry(LookbookEntry entry) async {
    await _lookbookBox?.put(entry.id, entry);
  }

  Future<void> deleteLookbookEntry(String id) async {
    await _lookbookBox?.delete(id);
  }

  List<CapsulePlan> readCapsulePlans() {
    final values = _capsuleBox?.values.toList() ?? [];
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<void> saveCapsulePlan(CapsulePlan plan) async {
    await _capsuleBox?.put(plan.id, plan);
  }

  Future<void> deleteCapsulePlan(String id) async {
    await _capsuleBox?.delete(id);
  }
}
