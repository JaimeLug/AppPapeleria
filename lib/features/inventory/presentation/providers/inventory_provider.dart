import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
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

// Filtered items computed provider
final filteredInventoryItemsProvider = Provider<List<InventoryItemModel>>((ref) {
  final items = ref.watch(inventoryItemsProvider);
  final filter = ref.watch(inventoryFilterProvider);

  if (filter == 'Todos') return items;
  if (filter == '⚠️ Bajo Stock') {
    return items.where((item) => item.currentStock <= item.minimumStock).toList();
  }
  
  // Custom types
  return items.where((item) => item.itemType == filter).toList();
});
