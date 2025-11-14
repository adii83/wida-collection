import 'package:hive/hive.dart';

class LookbookEntry {
  LookbookEntry({
    required this.id,
    required this.title,
    required this.occasion,
    required this.mood,
    required this.notes,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String occasion;
  final String mood;
  final String notes;
  final String imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  LookbookEntry copyWith({
    String? id,
    String? title,
    String? occasion,
    String? mood,
    String? notes,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LookbookEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      occasion: occasion ?? this.occasion,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LookbookEntryAdapter extends TypeAdapter<LookbookEntry> {
  @override
  final int typeId = 2;

  @override
  LookbookEntry read(BinaryReader reader) {
    return LookbookEntry(
      id: reader.readString(),
      title: reader.readString(),
      occasion: reader.readString(),
      mood: reader.readString(),
      notes: reader.readString(),
      imagePath: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, LookbookEntry obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.occasion)
      ..writeString(obj.mood)
      ..writeString(obj.notes)
      ..writeString(obj.imagePath)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
