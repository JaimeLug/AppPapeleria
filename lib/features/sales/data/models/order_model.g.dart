// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderModelAdapter extends TypeAdapter<OrderModel> {
  @override
  final int typeId = 0;

  @override
  OrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderModel(
      id: fields[0] as String,
      customerName: fields[1] as String,
      items: (fields[2] as List).cast<OrderItemModel>(),
      totalPrice: fields[3] as double,
      pendingBalance: fields[4] as double,
      deliveryDate: fields[5] as DateTime,
      isSynced: fields[6] as bool,
      saleDate: fields[10] as DateTime?,
      status: fields[7] as String,
      paymentStatus: fields[8] as String,
      deliveryStatus: fields[9] as String,
      googleEventId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerName)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.totalPrice)
      ..writeByte(4)
      ..write(obj.pendingBalance)
      ..writeByte(5)
      ..write(obj.deliveryDate)
      ..writeByte(6)
      ..write(obj.isSynced)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.paymentStatus)
      ..writeByte(9)
      ..write(obj.deliveryStatus)
      ..writeByte(10)
      ..write(obj.saleDate)
      ..writeByte(11)
      ..write(obj.googleEventId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
