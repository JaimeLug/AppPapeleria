import 'package:hive/hive.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@HiveType(typeId: 1)
class ProductModel extends ProductEntity {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double basePrice;
  @HiveField(3)
  final double extraCost;
  @HiveField(4)
  final String category;
  @HiveField(5)
  final String? notes;

  const ProductModel({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.extraCost,
    required this.category,
    this.notes,
  }) : super(
          id: id,
          name: name,
          basePrice: basePrice,
          extraCost: extraCost,
          category: category,
          notes: notes,
        );

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      basePrice: entity.basePrice,
      extraCost: entity.extraCost,
      category: entity.category,
      notes: entity.notes,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      extraCost: (json['extraCost'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'Sin Categoría',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'basePrice': basePrice,
      'extraCost': extraCost,
      'category': category,
      'notes': notes,
    };
  }
}
