import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';
import '../../../../core/services/google_cloud_service.dart';

class ProductRepositoryImpl implements ProductRepository {
  final Box<ProductModel> productBox;

  ProductRepositoryImpl(this.productBox);

  @override
  Future<Either<Failure, void>> addProduct(ProductEntity product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      await productBox.put(productModel.id, productModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(ProductEntity product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      await productBox.put(productModel.id, productModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
     try {
      await productBox.delete(id);
      
      try {
        final googleService = GoogleCloudService();
        if (googleService.isAuthenticated) {
           final settingsBox = Hive.box('settings');
           final settingsMap = settingsBox.get('appSettings');
           if (settingsMap != null) {
             final settings = Map<String, dynamic>.from(settingsMap);
             if (settings['syncSheetsEnabled'] == true && settings['googleSheetId'] != null) {
               final sheetId = settings['googleSheetId'] as String;
               if (sheetId.isNotEmpty) {
                 print('Intentando eliminar producto $id de Cloud...');
                 await googleService.deleteRowById(sheetId, 'Productos', id);
               }
             }
           }
        }
      } catch (e) {
        print('Error al intentar borrar producto de la nube: $e');
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
     try {
      final products = productBox.values.toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
