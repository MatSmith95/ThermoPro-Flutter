// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'temp_reading.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TempReadingAdapter extends TypeAdapter<TempReading> {
  @override
  final int typeId = 0;

  @override
  TempReading read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TempReading(
      timestamp: fields[0] as DateTime,
      internalTemp: fields[1] as double,
      ambientTemp: fields[2] as double,
      battery: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TempReading obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.internalTemp)
      ..writeByte(2)
      ..write(obj.ambientTemp)
      ..writeByte(3)
      ..write(obj.battery);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TempReadingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
