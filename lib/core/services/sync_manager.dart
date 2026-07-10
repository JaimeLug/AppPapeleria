import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/remote_repositories_providers.dart';
import 'pending_delete_queue.dart';
import 'sync_trigger.dart';
import '../../features/sales/data/repositories/supabase_customer_repository.dart';
import '../../features/inventory/domain/repositories/remote_product_repository.dart';
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

class SyncManager implements SyncTrigger {
  final SupabaseCustomerRepository _remoteCustomerRepo;
  final RemoteProductRepository _remoteProductRepo;
  final SupabaseOrderRepository _remoteOrderRepo;
  final SupabaseInventoryRepository _remoteInventoryRepo;
  final SupabaseFinanceRepository _remoteFinanceRepo;

  bool _isSyncing = false;
  bool _syncRequestedAgain = false;
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

  /// Sube a la nube solo lo que está pendiente (`isSynced == false`).
  /// Es el guardado en tiempo real que se dispara al crear/editar y al
  /// recuperar conectividad.
  @override
  Future<void> syncPendingData() async {
    // Sin sesión no se sincroniza: evita errores de RLS y que los registros
    // queden "colgados" por intentos de subida sin autenticar (p. ej. la sync
    // por conectividad que dispara al arrancar la app, antes del login).
    if (Supabase.instance.client.auth.currentSession == null) return;

    // Si ya hay una sincronización en curso, en vez de descartar esta petición
    // marcamos que hay que volver a correr al terminar. Así una creación hecha
    // mientras se sincroniza no se queda sin subir.
    if (_isSyncing) {
      _syncRequestedAgain = true;
      return;
    }
    _isSyncing = true;

    try {
      do {
        _syncRequestedAgain = false;
        await _syncCustomers();
        await _syncProducts();
        await _syncItems();
        await _syncOrders();
        await _syncMovements();
        await _syncExpenses();
        await _syncIncomes();
        await _syncPendingDeletes();
      } while (_syncRequestedAgain);
    } catch (e) {
      debugPrint('Error durante la sincronización: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Guardado completo: empuja TODO lo local a la nube, ignorando el flag
  /// `isSynced`. Se usa al cerrar sesión como red de seguridad y para
  /// re-subir datos cuyo flag apunta a una base anterior.
  Future<void> forceSyncAll() async {
    // Sin sesión no hay nada que subir de forma autenticada.
    if (Supabase.instance.client.auth.currentSession == null) return;

    // Si hay una sincronización normal en curso, esperamos a que termine en
    // vez de saltarnos el guardado completo (crítico al cerrar sesión).
    while (_isSyncing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _isSyncing = true;

    try {
      await _syncCustomers(force: true);
      await _syncProducts(force: true);
      await _syncItems(force: true);
      await _syncOrders(force: true);
      await _syncMovements(force: true);
      await _syncExpenses(force: true);
      await _syncIncomes(force: true);
      await _syncPendingDeletes();
    } catch (e) {
      debugPrint('Error durante el guardado completo: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncCustomers({bool force = false}) async {
    final box = Hive.box<CustomerModel>('customers');
    final pending = box.values.where((c) => force || !c.isSynced).toList();
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

  Future<void> _syncProducts({bool force = false}) async {
    final box = Hive.box<ProductModel>('products');
    final pending = box.values.where((p) => force || !p.isSynced).toList();
    for (var product in pending) {
      final result = await _remoteProductRepo.addProduct(product);
      result.fold(
        (failure) => debugPrint('Error sincronizando producto "${product.name}" (${product.id}): ${failure.message}'),
        (_) async {
          final synced = product.copyWith(isSynced: true);
          await box.put(product.id, synced);
        },
      );
    }
  }

  Future<void> _syncItems({bool force = false}) async {
    final box = Hive.box<InventoryItemModel>('inventoryItems');
    final pending = box.values.where((i) => force || !i.isSynced).toList();
    for (var item in pending) {
      try {
        if (item.isDeleted) {
          await _remoteInventoryRepo.deleteItemLogically(item.id);
        } else {
          await _remoteInventoryRepo.createItem(item);
        }
        final synced = item.copyWith(isSynced: true);
        await box.put(item.id, synced);
      } catch (e) {
        debugPrint('Error sincronizando ítem ${item.id}: $e');
      }
    }
  }

  Future<void> _syncOrders({bool force = false}) async {
    final box = Hive.box<OrderModel>('orders');
    final pending = box.values.where((o) => force || !o.isSynced).toList();
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

  Future<void> _syncMovements({bool force = false}) async {
    final box = Hive.box<StockMovementModel>('stockMovements');
    final pending = box.values.where((m) => force || !m.isSynced).toList();
    for (var movement in pending) {
      try {
        if (force) {
          // Guardado completo: solo sube el registro, sin re-ajustar el stock
          // (el stock ya viaja autoritativo en inventory_items).
          await _remoteInventoryRepo.upsertMovement(movement);
        } else {
          await _remoteInventoryRepo.adjustStock(
            movement.itemId,
            movement.quantity,
            movement.movementType,
            movement.reason,
            movementId: movement.id,
          );
        }
        final synced = movement.copyWith(isSynced: true);
        await box.put(movement.id, synced);
      } catch (e) {
        debugPrint('Error sincronizando movimiento ${movement.id}: $e');
      }
    }
  }

  Future<void> _syncExpenses({bool force = false}) async {
    final box = Hive.box<ExpenseModel>('expenses');
    final pending = box.values.where((e) => force || !e.isSynced).toList();
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

  Future<void> _syncIncomes({bool force = false}) async {
    final box = Hive.box<IncomeModel>('incomes');
    final pending = box.values.where((i) => force || !i.isSynced).toList();
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

  /// Cuenta los registros locales que aún no se han subido a la nube
  /// (más los borrados pendientes). Se usa para decidir si mostrar el
  /// diálogo de reconciliación al iniciar sesión.
  int countPendingLocalData() {
    int count = 0;
    count += Hive.box<CustomerModel>('customers').values.where((c) => !c.isSynced).length;
    count += Hive.box<ProductModel>('products').values.where((p) => !p.isSynced).length;
    count += Hive.box<InventoryItemModel>('inventoryItems').values.where((i) => !i.isSynced).length;
    count += Hive.box<OrderModel>('orders').values.where((o) => !o.isSynced).length;
    count += Hive.box<StockMovementModel>('stockMovements').values.where((m) => !m.isSynced).length;
    count += Hive.box<ExpenseModel>('expenses').values.where((e) => !e.isSynced).length;
    count += Hive.box<IncomeModel>('incomes').values.where((i) => !i.isSynced).length;
    count += PendingDeleteQueue.count;
    return count;
  }

  bool get hasPendingLocalData => countPendingLocalData() > 0;

  /// Descarta los registros locales sin sincronizar (y los borrados
  /// pendientes). Lo ya sincronizado —caché de la nube— se conserva.
  Future<void> discardPendingLocalData() async {
    await _deleteUnsynced<CustomerModel>('customers', (v) => v.isSynced);
    await _deleteUnsynced<ProductModel>('products', (v) => v.isSynced);
    await _deleteUnsynced<InventoryItemModel>('inventoryItems', (v) => v.isSynced);
    await _deleteUnsynced<OrderModel>('orders', (v) => v.isSynced);
    await _deleteUnsynced<StockMovementModel>('stockMovements', (v) => v.isSynced);
    await _deleteUnsynced<ExpenseModel>('expenses', (v) => v.isSynced);
    await _deleteUnsynced<IncomeModel>('incomes', (v) => v.isSynced);
    await PendingDeleteQueue.clear();
  }

  Future<void> _deleteUnsynced<T>(String boxName, bool Function(T) isSynced) async {
    final box = Hive.box<T>(boxName);
    final keysToDelete =
        box.keys.where((k) => !isSynced(box.get(k) as T)).toList();
    await box.deleteAll(keysToDelete);
  }

  Future<void> _syncPendingDeletes() async {
    final pendingDeletes = PendingDeleteQueue.getAll();

    for (final pendingDelete in pendingDeletes) {
      try {
        switch (pendingDelete.type) {
          case 'customer':
            await _remoteCustomerRepo.deleteCustomer(pendingDelete.id);
            break;
          case 'product':
            final result =
                await _remoteProductRepo.deleteProduct(pendingDelete.id);
            result.fold(
              (failure) => throw Exception(failure.message),
              (_) => null,
            );
            break;
          case 'order':
            final result = await _remoteOrderRepo.deleteOrder(pendingDelete.id);
            result.fold(
              (failure) => throw Exception(failure.message),
              (_) => null,
            );
            break;
          case 'expense':
            await _remoteFinanceRepo.deleteExpense(pendingDelete.id);
            break;
          case 'income':
            await _remoteFinanceRepo.deleteIncome(pendingDelete.id);
            break;
          default:
            debugPrint('Tipo de borrado pendiente desconocido: ${pendingDelete.type}');
            continue;
        }

        await PendingDeleteQueue.remove(pendingDelete.type, pendingDelete.id);
      } catch (e) {
        debugPrint(
          'Error sincronizando borrado ${pendingDelete.type}/${pendingDelete.id}: $e',
        );
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
  ref.onDispose(manager.dispose);

  return manager;
});
