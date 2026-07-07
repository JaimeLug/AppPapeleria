import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/offline_first_inventory_repository.dart';
import '../../data/models/stock_movement_model.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/providers/remote_repositories_providers.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final itemBox = Hive.box<InventoryItemModel>('inventoryItems');
  final movementBox = Hive.box<StockMovementModel>('stockMovements');
  final remoteRepo = ref.watch(remoteInventoryRepositoryProvider);
  final syncManager = ref.watch(syncManagerProvider);

  return OfflineFirstInventoryRepository(
    remoteRepo,
    itemBox,
    movementBox,
    syncManager,
  );
});

// Stream Provider for reactive UI updates (Items)
final inventoryItemsStreamProvider = StreamProvider<List<InventoryItemModel>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchItems();
});

// Stream Provider for reactive UI updates (Movements)
final stockMovementsStreamProvider = StreamProvider<List<StockMovementModel>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchMovements();
});

// Provides the list of all active items
final inventoryItemsProvider = StateNotifierProvider<InventoryItemsNotifier, List<InventoryItemModel>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return InventoryItemsNotifier(repository);
});

class InventoryItemsNotifier extends StateNotifier<List<InventoryItemModel>> {
  final InventoryRepository _repository;

  InventoryItemsNotifier(this._repository) : super([]) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = await _repository.getAllItems();
  }

  Future<void> addItem(InventoryItemModel item) async {
    await _repository.createItem(item);
    await loadItems();
  }

  Future<void> updateItem(InventoryItemModel item) async {
    await _repository.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _repository.deleteItemLogically(id);
    await loadItems();
  }

  Future<void> adjustStock(String itemId, double quantity, String type, String reason) async {
    await _repository.adjustStock(itemId, quantity, type, reason);
    await loadItems();
  }
}

// Current Filter state
final inventoryFilterProvider = StateProvider<String>((ref) => 'Todos');

// Filtered items computed provider (reactivo: deriva del stream de la caja)
final filteredInventoryItemsProvider = Provider<List<InventoryItemModel>>((ref) {
  final items = ref.watch(inventoryItemsStreamProvider).value ?? <InventoryItemModel>[];
  final filter = ref.watch(inventoryFilterProvider);

  if (filter == 'Todos') return items;
  if (filter == '⚠️ Bajo Stock') {
    return items.where((item) => item.currentStock <= item.minimumStock).toList();
  }
  
  // Custom types
  return items.where((item) => item.itemType == filter).toList();
});
