// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'quran_models.dart';

// ── QuranBookmarkAdapter ──────────────────────────────────────────────────────

class QuranBookmarkAdapter extends TypeAdapter<QuranBookmark> {
  @override
  final int typeId = 1;

  @override
  QuranBookmark read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuranBookmark(
      surahNumber: fields[0] as int,
      ayahNumber:  fields[1] as int,
      surahName:   fields[2] as String,
      savedAt:     fields[3] as DateTime,
      note:        fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QuranBookmark obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.surahNumber)
      ..writeByte(1)
      ..write(obj.ayahNumber)
      ..writeByte(2)
      ..write(obj.surahName)
      ..writeByte(3)
      ..write(obj.savedAt)
      ..writeByte(4)
      ..write(obj.note);
  }
}

// ── LastReadAdapter ───────────────────────────────────────────────────────────

class LastReadAdapter extends TypeAdapter<LastRead> {
  @override
  final int typeId = 2;

  @override
  LastRead read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LastRead(
      surahNumber: fields[0] as int,
      ayahNumber:  fields[1] as int,
      surahName:   fields[2] as String,
      readAt:      fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LastRead obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.surahNumber)
      ..writeByte(1)
      ..write(obj.ayahNumber)
      ..writeByte(2)
      ..write(obj.surahName)
      ..writeByte(3)
      ..write(obj.readAt);
  }
}
