import '../../data/models/inventory_item_model.dart';
import '../../data/models/stock_movement_model.dart';

abstract class InventoryRepository {
  Future<List<InventoryItemModel>> getAllItems();
  Stream<List<InventoryItemModel>> watchItems();
  Future<void> createItem(InventoryItemModel item);
  Future<void> updateItem(InventoryItemModel item);
  Future<void> deleteItem(String id);
  Future<void> deleteItemLogically(String id);
  
  Future<List<StockMovementModel>> getAllMovements();
  Stream<List<StockMovementModel>> watchMovements();
  Future<void> adjustStock(String itemId, double quantity, String type, String reason, {String? movementId});
}
