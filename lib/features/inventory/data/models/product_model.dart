import 'package:hive/hive.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@HiveType(typeId: 1)
class ProductModel extends ProductEntity {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final double basePrice;
  @override
  @HiveField(3)
  final double extraCost;
  @override
  @HiveField(4)
  final String category;
  @override
  @HiveField(5)
  final String? notes;
  @HiveField(6)
  final bool isSynced;
  @HiveField(7)
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.extraCost,
    required this.category,
    this.notes,
    this.isSynced = false,
    required this.updatedAt,
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
      isSynced: false,
      updatedAt: DateTime.now(),
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? basePrice,
    double? extraCost,
    String? category,
    String? notes,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      extraCost: extraCost ?? this.extraCost,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      basePrice: (json['base_price'] ?? (json['basePrice'] ?? 0.0)).toDouble(),
      extraCost: (json['extra_cost'] ?? (json['extraCost'] ?? 0.0)).toDouble(),
      category: json['category'] ?? 'Sin Categoría',
      notes: json['notes'],
      isSynced: true,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'base_price': basePrice,
      'extra_cost': extraCost,
      'category': category,
      'notes': notes,
      'isSynced': isSynced,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
