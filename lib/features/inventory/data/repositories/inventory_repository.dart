import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/google_cloud_service.dart';

class InventoryRepository {
  final Box<InventoryItemModel> _inventoryBox;
  final Box<StockMovementModel> _stockMovementsBox;

  InventoryRepository()
      : _inventoryBox = Hive.box<InventoryItemModel>('inventoryItems'),
        _stockMovementsBox = Hive.box<StockMovementModel>('stockMovements');

  // --- Inventory Item Operations ---

  Future<List<InventoryItemModel>> getAllItems() async {
    final rawList = _inventoryBox.values.toList();
    return rawList.where((item) => !item.isDeleted).toList();
  }

  InventoryItemModel? getItemById(String id) {
    return _inventoryBox.get(id);
  }

  Future<void> createItem(InventoryItemModel item) async {
    await _inventoryBox.put(item.id, item);
    await _syncItem(item);
  }

  Future<void> updateItem(InventoryItemModel item) async {
    await _inventoryBox.put(item.id, item);
    await _syncItem(item);
  }

  Future<void> deleteItemLogically(String id) async {
    final item = _inventoryBox.get(id);
    if (item != null) {
      final updatedItem = item.copyWith(isDeleted: true);
      await _inventoryBox.put(id, updatedItem);
      await _syncItem(updatedItem);
      
      final itemMovements = await getMovementsByItemId(id);
      for (var movement in itemMovements) {
        final updatedMovement = movement.copyWith(isItemDeleted: true);
        await _stockMovementsBox.put(updatedMovement.id, updatedMovement);
        // Note: we might not need to re-sync historical movements on item delete, 
        // but we can if desired. We will leave them as is in the cloud because 
        // they are history, or we could update them. Let's just keep cloud history.
      }
    }
  }

  // --- Stock Movement Operations ---

  Future<List<StockMovementModel>> getAllMovements() async {
    // We already get values, no heavy filtering here, but we can wrap it just in case
    return _stockMovementsBox.values.toList();
  }

  Future<List<StockMovementModel>> getMovementsByItemId(String itemId) async {
    final movements = _stockMovementsBox.values.toList();
    return movements.where((m) => m.itemId == itemId).toList();
  }

  // --- Atomic Adjustment ---

  /// Adjusts stock for an item and immediately records the movement.
  Future<void> adjustStock(String itemId, double quantity, String type, String reason) async {
    final item = _inventoryBox.get(itemId);
    if (item == null || item.isDeleted) {
      throw Exception('Ítem no encontrado o eliminado.');
    }

    double quantityChange = quantity;
    if (type == 'Salida' || type == 'Mermas/Dañado') {
      quantityChange = -quantity.abs();
    } else if (type == 'Entrada') {
      quantityChange = quantity.abs();
    }

    final newStock = item.currentStock + quantityChange;

    final movement = StockMovementModel(
      itemId: itemId,
      movementType: type,
      quantity: quantityChange,
      reason: reason,
      date: DateTime.now(),
    );

    item.currentStock = newStock;

    await _inventoryBox.put(item.id, item);
    await _stockMovementsBox.put(movement.id, movement);

    // Sync cloud
    await _syncItem(item);
    await _syncMovement(movement);
  }

  // --- Internal Google Cloud Sync Helpers ---

  Future<void> _syncItem(InventoryItemModel item) async {
    try {
      final settingsBox = Hive.box('settings');
      final settingsMap = settingsBox.get('appSettings');
      if (settingsMap != null) {
        final settings = Map<String, dynamic>.from(settingsMap);
        final googleService = GoogleCloudService();
        if (googleService.isAuthenticated && settings['syncSheetsEnabled'] == true && settings['googleSheetId'] != null) {
          await googleService.upsertInventoryItemInSheet(settings['googleSheetId'], item);
        }
      }
    } catch (e) {
      print('LOG: Error during Google Sync for InventoryItem: $e');
      throw Exception('Guardado LOCALMENTE, pero falló la subida de Inventario a Nube.');
    }
  }

  Future<void> _syncMovement(StockMovementModel movement) async {
    try {
      final settingsBox = Hive.box('settings');
      final settingsMap = settingsBox.get('appSettings');
      if (settingsMap != null) {
        final settings = Map<String, dynamic>.from(settingsMap);
        final googleService = GoogleCloudService();
        if (googleService.isAuthenticated && settings['syncSheetsEnabled'] == true && settings['googleSheetId'] != null) {
          await googleService.appendStockMovementToSheet(settings['googleSheetId'], movement);
        }
      }
    } catch (e) {
      print('LOG: Error during Google Sync for StockMovement: $e');
      throw Exception('Guardado LOCALMENTE, pero falló la subida de Movimiento a Nube.');
    }
  }
}
