import 'package:hive/hive.dart';
import '../../domain/entities/order_item.dart';

part 'order_item_model.g.dart';

@HiveType(typeId: 2)
class OrderItemModel extends OrderItemEntity {
  @override
  @HiveField(0)
  final String productId;
  @override
  @HiveField(1)
  final String productName;
  @override
  @HiveField(2)
  final double price;
  @override
  @HiveField(3)
  final int quantity;
  @override
  @HiveField(4)
  final String? notes;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.notes,
  }) : super(
          productId: productId,
          productName: productName,
          price: price,
          quantity: quantity,
          notes: notes,
        );

  factory OrderItemModel.fromEntity(OrderItemEntity entity) {
    return OrderItemModel(
      productId: entity.productId,
      productName: entity.productName,
      price: entity.price,
      quantity: entity.quantity,
      notes: entity.notes,
    );
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['product_id'] ?? map['productId'] ?? '',
      productName: map['product_name'] ?? map['productName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'notes': notes,
    };
  }
}
