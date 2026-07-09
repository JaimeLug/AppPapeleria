import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';
import 'supabase_product_repository.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/services/pending_delete_queue.dart';

class OfflineFirstProductRepository implements ProductRepository {
  final SupabaseProductRepository _remoteRepo;
  final Box<ProductModel> _box;
  final SyncManager _syncManager;

  OfflineFirstProductRepository(this._remoteRepo, this._box, this._syncManager);

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
    final local = _box.values.toList();
    _fetchRemoteAndSync();
    return Right(local);
  }

  @override
  Stream<List<ProductEntity>> watchProducts() async* {
    _fetchRemoteAndSync(); // Fetch inicial inmediato
    // Realtime: cada cambio en Supabase (alta/edición/borrado en otro
    // dispositivo) se reconcilia en la caja local en vivo.
    final remoteSub = _remoteRepo.watchProducts().listen(
      _reconcile,
      onError: (e) => debugPrint('Realtime productos: $e'),
    );
    yield _box.values.toList();
    try {
      await for (final _ in _box.watch()) {
        yield _box.values.toList();
      }
    } finally {
      await remoteSub.cancel();
    }
  }

  Future<void> _fetchRemoteAndSync() async {
    final result = await _remoteRepo.getProducts();
    result.fold((l) => null, (remote) => _reconcile(remote));
  }

  /// Reconcilia una lista remota (activa) contra la caja local: actualiza lo
  /// más nuevo y poda lo ya sincronizado que dejó de existir en remoto.
  Future<void> _reconcile(List<ProductEntity> remoteProducts) async {
    final remoteIds = <String>{};
    for (var remote in remoteProducts) {
      remoteIds.add(remote.id);
      final local = _box.get(remote.id);
      if (local == null || (remote is ProductModel && remote.updatedAt.isAfter(local.updatedAt))) {
        await _box.put(remote.id, remote as ProductModel);
      }
    }
    // Poda SEGURA: de los candidatos (sincronizados que ya no están activos),
    // solo eliminamos los que el servidor confirma como borrados. Los que no
    // existen en el servidor son locales con flag obsoleto y se conservan.
    final candidates = _box.values
        .where((p) => !remoteIds.contains(p.id))
        .map((p) => p.id)
        .toList();
    if (candidates.isNotEmpty) {
      final confirmed = await _remoteRepo.deletedIdsAmong(candidates);
      for (final id in confirmed) {
        await _box.delete(id);
      }
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(ProductEntity product) async {
    final model = ProductModel(
      id: product.id,
      name: product.name,
      basePrice: product.basePrice,
      extraCost: product.extraCost,
      category: product.category,
      notes: product.notes,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _box.put(model.id, model);
    _syncManager.syncPendingData();
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateProduct(ProductEntity product) async {
    return addProduct(product); // Logic is the same for optimistic UI
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    await PendingDeleteQueue.add('product', id);
    await _box.delete(id);
    _syncManager.syncPendingData();
    return const Right(null);
  }
}
