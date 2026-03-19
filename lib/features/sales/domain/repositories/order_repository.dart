import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderEntity>>> getOrders();
  Stream<List<OrderEntity>> watchOrders();
  Future<Either<Failure, bool>> addOrder(OrderEntity order);
  Future<Either<Failure, void>> deleteOrder(String id);
  Future<Either<Failure, bool>> syncOrders();
}
