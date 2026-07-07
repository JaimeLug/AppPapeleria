import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/customer_model.dart';
import 'supabase_customer_repository.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/services/pending_delete_queue.dart';

class OfflineFirstCustomerRepository implements CustomerRepository {
  final SupabaseCustomerRepository _remoteRepo;
  final Box<CustomerModel> _box;
  final SyncManager _syncManager;

  OfflineFirstCustomerRepository(this._remoteRepo, this._box, this._syncManager);

  @override
  Future<List<CustomerEntity>> getAllCustomers() async {
    // 1. Return Local immediately
    final localData = _box.values.toList();
    
    // 2. Background Fetch (Silent)
    _fetchRemoteAndSync();
    
    return localData;
  }

  @override
  Stream<List<CustomerEntity>> watchCustomers() async* {
    _fetchRemoteAndSync(); // Background fetch
    yield _box.values.toList();
    await for (final _ in _box.watch()) {
      yield _box.values.toList();
    }
  }

  Future<void> _fetchRemoteAndSync() async {
    try {
      final remoteData = await _remoteRepo.getAllCustomers();
      final remoteIds = <String>{};
      for (var remoteCustomer in remoteData) {
        remoteIds.add(remoteCustomer.id);
        final localCustomer = _box.get(remoteCustomer.id);

        // Only update if remote is newer or not exists locally
        if (localCustomer == null ||
           (remoteCustomer is CustomerModel && remoteCustomer.updatedAt.isAfter(localCustomer.updatedAt))) {
          await _box.put(remoteCustomer.id, remoteCustomer as CustomerModel);
        }
      }
      // Poda: elimina lo que ya fue sincronizado pero ya no existe en remoto
      // (borrado desde otro dispositivo). No toca lo creado local sin subir.
      final toRemove = _box.values
          .where((c) => c.isSynced && !remoteIds.contains(c.id))
          .map((c) => c.id)
          .toList();
      for (final id in toRemove) {
        await _box.delete(id);
      }
    } catch (e) {
      debugPrint('Error en fetch remoto de clientes: $e');
    }
  }

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    return _box.values
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<void> saveCustomer(CustomerEntity customer) async {
    final model = CustomerModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      isSynced: false,
      updatedAt: DateTime.now(),
    );

    // 1. Save Local (Optimistic)
    await _box.put(model.id, model);

    // 2. Trigger Sync
    _syncManager.syncPendingData();
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final local = _box.get(id);
    if (local != null) {
      await PendingDeleteQueue.add('customer', id);
      await _box.delete(id);
    }

    _syncManager.syncPendingData();
  }
}
