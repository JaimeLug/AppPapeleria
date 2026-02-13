import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../config/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
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
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Activos'),
              Tab(text: 'Hoy'),
              Tab(text: 'Historial'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Consumer(
                builder: (context, ref, child) {
                  return IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                    tooltip: 'Sincronizar ahora',
                    onPressed: () async {
                      final success = await ref.read(ordersProvider.notifier).syncOrders();
                      if (context.mounted) {
                         if (success) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Datos actualizados correctamente'), backgroundColor: Colors.green),
                           );
                         } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('No se pudo actualizar. Mostrando datos locales.'), backgroundColor: Colors.orange),
                           );
                         }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<OrderModel>('orders').listenable(),
          builder: (context, Box<OrderModel> box, _) {
            final orders = box.values.toList().cast<OrderEntity>();
            
            // Filter Logic - using deliveryStatus
            final activeOrders = orders.where((o) => o.deliveryStatus != 'delivered' && o.status != 'Entregado').toList();
            // Fallback to 'status' if deliveryStatus is pending but status says Entregado (legacy check)
            
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

    return RefreshIndicator(
      onRefresh: () async {
        final success = await ref.read(ordersProvider.notifier).syncOrders();
        if (context.mounted) {
           if (success) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Datos actualizados correctamente'), backgroundColor: Colors.green),
             );
           } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('No se pudo actualizar. Mostrando datos locales.'), backgroundColor: Colors.orange),
             );
           }
        }
      },
      child: ListView.builder(
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
      ),
    );
  }
}
