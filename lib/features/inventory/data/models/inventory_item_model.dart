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
  bool isDeleted; // Optional boolean to handle logical deletion

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
  }) : id = id ?? const Uuid().v4();

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
    );
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      itemType: json['itemType'],
      unitOfMeasure: json['unitOfMeasure'],
      currentStock: (json['currentStock'] ?? 0.0).toDouble(),
      minimumStock: (json['minimumStock'] ?? 0.0).toDouble(),
      unitCost: (json['unitCost'] ?? 0.0).toDouble(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'itemType': itemType,
      'unitOfMeasure': unitOfMeasure,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'unitCost': unitCost,
      'isDeleted': isDeleted,
    };
  }
}
