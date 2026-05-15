// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'hadis_models.dart';

// ── SavedHadisAdapter ─────────────────────────────────────────────────────────

class SavedHadisAdapter extends TypeAdapter<SavedHadis> {
  @override
  final int typeId = 3;

  @override
  SavedHadis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedHadis(
      hadisId:    fields[0] as int,
      kitab:      fields[1] as String,
      arab:       fields[2] as String,
      terjemahan: fields[3] as String,
      sumber:     fields[4] as String,
      savedAt:    fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavedHadis obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.hadisId)
      ..writeByte(1)..write(obj.kitab)
      ..writeByte(2)..write(obj.arab)
      ..writeByte(3)..write(obj.terjemahan)
      ..writeByte(4)..write(obj.sumber)
      ..writeByte(5)..write(obj.savedAt);
  }
}

// ── CachedHadisHariIniAdapter ─────────────────────────────────────────────────

class CachedHadisHariIniAdapter extends TypeAdapter<CachedHadisHariIni> {
  @override
  final int typeId = 4;

  @override
  CachedHadisHariIni read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedHadisHariIni(
      kitabId:    fields[0] as String,
      nomorHadis: fields[1] as int,
      arab:       fields[2] as String,
      terjemahan: fields[3] as String,
      rawi:       fields[4] as String,
      sumber:     fields[5] as String,
      tanggal:    fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedHadisHariIni obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.kitabId)
      ..writeByte(1)..write(obj.nomorHadis)
      ..writeByte(2)..write(obj.arab)
      ..writeByte(3)..write(obj.terjemahan)
      ..writeByte(4)..write(obj.rawi)
      ..writeByte(5)..write(obj.sumber)
      ..writeByte(6)..write(obj.tanggal);
  }
}
