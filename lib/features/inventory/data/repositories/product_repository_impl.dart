import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

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
