import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'inventory_item_model.g.dart';

@HiveType(typeId: 6) // typeId must be unique across all adapters
class InventoryItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? sku;

  @HiveField(3)
  final String itemType; // "Materia Prima", "Producto Terminado", "Insumo/Empaque"

  @HiveField(4)
  final String unitOfMeasure; // "Piezas", "Metros", "Paquetes", "Litros"

  @HiveField(5)
  double currentStock;

  @HiveField(6)
  final double minimumStock;

  @HiveField(7)
  final double unitCost;

  @HiveField(8)
  bool isDeleted;

  @HiveField(9)
  final bool isSynced;

  @HiveField(10)
  final DateTime updatedAt;

  InventoryItemModel({
    String? id,
    required this.name,
    this.sku,
    required this.itemType,
    required this.unitOfMeasure,
    this.currentStock = 0.0,
    this.minimumStock = 0.0,
    this.unitCost = 0.0,
    this.isDeleted = false,
    this.isSynced = false,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? sku,
    String? itemType,
    String? unitOfMeasure,
    double? currentStock,
    double? minimumStock,
    double? unitCost,
    bool? isDeleted,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      itemType: itemType ?? this.itemType,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      unitCost: unitCost ?? this.unitCost,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      itemType: json['item_type'] ?? json['itemType'],
      unitOfMeasure: json['unit_of_measure'] ?? json['unitOfMeasure'],
      currentStock: (json['current_stock'] ?? (json['currentStock'] ?? 0.0)).toDouble(),
      minimumStock: (json['minimum_stock'] ?? (json['minimumStock'] ?? 0.0)).toDouble(),
      unitCost: (json['unit_cost'] ?? (json['unitCost'] ?? 0.0)).toDouble(),
      isDeleted: json['is_deleted'] ?? (json['isDeleted'] ?? false),
      isSynced: true,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'item_type': itemType,
      'unit_of_measure': unitOfMeasure,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'unit_cost': unitCost,
      'is_deleted': isDeleted,
      'is_synced': isSynced,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
