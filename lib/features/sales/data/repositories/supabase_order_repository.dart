import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _supabase;

  SupabaseOrderRepository(this._supabase);

  /// Ids que el servidor confirma como borrados (para poda segura).
  Future<Set<String>> deletedIdsAmong(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final res = await _supabase
          .from('orders')
          .select('id')
          .inFilter('id', ids)
          .eq('is_deleted', true);
      return res.map((r) => r['id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    try {
      // Fetch orders
      final ordersResponse = await _supabase
          .from('orders')
          .select()
          .eq('is_deleted', false)
          .order('sale_date', ascending: false);

      // Renglones de TODOS los pedidos en una sola query (evita N+1).
      final orderIds =
          ordersResponse.map((o) => o['id'] as String).toList();
      final Map<String, List<OrderItemModel>> itemsByOrder = {};
      if (orderIds.isNotEmpty) {
        final itemsResponse = await _supabase
            .from('order_items')
            .select()
            .inFilter('order_id', orderIds);
        for (final itemJson in itemsResponse) {
          final oid = itemJson['order_id'] as String;
          (itemsByOrder[oid] ??= []).add(OrderItemModel.fromMap(itemJson));
        }
      }

      final List<OrderEntity> orders = [];

      for (var orderJson in ordersResponse) {
        final orderId = orderJson['id'] as String;
        final items = itemsByOrder[orderId] ?? const [];

        // Map order fields from snake_case to model
        final order = OrderModel(
          id: orderJson['id'],
          customerName: orderJson['customer_name'],
          items: items,
          totalPrice: (orderJson['total_price'] ?? 0.0).toDouble(),
          pendingBalance: (orderJson['pending_balance'] ?? 0.0).toDouble(),
          deliveryDate: DateTime.parse(orderJson['delivery_date']),
          isSynced: true,
          saleDate: orderJson['sale_date'] != null ? DateTime.parse(orderJson['sale_date']) : null,
          paymentStatus: orderJson['payment_status'] ?? 'pending',
          deliveryStatus: orderJson['delivery_status'] ?? 'pending',
          googleEventId: orderJson['google_event_id'],
          notes: orderJson['notes'],
          updatedAt: orderJson['updated_at'] != null 
              ? DateTime.parse(orderJson['updated_at']) 
              : DateTime.parse(orderJson['delivery_date']),
        );
        orders.add(order);
      }

      return Right(orders);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Error BD al obtener pedidos: ${e.message}'));
    } on AuthException catch (e) {
      return Left(ServerFailure('Error de Autenticación: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Error inesperado al obtener pedidos: $e'));
    }
  }

  @override
  Stream<List<OrderEntity>> watchOrders() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('is_deleted', false)
        .order('sale_date')
        .map((data) => data.map((json) => OrderModel(
              id: json['id'],
              customerName: json['customer_name'],
              items: const [], // Simplified for stream
              totalPrice: (json['total_price'] ?? 0.0).toDouble(),
              pendingBalance: (json['pending_balance'] ?? 0.0).toDouble(),
              deliveryDate: DateTime.parse(json['delivery_date']),
              isSynced: true,
              saleDate: json['sale_date'] != null ? DateTime.parse(json['sale_date']) : null,
              paymentStatus: json['payment_status'] ?? 'pending',
              deliveryStatus: json['delivery_status'] ?? 'pending',
              googleEventId: json['google_event_id'],
              notes: json['notes'],
              updatedAt: json['updated_at'] != null 
                  ? DateTime.parse(json['updated_at']) 
                  : DateTime.parse(json['delivery_date']),
            )).toList());
  }

  @override
  Future<Either<Failure, bool>> addOrder(OrderEntity order) async {
    try {
      // 1. Insert Order
      final orderData = {
        'id': order.id,
        'customer_name': order.customerName,
        'total_price': order.totalPrice,
        'pending_balance': order.pendingBalance,
        'delivery_date': order.deliveryDate.toUtc().toIso8601String(),
        'sale_date': order.saleDate?.toUtc().toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
        'payment_status': order.paymentStatus,
        'delivery_status': order.deliveryStatus,
        'google_event_id': order.googleEventId,
        'notes': order.notes,
        'is_deleted': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await _supabase.from('orders').upsert(orderData);

      // 2. Insert Order Items (Massive insert)
      if (order.items.isNotEmpty) {
        final itemsData = order.items.map((item) => {
          'order_id': order.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'price': item.price,
          'quantity': item.quantity,
          'notes': item.notes,
        }).toList();

        // Optional: Delete existing items if it's an update to avoid duplicates
        await _supabase.from('order_items').delete().eq('order_id', order.id);
        await _supabase.from('order_items').insert(itemsData);
      }

      return const Right(true);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Error BD al guardar pedido: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Error inesperado al guardar pedido: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOrder(String id) async {
    try {
      await _supabase.from('orders').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Error BD al eliminar pedido: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Error inesperado al eliminar pedido: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> syncOrders() async {
    // This will be implemented in the Offline Engine phase (Phase 5)
    // For now, it returns success as we are directly in Cloud Repo
    return const Right(true);
  }
}
