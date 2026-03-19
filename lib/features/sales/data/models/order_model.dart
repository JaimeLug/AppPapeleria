import 'package:hive/hive.dart';
import '../../domain/entities/order.dart';
import 'order_item_model.dart';

part 'order_model.g.dart';

@HiveType(typeId: 0)
class OrderModel extends OrderEntity {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String customerName;
  @override
  @HiveField(2)
  final List<OrderItemModel> items;
  @override
  @HiveField(3)
  final double totalPrice;
  @override
  @HiveField(4)
  final double pendingBalance;
  @override
  @HiveField(5)
  final DateTime deliveryDate;
  @override
  @HiveField(6)
  final bool isSynced;
  @override
  @HiveField(7)
  final String status;
  @override
  @HiveField(8)
  final String paymentStatus;
  @override
  @HiveField(9)
  final String deliveryStatus;
  @override
  @HiveField(10)
  final DateTime? saleDate;
  @override
  @HiveField(11)
  final String? googleEventId;
  @override
  @HiveField(12)
  final String? notes;
  @override
  @HiveField(13)
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.customerName,
    required this.items,
    required this.totalPrice,
    required this.pendingBalance,
    required this.deliveryDate,
    this.isSynced = false,
    this.saleDate,
    this.status = 'Pendiente',
    this.paymentStatus = 'pending',
    this.deliveryStatus = 'pending',
    this.googleEventId,
    this.notes,
    required this.updatedAt,
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
          notes: notes,
          updatedAt: updatedAt,
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
      notes: entity.notes,
      updatedAt: DateTime.now(),
    );
  }

  @override
  OrderModel copyWith({
    String? id,
    String? customerName,
    covariant List<OrderItemModel>? items,
    double? totalPrice,
    double? pendingBalance,
    DateTime? deliveryDate,
    bool? isSynced,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
    DateTime? saleDate,
    String? googleEventId,
    String? notes,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      isSynced: isSynced ?? this.isSynced,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      saleDate: saleDate ?? this.saleDate,
      googleEventId: googleEventId ?? this.googleEventId,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
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
      status: map['status'] ?? 'Pendiente',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      deliveryStatus: map['deliveryStatus'] ?? 'pending',
      googleEventId: map['googleEventId'],
      notes: map['notes'],
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
          : DateTime.now(),
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
      'notes': notes,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      customerName: json['customer_name'] ?? json['Cliente'] ?? '',
      items: (json['items'] as List?)?.map((e) => OrderItemModel.fromMap(e)).toList() ?? [], 
      totalPrice: (json['total_price'] ?? json['Total'] ?? 0.0).toDouble(),
      pendingBalance: (json['pending_balance'] ?? json['Saldo'] ?? 0.0).toDouble(),
      deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : DateTime.now(),
      isSynced: true,
      saleDate: json['sale_date'] != null ? DateTime.parse(json['sale_date']) : null,
      status: json['status'] ?? 'Pendiente',
      paymentStatus: json['payment_status'] ?? 'pending',
      deliveryStatus: json['delivery_status'] ?? 'pending',
      googleEventId: json['google_event_id'],
      notes: json['notes'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'total_price': totalPrice,
      'pending_balance': pendingBalance,
      'delivery_date': deliveryDate.toIso8601String(), 
      'sale_date': saleDate?.toIso8601String(),
      'status': status,
      'payment_status': paymentStatus,
      'delivery_status': deliveryStatus,
      'notes': notes ?? '',
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
