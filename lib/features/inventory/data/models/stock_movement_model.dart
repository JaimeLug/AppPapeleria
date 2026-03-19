import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'stock_movement_model.g.dart';

@HiveType(typeId: 7) // typeId must be unique across all adapters
class StockMovementModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String itemId;

  @HiveField(2)
  final String movementType; // "Entrada", "Salida", "Ajuste", "Mermas/Dañado"

  @HiveField(3)
  final double quantity; // Positive for inputs, negative for outputs

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String reason;

  @HiveField(6)
  final bool isItemDeleted;

  @HiveField(7)
  final bool isSynced;

  @HiveField(8)
  final DateTime updatedAt;

  StockMovementModel({
    String? id,
    required this.itemId,
    required this.movementType,
    required this.quantity,
    DateTime? date,
    required this.reason,
    this.isItemDeleted = false,
    this.isSynced = false,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  StockMovementModel copyWith({
    String? id,
    String? itemId,
    String? movementType,
    double? quantity,
    DateTime? date,
    String? reason,
    bool? isItemDeleted,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return StockMovementModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      isItemDeleted: isItemDeleted ?? this.isItemDeleted,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'],
      itemId: json['item_id'] ?? json['itemId'],
      movementType: json['movement_type'] ?? json['movementType'],
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      reason: json['reason'] ?? '',
      isItemDeleted: json['is_item_deleted'] ?? (json['isItemDeleted'] ?? false),
      isSynced: true,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'movement_type': movementType,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'reason': reason,
      'is_item_deleted': isItemDeleted,
      'is_synced': isSynced,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
