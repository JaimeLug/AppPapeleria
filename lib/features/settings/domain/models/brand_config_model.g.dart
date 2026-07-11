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
      backgroundColorHex: fields[5] as int?,
      surfaceColorHex: fields[6] as int?,
      sidebarColorHex: fields[7] as int?,
      dashReceivableColorHex: fields[8] as int?,
      dashIncomeColorHex: fields[9] as int?,
      dashExpenseColorHex: fields[10] as int?,
      dashNeutralColorHex: fields[11] as int?,
      dashNegativeColorHex: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, BrandConfigModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.appName)
      ..writeByte(1)
      ..write(obj.primaryColorHex)
      ..writeByte(2)
      ..write(obj.accentColorHex)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.logoBase64)
      ..writeByte(5)
      ..write(obj.backgroundColorHex)
      ..writeByte(6)
      ..write(obj.surfaceColorHex)
      ..writeByte(7)
      ..write(obj.sidebarColorHex)
      ..writeByte(8)
      ..write(obj.dashReceivableColorHex)
      ..writeByte(9)
      ..write(obj.dashIncomeColorHex)
      ..writeByte(10)
      ..write(obj.dashExpenseColorHex)
      ..writeByte(11)
      ..write(obj.dashNeutralColorHex)
      ..writeByte(12)
      ..write(obj.dashNegativeColorHex);
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
