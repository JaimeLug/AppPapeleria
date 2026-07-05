// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryItemModelAdapter extends TypeAdapter<InventoryItemModel> {
  @override
  final int typeId = 6;

  @override
  InventoryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryItemModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      sku: fields[2] as String?,
      itemType: fields[3] as String,
      unitOfMeasure: fields[4] as String,
      currentStock: fields[5] as double,
      minimumStock: fields[6] as double,
      unitCost: fields[7] as double,
      isDeleted: fields[8] as bool,
      isSynced: fields[9] as bool,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItemModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sku)
      ..writeByte(3)
      ..write(obj.itemType)
      ..writeByte(4)
      ..write(obj.unitOfMeasure)
      ..writeByte(5)
      ..write(obj.currentStock)
      ..writeByte(6)
      ..write(obj.minimumStock)
      ..writeByte(7)
      ..write(obj.unitCost)
      ..writeByte(8)
      ..write(obj.isDeleted)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
