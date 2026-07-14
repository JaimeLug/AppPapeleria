import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'orders_provider.dart';

/// IDs de producto ordenados por cantidad total vendida (de más a menos),
/// sumando TODOS los pedidos. Se usa para destacar los "Más vendidos" en el
/// catálogo de ventas. Se actualiza en vivo con los pedidos.
final bestSellerProductIdsProvider = Provider.autoDispose<List<String>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  final orders = ordersAsync.value ?? [];

  final counts = <String, int>{};
  for (final order in orders) {
    for (final item in order.items) {
      if (item.productId.isEmpty) continue;
      counts[item.productId] = (counts[item.productId] ?? 0) + item.quantity.toInt();
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.map((e) => e.key).toList();
});
