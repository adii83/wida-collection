import 'package:hive/hive.dart';

class CapsulePlan {
  CapsulePlan({
    required this.id,
    required this.weekLabel,
    required this.top,
    required this.bottom,
    required this.outer,
    required this.accessories,
    required this.colorHex,
    required this.createdAt,
  });

  final String id;
  final String weekLabel;
  final String top;
  final String bottom;
  final String outer;
  final String accessories;
  final String colorHex;
  final DateTime createdAt;

  CapsulePlan copyWith({
    String? id,
    String? weekLabel,
    String? top,
    String? bottom,
    String? outer,
    String? accessories,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return CapsulePlan(
      id: id ?? this.id,
      weekLabel: weekLabel ?? this.weekLabel,
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      outer: outer ?? this.outer,
      accessories: accessories ?? this.accessories,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CapsulePlanAdapter extends TypeAdapter<CapsulePlan> {
  @override
  final int typeId = 3;

  @override
  CapsulePlan read(BinaryReader reader) {
    return CapsulePlan(
      id: reader.readString(),
      weekLabel: reader.readString(),
      top: reader.readString(),
      bottom: reader.readString(),
      outer: reader.readString(),
      accessories: reader.readString(),
      colorHex: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, CapsulePlan obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.weekLabel)
      ..writeString(obj.top)
      ..writeString(obj.bottom)
      ..writeString(obj.outer)
      ..writeString(obj.accessories)
      ..writeString(obj.colorHex)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
