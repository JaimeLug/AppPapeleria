import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? notes;

  const OrderItemEntity({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.notes,
  });

  double get total => price * quantity;

  @override
  List<Object?> get props => [productId, productName, price, quantity, notes];

  OrderItemEntity copyWith({
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    String? notes,
  }) {
    return OrderItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}
