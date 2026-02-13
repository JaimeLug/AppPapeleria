import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/services/google_cloud_service.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import 'cart_provider.dart';

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
        // Sort by delivery date ascending (closest first)
        orders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
        state = AsyncValue.data(orders);
      },
    );
  }

  // Add method to update status if needed
  Future<void> updateOrderStatus(OrderEntity order, String newStatus) async {
      // Legacy status update
      final updatedOrder = order.copyWith(status: newStatus);
      await repository.addOrder(updatedOrder);
      // getOrders(); // Not strictly needed if listening to Hive, but good for local state if used
  }

  Future<void> markAsDelivered(OrderEntity order) async {
    print('LOG: Marking order ${order.id} as delivered');
    print('LOG: Current deliveryStatus: ${order.deliveryStatus}');
    final updatedOrder = order.copyWith(
      deliveryStatus: 'delivered',
      status: 'Entregado', // Synced for legacy compatibility
    );
    print('LOG: Updated deliveryStatus: ${updatedOrder.deliveryStatus}');
    await repository.addOrder(updatedOrder);
    print('LOG: Order saved to repository');
  }

  Future<void> liquidateDebt(OrderEntity order) async {
    print('LOG: Liquidating debt for order ${order.id}');
    print('LOG: Current pendingBalance: ${order.pendingBalance}');
    final updatedOrder = order.copyWith(
      pendingBalance: 0.0,
      paymentStatus: 'paid',
    );
    print('LOG: Updated pendingBalance: ${updatedOrder.pendingBalance}');
    await repository.addOrder(updatedOrder);
    print('LOG: Order saved to repository');
  }

  Future<void> addPayment(OrderEntity order, double amount) async {
    print('LOG: Adding payment of \$$amount to order ${order.id}');
    print('LOG: Current pendingBalance: ${order.pendingBalance}');
    
    // Validation
    if (amount <= 0 || amount > order.pendingBalance) {
      print('LOG: Invalid payment amount');
      return;
    }
    
    final newBalance = order.pendingBalance - amount;
    final isPaid = newBalance <= 0.01; // Consider paid if balance is negligible
    
    final updatedOrder = order.copyWith(
      pendingBalance: isPaid ? 0.0 : newBalance,
      paymentStatus: isPaid ? 'paid' : 'pending',
    );
    
    print('LOG: New pendingBalance: ${updatedOrder.pendingBalance}');
    print('LOG: Payment status: ${updatedOrder.paymentStatus}');
    await repository.addOrder(updatedOrder);
    print('LOG: Order saved to repository');
  }

  Future<void> deleteOrder(String id) async {
    print('LOG: Deleting order $id');
    final result = await repository.deleteOrder(id);
    result.fold(
      (failure) {
        print('LOG: Error deleting order: $failure');
      },
      (_) {
        print('LOG: Order deleted successfully');
        getOrders();
      },
    );
  }
  Future<bool> syncOrders() async {
    try {
      final settingsBox = Hive.box('settings');
      final settingsMap = settingsBox.get('appSettings');
      if (settingsMap == null) return false;
      
      final settings = Map<String, dynamic>.from(settingsMap);
      final sheetId = settings['googleSheetId'];
      
      if (sheetId == null || sheetId.isEmpty) {
        return false;
      }

      final googleService = GoogleCloudService();
      if (!googleService.isAuthenticated) {
        // Try to restore session
        final restored = await googleService.authenticateFromStoredCredentials();
        if (!restored) return false;
      }

      // Perform Import (Upsert)
      await googleService.importFromSheets(sheetId, replaceLocal: false);
      
      // Refresh local list
      await getOrders();
      return true;
    } catch (e) {
      print('LOG: Sync error: $e');
      return false;
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderEntity>>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrdersNotifier(repository);
});
