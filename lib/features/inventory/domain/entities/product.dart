import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final double basePrice;
  final double extraCost; // Costo de extras
  final String category;
  final String? notes;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.extraCost,
    required this.category,
    this.notes,
  });

  @override
  List<Object?> get props => [id, name, basePrice, extraCost, category, notes];
}
