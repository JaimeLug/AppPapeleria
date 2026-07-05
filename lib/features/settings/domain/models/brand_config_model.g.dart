// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand_config_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BrandConfigModelAdapter extends TypeAdapter<BrandConfigModel> {
  @override
  final int typeId = 8;

  @override
  BrandConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrandConfigModel(
      appName: fields[0] as String,
      primaryColorHex: fields[1] as int,
      accentColorHex: fields[2] as int,
      updatedAt: fields[3] as DateTime,
      logoBase64: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BrandConfigModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.appName)
      ..writeByte(1)
      ..write(obj.primaryColorHex)
      ..writeByte(2)
      ..write(obj.accentColorHex)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.logoBase64);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
