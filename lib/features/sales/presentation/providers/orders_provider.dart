import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import 'cart_provider.dart';

// Stream Provider to power the UI reactively without importing Hive directly
final ordersStreamProvider = StreamProvider<List<OrderEntity>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.watchOrders();
});

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderEntity>>> {
  final OrderRepository repository;

  OrdersNotifier(this.repository) : super(const AsyncValue.loading()) {
    getOrders();
  }

  Future<void> getOrders() async {
    state = const AsyncValue.loading();
    final result = await repository.getOrders();
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (orders) {
        state = AsyncValue.data(orders);
      },
    );
  }

  // Add method to update status if needed
  Future<void> updateOrderStatus(OrderEntity order, String newStatus) async {
      // Legacy status update
      final updatedOrder = order.copyWith(status: newStatus);
      await repository.addOrder(updatedOrder);
  }

  Future<void> markAsDelivered(OrderEntity order) async {
    debugPrint('LOG: Marking order ${order.id} as delivered');
    final updatedOrder = order.copyWith(
      deliveryStatus: 'delivered',
      status: 'Entregado', // Synced for legacy compatibility
    );
    await repository.addOrder(updatedOrder);
  }

  Future<void> liquidateDebt(OrderEntity order) async {
    debugPrint('LOG: Liquidating debt for order ${order.id}');
    final updatedOrder = order.copyWith(
      pendingBalance: 0.0,
      paymentStatus: 'paid',
    );
    await repository.addOrder(updatedOrder);
  }

  Future<void> addPayment(OrderEntity order, double amount) async {
    debugPrint('LOG: Adding payment of \$$amount to order ${order.id}');
    
    // Validation
    if (amount <= 0 || amount > order.pendingBalance) {
      return;
    }
    
    final newBalance = order.pendingBalance - amount;
    final isPaid = newBalance <= 0.01; // Consider paid if balance is negligible
    
    final updatedOrder = order.copyWith(
      pendingBalance: isPaid ? 0.0 : newBalance,
      paymentStatus: isPaid ? 'paid' : 'pending',
    );
    
    await repository.addOrder(updatedOrder);
  }

  Future<void> deleteOrder(String id) async {
    debugPrint('LOG: Deleting order $id');
    final result = await repository.deleteOrder(id);
    result.fold(
      (failure) {
        debugPrint('LOG: Error deleting order: $failure');
      },
      (_) {
        debugPrint('LOG: Order deleted successfully');
        getOrders();
      },
    );
  }

  Future<bool> syncOrders() async {
    final result = await repository.syncOrders();
    return result.fold(
      (failure) => false,
      (_) => true,
    );
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderEntity>>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrdersNotifier(repository);
});
