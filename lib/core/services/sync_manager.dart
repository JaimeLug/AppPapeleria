import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/remote_repositories_providers.dart';
import '../../features/sales/data/repositories/supabase_customer_repository.dart';
import '../../features/inventory/data/repositories/supabase_product_repository.dart';
import '../../features/sales/data/repositories/supabase_order_repository.dart';
import '../../features/inventory/data/repositories/supabase_inventory_repository.dart';
import '../../features/finance/data/repositories/supabase_finance_repository.dart';

import '../../features/sales/data/models/customer_model.dart';
import '../../features/inventory/data/models/product_model.dart';
import '../../features/sales/data/models/order_model.dart';
import '../../features/inventory/data/models/inventory_item_model.dart';
import '../../features/inventory/data/models/stock_movement_model.dart';
import '../../features/finance/data/models/expense_model.dart';
import '../../features/finance/data/models/income_model.dart';

class SyncManager {
  final SupabaseCustomerRepository _remoteCustomerRepo;
  final SupabaseProductRepository _remoteProductRepo;
  final SupabaseOrderRepository _remoteOrderRepo;
  final SupabaseInventoryRepository _remoteInventoryRepo;
  final SupabaseFinanceRepository _remoteFinanceRepo;

  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncManager(
    this._remoteCustomerRepo,
    this._remoteProductRepo,
    this._remoteOrderRepo,
    this._remoteInventoryRepo,
    this._remoteFinanceRepo,
  );

  void init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncPendingData();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _syncCustomers();
      await _syncProducts();
      await _syncItems();
      await _syncOrders();
      await _syncMovements();
      await _syncExpenses();
      await _syncIncomes();
    } catch (e) {
      debugPrint('Error durante la sincronización: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncCustomers() async {
    final box = Hive.box<CustomerModel>('customers');
    final pending = box.values.where((c) => !c.isSynced).toList();
    for (var customer in pending) {
      try {
        await _remoteCustomerRepo.saveCustomer(customer);
        final synced = customer.copyWith(isSynced: true);
        await box.put(customer.id, synced);
      } catch (e) {
        debugPrint('Error sincronizando cliente ${customer.id}: $e');
      }
    }
  }

  Future<void> _syncProducts() async {
    final box = Hive.box<ProductModel>('products');
    final pending = box.values.where((p) => !p.isSynced).toList();
    for (var product in pending) {
      final result = await _remoteProductRepo.addProduct(product);
      result.fold(
        (failure) => debugPrint('Error sincronizando producto ${product.id}: ${failure.message}'),
        (_) async {
          final synced = product.copyWith(isSynced: true);
          await box.put(product.id, synced);
        },
      );
    }
  }

  Future<void> _syncItems() async {
    final box = Hive.box<InventoryItemModel>('inventoryItems');
    final pending = box.values.where((i) => !i.isSynced).toList();
    for (var item in pending) {
      try {
        await _remoteInventoryRepo.createItem(item);
        final synced = item.copyWith(isSynced: true);
        await box.put(item.id, synced);
      } catch (e) {
        debugPrint('Error sincronizando ítem ${item.id}: $e');
      }
    }
  }

  Future<void> _syncOrders() async {
    final box = Hive.box<OrderModel>('orders');
    final pending = box.values.where((o) => !o.isSynced).toList();
    for (var order in pending) {
      final result = await _remoteOrderRepo.addOrder(order);
      result.fold(
        (failure) => debugPrint('Error sincronizando pedido ${order.id}: ${failure.message}'),
        (_) async {
          final synced = order.copyWith(isSynced: true);
          await box.put(order.id, synced);
        },
      );
    }
  }

  Future<void> _syncMovements() async {
    final box = Hive.box<StockMovementModel>('stockMovements');
    final pending = box.values.where((m) => !m.isSynced).toList();
    for (var movement in pending) {
      try {
        await _remoteInventoryRepo.adjustStock(
          movement.itemId,
          movement.quantity,
          movement.movementType,
          movement.reason,
          movementId: movement.id,
        );
        final synced = movement.copyWith(isSynced: true);
        await box.put(movement.id, synced);
      } catch (e) {
        debugPrint('Error sincronizando movimiento ${movement.id}: $e');
      }
    }
  }

  Future<void> _syncExpenses() async {
    final box = Hive.box<ExpenseModel>('expenses');
    final pending = box.values.where((e) => !e.isSynced).toList();
    for (var expense in pending) {
      try {
        await _remoteFinanceRepo.addExpense(expense);
        final synced = expense.copyWith(isSynced: true);
        await box.put(expense.id, synced);
      } catch (e) {
        debugPrint('Error sincronizando gasto ${expense.id}: $e');
      }
    }
  }

  Future<void> _syncIncomes() async {
    final box = Hive.box<IncomeModel>('incomes');
    final pending = box.values.where((i) => !i.isSynced).toList();
    for (var income in pending) {
      try {
        await _remoteFinanceRepo.addIncome(income);
        final synced = income.copyWith(isSynced: true);
        await box.put(income.id, synced);
      } catch (e) {
        debugPrint('Error sincronizando ingreso ${income.id}: $e');
      }
    }
  }
}

// Provider for SyncManager
final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    ref.watch(remoteCustomerRepositoryProvider),
    ref.watch(remoteProductRepositoryProvider),
    ref.watch(remoteOrderRepositoryProvider),
    ref.watch(remoteInventoryRepositoryProvider),
    ref.watch(remoteFinanceRepositoryProvider),
  );
  
  // Self-initialize the manager
  manager.init();
  
  return manager;
});
