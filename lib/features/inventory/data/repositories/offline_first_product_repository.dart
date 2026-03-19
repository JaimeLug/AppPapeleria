import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';
import 'supabase_product_repository.dart';
import '../../../../core/services/sync_manager.dart';

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
    _fetchRemoteAndSync(); // Background fetch
    yield _box.values.toList();
    await for (final _ in _box.watch()) {
      yield _box.values.toList();
    }
  }

  Future<void> _fetchRemoteAndSync() async {
    final result = await _remoteRepo.getProducts();
    result.fold(
      (l) => null,
      (remoteProducts) async {
        for (var remote in remoteProducts) {
          final local = _box.get(remote.id);
          if (local == null || (remote is ProductModel && remote.updatedAt.isAfter(local.updatedAt))) {
            await _box.put(remote.id, remote as ProductModel);
          }
        }
      },
    );
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
    await _box.delete(id);
    _remoteRepo.deleteProduct(id); // Fire and forget, SyncManager handles retry if we had a tombstone
    return const Right(null);
  }
}
