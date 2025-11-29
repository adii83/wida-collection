import 'package:hive/hive.dart';

class CartItemModel {
  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  final String id;
  final String productId;
  final String name;
  final String image;
  final double price;
  int quantity;
  String ownerId;
  final DateTime createdAt;
  DateTime updatedAt;
  bool synced;

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? name,
    String? image,
    double? price,
    int? quantity,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price']?.toString() ?? '') ?? 0.0,
      quantity: (map['quantity'] is int)
          ? map['quantity'] as int
          : int.tryParse(map['quantity']?.toString() ?? '') ?? 1,
      ownerId: map['owner']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      synced: true,
    );
  }

  Map<String, dynamic> toMap({String? owner}) {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'owner': owner ?? ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class CartItemModelAdapter extends TypeAdapter<CartItemModel> {
  @override
  final int typeId = 2;

  @override
  CartItemModel read(BinaryReader reader) {
    final id = reader.readString();
    final productId = reader.readString();
    final name = reader.readString();
    final image = reader.readString();
    final price = reader.readDouble();
    final quantity = reader.readInt();
    final ownerId = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final synced = reader.readBool();
    return CartItemModel(
      id: id,
      productId: productId,
      name: name,
      image: image,
      price: price,
      quantity: quantity,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      synced: synced,
    );
  }

  @override
  void write(BinaryWriter writer, CartItemModel obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.productId)
      ..writeString(obj.name)
      ..writeString(obj.image)
      ..writeDouble(obj.price)
      ..writeInt(obj.quantity)
      ..writeString(obj.ownerId)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch)
      ..writeBool(obj.synced);
  }
}
