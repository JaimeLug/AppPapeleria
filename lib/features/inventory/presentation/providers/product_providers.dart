import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/product_model.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../data/repositories/offline_first_product_repository.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/providers/remote_repositories_providers.dart';

// Repository Provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final box = Hive.box<ProductModel>('products');
  final remoteRepo = ref.watch(remoteProductRepositoryProvider);
  final syncManager = ref.watch(syncManagerProvider);
  
  return OfflineFirstProductRepository(remoteRepo, box, syncManager);
});

// Stream Provider for reactive UI updates
final productListStreamProvider = StreamProvider<List<ProductEntity>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProducts();
});

// State Notifier to manage the list of products
class ProductListNotifier extends StateNotifier<AsyncValue<List<ProductEntity>>> {
  final ProductRepository repository;

  ProductListNotifier(this.repository) : super(const AsyncValue.loading()) {
    getProducts();
  }

  Future<void> getProducts() async {
    state = const AsyncValue.loading();
    final result = await repository.getProducts();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (products) => state = AsyncValue.data(products),
    );
  }

  Future<void> addProduct(ProductEntity product, WidgetRef ref) async {
    final result = await repository.addProduct(product);
    await result.fold(
      (failure) async {
        throw Exception(failure.message);
      },
      (_) async {
        getProducts();
      },
    );
  }

  Future<void> updateProduct(ProductEntity product, WidgetRef ref) async {
    final result = await repository.updateProduct(product);
    await result.fold(
      (failure) async {
        throw Exception(failure.message);
      },
      (_) async {
        getProducts();
      },
    );
  }

  Future<void> deleteProduct(String id) async {
    final result = await repository.deleteProduct(id);
    await result.fold(
      (failure) async {
        throw Exception(failure.message);
      },
      (_) async => getProducts(),
    );
  }
}

// Logic Provider
final productListProvider = StateNotifierProvider<ProductListNotifier, AsyncValue<List<ProductEntity>>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductListNotifier(repository);
});
