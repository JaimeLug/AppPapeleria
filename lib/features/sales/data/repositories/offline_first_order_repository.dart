import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';
import 'supabase_order_repository.dart';
import '../../../../core/services/sync_manager.dart';

class OfflineFirstOrderRepository implements OrderRepository {
  final SupabaseOrderRepository _remoteRepo;
  final Box<OrderModel> _box;
  final SyncManager _syncManager;

  OfflineFirstOrderRepository(this._remoteRepo, this._box, this._syncManager);

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    final local = _box.values.toList();
    _fetchRemoteAndSync();
    return Right(local);
  }

  @override
  Stream<List<OrderEntity>> watchOrders() async* {
    _fetchRemoteAndSync(); // Background fetch
    yield _box.values.toList();
    await for (final _ in _box.watch()) {
      yield _box.values.toList();
    }
  }

  Future<void> _fetchRemoteAndSync() async {
    final result = await _remoteRepo.getOrders();
    result.fold(
      (l) => null,
      (remoteOrders) async {
        for (var remote in remoteOrders) {
          final local = _box.get(remote.id);
          if (local == null || (remote is OrderModel && remote.updatedAt.isAfter(local.updatedAt))) {
            await _box.put(remote.id, remote as OrderModel);
          }
        }
      },
    );
  }

  @override
  Future<Either<Failure, bool>> addOrder(OrderEntity order) async {
    final model = OrderModel.fromEntity(order).copyWith(
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _box.put(model.id, model);
    _syncManager.syncPendingData();
    return const Right(true);
  }

  @override
  Future<Either<Failure, void>> deleteOrder(String id) async {
    await _box.delete(id);
    _remoteRepo.deleteOrder(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> syncOrders() async {
    await _syncManager.syncPendingData(); // Trigger general sync
    return const Right(true);
  }
}
