import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              const Text('Gestión de Pedidos', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Search Bar
              SizedBox(
                height: 45,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre del cliente...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          toolbarHeight: 110,
          bottom: TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Activos'),
              Tab(text: 'Hoy'),
              Tab(text: 'Historial'),
            ],
          ),
          actions: const [],
        ),
        body: ref.watch(ordersStreamProvider).when(
          data: (orders) {
            // Filter Logic - using deliveryStatus
            final activeOrders = orders.where((o) => o.deliveryStatus != 'delivered' && o.status != 'Entregado').toList();
            
            final today = DateTime.now();
            final todayOrders = orders.where((o) {
              return o.deliveryDate.year == today.year &&
                     o.deliveryDate.month == today.month &&
                     o.deliveryDate.day == today.day &&
                     (o.deliveryStatus != 'delivered' && o.status != 'Entregado');
            }).toList();

            final historyOrders = orders.where((o) => o.deliveryStatus == 'delivered' || o.status == 'Entregado').toList();

            return TabBarView(
              children: [
                _OrderList(orders: activeOrders, searchQuery: _searchQuery),
                _OrderList(orders: todayOrders, searchQuery: _searchQuery),
                _OrderList(orders: historyOrders, searchQuery: _searchQuery),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error al cargar pedidos:\n$err', textAlign: TextAlign.center)),
        ),
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  final List<OrderEntity> orders;
  final String searchQuery;

  const _OrderList({required this.orders, this.searchQuery = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter orders by customer name
    final filteredOrders = orders.where((order) {
      if (searchQuery.isEmpty) return true;
      return order.customerName.toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty 
                ? 'No hay pedidos en esta sección' 
                : 'No se encontraron pedidos con "$searchQuery"',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OrderCard(
              order: order,
              onStatusChange: (newStatus) {
                ref.read(ordersProvider.notifier).updateOrderStatus(order, newStatus);
              },
              onMarkDelivered: () {
                 ref.read(ordersProvider.notifier).markAsDelivered(order);
              },
              onLiquidateDebt: () {
                ref.read(ordersProvider.notifier).liquidateDebt(order);
              },
              onAddPayment: (amount) {
                ref.read(ordersProvider.notifier).addPayment(order, amount);
              },
            ),
          );
        },
      );
  }
}