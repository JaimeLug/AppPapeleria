import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';

class SupabaseInventoryRepository {
  final SupabaseClient _supabase;

  SupabaseInventoryRepository(this._supabase);

  // --- Inventory Item Operations ---

  /// Stream en vivo (Realtime) de los ítems activos.
  Stream<List<InventoryItemModel>> watchItems() {
    return _supabase
        .from('inventory_items')
        .stream(primaryKey: ['id'])
        .eq('is_deleted', false)
        .map((data) => data.map((json) => _mapToItem(json)).toList());
  }

  Future<List<InventoryItemModel>> getAllItems() async {
    try {
      final response = await _supabase
          .from('inventory_items')
          .select()
          .eq('is_deleted', false);
      
      return response.map((json) => _mapToItem(json)).toList();
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al obtener inventario: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al obtener inventario: $e');
    }
  }

  Future<void> createItem(InventoryItemModel item) async {
    try {
      final data = _mapToTable(item);
      data['is_deleted'] = false;
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('inventory_items').upsert(data);
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al crear ítem de inventario: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al crear ítem de inventario: $e');
    }
  }

  Future<void> updateItem(InventoryItemModel item) async {
    try {
      final data = _mapToTable(item);
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('inventory_items').update(data).eq('id', item.id);
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al actualizar ítem: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar ítem: $e');
    }
  }

  Future<void> deleteItemLogically(String id) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('inventory_items').update({
        'is_deleted': true,
        'updated_at': now,
      }).eq('id', id);
      
      // Also mark movements as related to a deleted item if necessary
      await _supabase.from('stock_movements').update({
        'is_item_deleted': true,
      }).eq('item_id', id);
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al eliminar ítem (Soft Delete): ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar ítem (Soft Delete): $e');
    }
  }

  // --- Stock Movement Operations ---

  Future<List<StockMovementModel>> getAllMovements() async {
    try {
      final response = await _supabase
          .from('stock_movements')
          .select()
          .order('date', ascending: false);
      
      return response.map((json) => _mapToMovement(json)).toList();
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al obtener movimientos de stock: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al obtener movimientos de stock: $e');
    }
  }

  Future<void> adjustStock(String itemId, double quantity, String type, String reason, {String? movementId}) async {
    try {
      // 1. Get current stock
      final itemResponse = await _supabase
          .from('inventory_items')
          .select('current_stock')
          .eq('id', itemId)
          .maybeSingle();
      
      double currentStock = (itemResponse?['current_stock'] ?? 0.0).toDouble();
      
      // 2. Calculate new stock
      double quantityChange = quantity;
      if (type == 'Salida' || type == 'Mermas/Dañado') {
        quantityChange = -quantity.abs();
      } else if (type == 'Entrada') {
        quantityChange = quantity.abs();
      }
      
      final newStock = currentStock + quantityChange;

      // 3. Update stock and insert movement (Sequential)
      await _supabase.from('inventory_items').update({
        'current_stock': newStock,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', itemId);

      await _supabase.from('stock_movements').upsert({
        if (movementId != null) 'id': movementId,
        'item_id': itemId,
        'movement_type': type,
        'quantity': quantityChange,
        'reason': reason,
        'date': DateTime.now().toUtc().toIso8601String(),
        'is_item_deleted': false,
      });
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD en el ajuste de stock: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado en el ajuste de stock: $e');
    }
  }

  /// Sube (o actualiza) el registro de un movimiento SIN recalcular el stock.
  /// Se usa en el "guardado completo" para no duplicar ajustes de inventario:
  /// el stock ya viaja de forma autoritativa en `inventory_items.current_stock`.
  Future<void> upsertMovement(StockMovementModel movement) async {
    try {
      await _supabase.from('stock_movements').upsert({
        'id': movement.id,
        'item_id': movement.itemId,
        'movement_type': movement.movementType,
        'quantity': movement.quantity,
        'reason': movement.reason,
        'date': movement.date.toUtc().toIso8601String(),
        'is_item_deleted': movement.isItemDeleted,
      });
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al subir movimiento: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al subir movimiento: $e');
    }
  }

  // --- Mappers ---

  InventoryItemModel _mapToItem(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      itemType: json['item_type'] ?? 'Materia Prima',
      unitOfMeasure: json['unit_of_measure'] ?? 'Piezas',
      currentStock: (json['current_stock'] ?? 0.0).toDouble(),
      minimumStock: (json['minimum_stock'] ?? 0.0).toDouble(),
      unitCost: (json['unit_cost'] ?? 0.0).toDouble(),
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> _mapToTable(InventoryItemModel item) {
    return {
      'id': item.id,
      'name': item.name,
      'sku': item.sku,
      'item_type': item.itemType,
      'unit_of_measure': item.unitOfMeasure,
      'current_stock': item.currentStock,
      'minimum_stock': item.minimumStock,
      'unit_cost': item.unitCost,
    };
  }

  StockMovementModel _mapToMovement(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'],
      itemId: json['item_id'],
      movementType: json['movement_type'],
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date']),
      reason: json['reason'] ?? '',
      isItemDeleted: json['is_item_deleted'] ?? false,
    );
  }
}
