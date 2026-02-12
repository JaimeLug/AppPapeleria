import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/order.dart';
import 'order_item_model.dart';
import '../../domain/entities/order_item.dart';

part 'order_model.g.dart';

@HiveType(typeId: 0)
class OrderModel extends OrderEntity {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String customerName;
  @HiveField(2)
  final List<OrderItemModel> items;
  @HiveField(3)
  final double totalPrice;
  @HiveField(4)
  final double pendingBalance;
  @HiveField(5)
  final DateTime deliveryDate;
  @HiveField(6)
  final bool isSynced;
  @HiveField(7)
  final String status;
  @HiveField(8)
  final String paymentStatus;
  @HiveField(9)
  final String deliveryStatus;
  @HiveField(10)
  final DateTime? saleDate;
  @HiveField(11)
  final String? googleEventId;

  const OrderModel({
    required this.id,
    required this.customerName,
    required this.items,
    required this.totalPrice,
    required this.pendingBalance,
    required this.deliveryDate,
    required this.isSynced,
    this.saleDate,
    this.status = 'Diseño',
    this.paymentStatus = 'pending',
    this.deliveryStatus = 'pending',
    this.googleEventId,
  }) : super(
          id: id,
          customerName: customerName,
          items: items,
          totalPrice: totalPrice,
          pendingBalance: pendingBalance,
          deliveryDate: deliveryDate,
          isSynced: isSynced,
          saleDate: saleDate,
          status: status,
          paymentStatus: paymentStatus,
          deliveryStatus: deliveryStatus,
          googleEventId: googleEventId,
        );

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      customerName: entity.customerName,
      items: entity.items.map((e) => OrderItemModel.fromEntity(e)).toList(),
      totalPrice: entity.totalPrice,
      pendingBalance: entity.pendingBalance,
      deliveryDate: entity.deliveryDate,
      isSynced: entity.isSynced,
      saleDate: entity.saleDate,
      status: entity.status,
      paymentStatus: entity.paymentStatus,
      deliveryStatus: entity.deliveryStatus,
      googleEventId: entity.googleEventId,
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      items: List<OrderItemModel>.from(
          (map['items'] ?? []).map((x) => OrderItemModel.fromMap(x))),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      pendingBalance: (map['pendingBalance'] ?? 0.0).toDouble(),
      deliveryDate: DateTime.fromMillisecondsSinceEpoch(map['deliveryDate']),
      isSynced: map['isSynced'] ?? false,
      saleDate: map['saleDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['saleDate']) 
          : null,
      status: map['status'] ?? 'Diseño',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      deliveryStatus: map['deliveryStatus'] ?? 'pending',
      googleEventId: map['googleEventId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'items': items.map((x) => x.toMap()).toList(),
      'totalPrice': totalPrice,
      'pendingBalance': pendingBalance,
      'deliveryDate': deliveryDate.millisecondsSinceEpoch,
      'isSynced': isSynced,
      'saleDate': saleDate?.millisecondsSinceEpoch,
      'status': status,
      'paymentStatus': paymentStatus,
      'deliveryStatus': deliveryStatus,
      'googleEventId': googleEventId,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['ID'] ?? '',
      customerName: json['Cliente'] ?? '',
      items: [], 
      totalPrice: double.tryParse(json['Total']?.toString() ?? '0') ?? 0.0,
      pendingBalance: double.tryParse(json['Saldo']?.toString() ?? '0') ?? 0.0,
      deliveryDate: DateTime.tryParse(json['Fecha Entrega'] ?? '') ?? DateTime.now(),
      isSynced: true,
      saleDate: DateTime.tryParse(json['Fecha Venta'] ?? ''),
      status: json['Estado'] ?? 'Diseño',
      paymentStatus: 'pending', 
      deliveryStatus: 'pending',
      googleEventId: null,
    );
  }

  Map<String, dynamic> toJson() {
    final productsSummary = items.map((e) => '${e.quantity}x ${e.productName}').join(', ');
    return {
      'ID': id,
      'Cliente': customerName,
      'Productos': productsSummary,
      'Total': totalPrice,
      'Saldo': pendingBalance,
      'Fecha Entrega': deliveryDate.toIso8601String().split('T')[0], 
      'Fecha Venta': saleDate?.toIso8601String().split('T')[0],
      'Sincronizado': isSynced ? 'Si' : 'No',
      'Estado': status,
      'EstatusPago': paymentStatus,
      'EstatusEntrega': deliveryStatus,
    };
  }
}
