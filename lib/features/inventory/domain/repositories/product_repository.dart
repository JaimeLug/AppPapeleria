import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts();
  Future<Either<Failure, void>> addProduct(ProductEntity product);
  Future<Either<Failure, void>> updateProduct(ProductEntity product);
  Future<Either<Failure, void>> deleteProduct(String id);
}
