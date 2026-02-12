import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/services/google_cloud_service.dart';

// Repository Provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final box = Hive.box<ProductModel>('products');
  return ProductRepositoryImpl(box);
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
    result.fold(
      (failure) {
        // Handle error if needed
      },
      (_) async {
        // Sync to Google Sheets if enabled
        final settings = ref.read(settingsProvider);
        if (settings.syncSheetsEnabled && settings.googleSheetId != null) {
          await GoogleCloudService().appendProductToSheet(settings.googleSheetId!, product);
        }
        getProducts();
      },
    );
  }

  Future<void> updateProduct(ProductEntity product, WidgetRef ref) async {
    final result = await repository.updateProduct(product);
    result.fold(
      (failure) {
        // Handle error
      },
      (_) async {
        // Sync to Google Sheets if enabled
        final settings = ref.read(settingsProvider);
        if (settings.syncSheetsEnabled && settings.googleSheetId != null) {
          await GoogleCloudService().appendProductToSheet(settings.googleSheetId!, product);
        }
        getProducts();
      },
    );
  }

  Future<void> deleteProduct(String id) async {
    final result = await repository.deleteProduct(id);
    result.fold(
      (failure) {},
      (_) => getProducts(),
    );
  }
}

// Logic Provider
final productListProvider = StateNotifierProvider<ProductListNotifier, AsyncValue<List<ProductEntity>>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductListNotifier(repository);
});
