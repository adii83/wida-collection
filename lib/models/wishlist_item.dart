import 'package:hive/hive.dart';

class WishlistItem {
  WishlistItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    this.ownerId = HiveOwnerKeys.local,
    this.restockAlert = false,
    this.synced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String productId;
  final String name;
  final String image;
  final double price;
  final String ownerId;
  final bool restockAlert;
  final bool synced;
  final DateTime createdAt;
  final DateTime updatedAt;

  WishlistItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? image,
    double? price,
    String? ownerId,
    bool? restockAlert,
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      ownerId: ownerId ?? this.ownerId,
      restockAlert: restockAlert ?? this.restockAlert,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price']?.toString() ?? '') ?? 0,
      ownerId: map['owner']?.toString().isNotEmpty == true
          ? map['owner'].toString()
          : HiveOwnerKeys.local,
      restockAlert: map['restock_alert'] == true,
      synced: true,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({String? owner}) {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'image': image,
      'price': price,
      'restock_alert': restockAlert,
      'owner': owner ?? ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class WishlistItemAdapter extends TypeAdapter<WishlistItem> {
  @override
  final int typeId = 1;

  @override
  WishlistItem read(BinaryReader reader) {
    return WishlistItem(
      id: reader.readString(),
      productId: reader.readString(),
      name: reader.readString(),
      image: reader.readString(),
      price: reader.readDouble(),
      restockAlert: reader.readBool(),
      synced: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      ownerId: _readOwner(reader),
    );
  }

  @override
  void write(BinaryWriter writer, WishlistItem obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.productId)
      ..writeString(obj.name)
      ..writeString(obj.image)
      ..writeDouble(obj.price)
      ..writeBool(obj.restockAlert)
      ..writeBool(obj.synced)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch)
      ..writeString(obj.ownerId);
  }

  static String _readOwner(BinaryReader reader) {
    try {
      if (reader.availableBytes <= 0) {
        return HiveOwnerKeys.local;
      }
      final value = reader.readString();
      return value.isEmpty ? HiveOwnerKeys.local : value;
    } catch (_) {
      return HiveOwnerKeys.local;
    }
  }
}

class HiveOwnerKeys {
  static const local = 'local';
}
