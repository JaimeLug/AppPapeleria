import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';
import 'supabase_inventory_repository.dart';
import '../../../../core/services/sync_manager.dart';

class OfflineFirstInventoryRepository implements InventoryRepository {
  final SupabaseInventoryRepository _remoteRepo;
  final Box<InventoryItemModel> _itemBox;
  final Box<StockMovementModel> _movementBox;
  final SyncManager _syncManager;

  OfflineFirstInventoryRepository(
    this._remoteRepo,
    this._itemBox,
    this._movementBox,
    this._syncManager,
  );

  @override
  Future<List<InventoryItemModel>> getAllItems() async {
    final local = _itemBox.values.where((i) => !i.isDeleted).toList();
    _fetchRemoteItems();
    return local;
  }

  @override
  Stream<List<InventoryItemModel>> watchItems() async* {
    _fetchRemoteItems(); // Background fetch
    yield _itemBox.values.where((i) => !i.isDeleted).toList();
    await for (final _ in _itemBox.watch()) {
      yield _itemBox.values.where((i) => !i.isDeleted).toList();
    }
  }

  @override
  Stream<List<StockMovementModel>> watchMovements() async* {
    _fetchRemoteMovements(); // Background fetch
    yield _movementBox.values.toList();
    await for (final _ in _movementBox.watch()) {
      yield _movementBox.values.toList();
    }
  }

  Future<void> _fetchRemoteMovements() async {
    try {
      final remote = await _remoteRepo.getAllMovements();
      for (var movement in remote) {
        final local = _movementBox.get(movement.id);
        if (local == null || movement.updatedAt.isAfter(local.updatedAt)) {
          await _movementBox.put(movement.id, movement);
        }
      }
    } catch (e) {
      debugPrint('Error en fetch remoto de movimientos: $e');
    }
  }

  Future<void> _fetchRemoteItems() async {
    try {
      final remote = await _remoteRepo.getAllItems();
      for (var item in remote) {
        final local = _itemBox.get(item.id);
        if (local == null || item.updatedAt.isAfter(local.updatedAt)) {
          await _itemBox.put(item.id, item);
        }
      }
    } catch (e) {
      debugPrint('Error en fetch remoto de ítems: $e');
    }
  }

  @override
  Future<void> createItem(InventoryItemModel item) async {
    final model = item.copyWith(isSynced: false, updatedAt: DateTime.now());
    await _itemBox.put(model.id, model);
    _syncManager.syncPendingData();
  }

  @override
  Future<void> updateItem(InventoryItemModel item) async {
    await createItem(item);
  }

  @override
  Future<void> deleteItem(String id) async {
    await _itemBox.delete(id);
    // Ideally we should also call remote hard delete if that's the intention,
    // but usually in this app we prefer logical delete.
  }

  @override
  Future<void> deleteItemLogically(String id) async {
    final local = _itemBox.get(id);
    if (local != null) {
      final updated = local.copyWith(isDeleted: true, updatedAt: DateTime.now(), isSynced: false);
      await _itemBox.put(id, updated);
      _syncManager.syncPendingData();
    }
    await _remoteRepo.deleteItemLogically(id);
  }

  @override
  Future<List<StockMovementModel>> getAllMovements() async {
    return _movementBox.values.toList();
  }

  @override
  Future<void> adjustStock(String itemId, double quantity, String type, String reason, {String? movementId}) async {
    final item = _itemBox.get(itemId);
    if (item == null) return;

    // 1. Optimistic Stock Update
    double change = (type == 'Salida' || type == 'Mermas/Dañado') ? -quantity.abs() : quantity.abs();
    final updatedItem = item.copyWith(
      currentStock: item.currentStock + change,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _itemBox.put(itemId, updatedItem);

    // 2. Local Movement Record
    final movement = StockMovementModel(
      id: movementId,
      itemId: itemId,
      movementType: type,
      quantity: change,
      reason: reason,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _movementBox.put(movement.id, movement);

    // 3. Trigger Sync (Passing the same ID to the remote repo)
    try {
      await _remoteRepo.adjustStock(
        itemId, 
        quantity.abs(), 
        type, 
        reason, 
        movementId: movement.id
      );
      // If immediate sync succeeds, mark as synced
      await _movementBox.put(movement.id, movement.copyWith(isSynced: true));
    } catch (e) {
      debugPrint('Sync failed, will retry later: $e');
      _syncManager.syncPendingData();
    }
  }
}
