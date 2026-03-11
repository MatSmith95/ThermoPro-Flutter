// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProbeHistoryAdapter extends TypeAdapter<ProbeHistory> {
  @override
  final int typeId = 2;

  @override
  ProbeHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProbeHistory(
      probeId: fields[0] as String,
      probeName: fields[1] as String,
      readings: (fields[2] as List).cast<TempReading>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProbeHistory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.probeId)
      ..writeByte(1)
      ..write(obj.probeName)
      ..writeByte(2)
      ..write(obj.readings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProbeHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProbeSettingsAdapter extends TypeAdapter<ProbeSettings> {
  @override
  final int typeId = 3;

  @override
  ProbeSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProbeSettings(
      probeId: fields[0] as String,
      targetInternal: fields[1] as double?,
      targetAmbient: fields[2] as double?,
      colorValue: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProbeSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.probeId)
      ..writeByte(1)
      ..write(obj.targetInternal)
      ..writeByte(2)
      ..write(obj.targetAmbient)
      ..writeByte(3)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProbeSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CookSessionAdapter extends TypeAdapter<CookSession> {
  @override
  final int typeId = 4;

  @override
  CookSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CookSession(
      id: fields[0] as String,
      name: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime?,
      probeHistories: (fields[4] as List).cast<ProbeHistory>(),
      probeSettings: (fields[5] as List).cast<ProbeSettings>(),
    );
  }

  @override
  void write(BinaryWriter writer, CookSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.probeHistories)
      ..writeByte(5)
      ..write(obj.probeSettings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
