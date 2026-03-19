import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _supabase;

  SupabaseProductRepository(this._supabase);

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_deleted', false);
      
      final products = response.map((json) => ProductModel.fromJson(json)).toList();
      return Right(products);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Error de Base de Datos: ${e.message}'));
    } on AuthException catch (e) {
      return Left(ServerFailure('Error de Autenticación: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Error inesperado al obtener productos: $e'));
    }
  }

  @override
  Stream<List<ProductEntity>> watchProducts() {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('is_deleted', false)
        .map((data) => data.map((json) => ProductModel.fromJson(json)).toList());
  }

  @override
  Future<Either<Failure, void>> addProduct(ProductEntity product) async {
    try {
      final data = {
        'id': product.id,
        'name': product.name,
        'base_price': product.basePrice,
        'extra_cost': product.extraCost,
        'category': product.category,
        'notes': product.notes,
        'is_deleted': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _supabase.from('products').upsert(data);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Error de Base de Datos: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Error inesperado al agregar producto: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(ProductEntity product) async {
    try {
      final data = {
        'name': product.name,
        'base_price': product.basePrice,
        'extra_cost': product.extraCost,
        'category': product.category,
        'notes': product.notes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _supabase.from('products').update(data).eq('id', product.id);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Error de Base de Datos: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Error inesperado al actualizar producto: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await _supabase.from('products').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Error de Base de Datos: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Error inesperado al eliminar producto: $e'));
    }
  }
}
