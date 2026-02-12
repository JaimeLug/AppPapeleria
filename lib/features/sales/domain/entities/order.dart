import 'package:equatable/equatable.dart';
import 'order_item.dart';

class OrderEntity extends Equatable {
  final String id;
  final String customerName;
  final List<OrderItemEntity> items;
  final double totalPrice;
  final double pendingBalance;
  final DateTime deliveryDate;
  final bool isSynced;
  final DateTime? saleDate; // Date of the transaction (nullable for backward compatibility)
  final String status; // Deprecated, use deliveryStatus
  final String paymentStatus; // paid, pending
  final String deliveryStatus; // pending, delivered, cancelled
  final String? googleEventId; // Google Calendar event ID for sync

  const OrderEntity({
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
  });

  OrderEntity copyWith({
    String? id,
    String? customerName,
    List<OrderItemEntity>? items,
    double? totalPrice,
    double? pendingBalance,
    DateTime? deliveryDate,
    bool? isSynced,
    DateTime? saleDate,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
    String? googleEventId,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      isSynced: isSynced ?? this.isSynced,
      saleDate: saleDate ?? this.saleDate,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      googleEventId: googleEventId ?? this.googleEventId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerName,
        items,
        totalPrice,
        pendingBalance,
        deliveryDate,
        isSynced,
        saleDate,
        status,
        paymentStatus,
        deliveryStatus,
        googleEventId,
      ];
}
