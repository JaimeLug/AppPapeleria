import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import '../../data/models/order_model.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<OrderEntity>> _events = {};
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    final box = Hive.box<OrderModel>('orders');
    final orders = box.values.toList();
    
    // Group orders by delivery date
    final Map<DateTime, List<OrderEntity>> events = {};
    for (var order in orders) {
      final date = DateTime(
        order.deliveryDate.year,
        order.deliveryDate.month,
        order.deliveryDate.day,
      );
      if (events[date] == null) {
        events[date] = [];
      }
      events[date]!.add(order);
    }
    
    setState(() {
      _events = events;
    });
  }

  List<OrderEntity> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  bool _hasPendingDeliveries(DateTime day) {
    final orders = _getEventsForDay(day);
    return orders.any((order) => 
      order.deliveryStatus != 'delivered' && order.status != 'Entregado'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Agenda de Entregas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<OrderModel>('orders').listenable(),
        builder: (context, Box<OrderModel> box, _) {
          // Reload orders when data changes (without setState)
          final orders = box.values.toList();
          
          // Group orders by delivery date
          final Map<DateTime, List<OrderEntity>> events = {};
          for (var order in orders) {
            final date = DateTime(
              order.deliveryDate.year,
              order.deliveryDate.month,
              order.deliveryDate.day,
            );
            if (events[date] == null) {
              events[date] = [];
            }
            events[date]!.add(order);
          }
          
          // Update _events without setState since we're in build
          _events = events;
          
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 800;
              
              if (isWideScreen) {
                // Desktop layout: Calendar on left, list on right
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildCalendar(),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 2,
                      child: _buildOrderList(),
                    ),
                  ],
                );
              } else {
                // Mobile layout: Calendar on top, list below
                return Column(
                  children: [
                    _buildCalendar(),
                    const Divider(height: 1),
                    Expanded(child: _buildOrderList()),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildCalendar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? Colors.transparent : Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      child: TableCalendar<OrderEntity>(
        locale: 'es_ES',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          // Text Styles for Dark Mode
          defaultTextStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          weekendTextStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
          outsideTextStyle: TextStyle(color: isDarkMode ? Colors.grey[700] : Colors.grey),

          // Today
          todayDecoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : AppTheme.primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          // Selected day
          selectedDecoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[700] : AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          // Markers
          markerDecoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            
            final hasPending = _hasPendingDeliveries(day);
            return Positioned(
              bottom: 1,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasPending ? (isDarkMode ? Colors.redAccent : Colors.red) : (isDarkMode ? Colors.greenAccent : Colors.green),
                ),
              ),
            );
          },
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.primaryColor,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: isDarkMode ? Colors.white : AppTheme.primaryColor,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: isDarkMode ? Colors.white : AppTheme.primaryColor,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey[400] : Colors.black,
          ),
          weekendStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey[400] : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    final allOrders = _getEventsForDay(_selectedDay);
    
    // Filter orders based on search query
    final orders = allOrders.where((order) {
      if (_searchQuery.isEmpty) return true;
      
      final clientName = order.customerName.toLowerCase();
      final orderId = order.id.toLowerCase();
      final productMatch = order.items.any((item) => 
        item.productName.toLowerCase().contains(_searchQuery)
      );
      
      return clientName.contains(_searchQuery) || 
             orderId.contains(_searchQuery) ||
             productMatch;
    }).toList();
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${orders.length} ${orders.length == 1 ? 'pedido' : 'pedidos'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar entrega...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          const Divider(height: 1),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                                    const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No hay entregas programadas'
                              : 'No hay entregas para "$_searchQuery" este día',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderItem(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderEntity order) {
    final isDelivered = order.deliveryStatus == 'delivered' || order.status == 'Entregado';
    final hasDebt = order.pendingBalance > 0.01;
    
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivered 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDelivered ? 'Entregado' : 'Pendiente',
                    style: TextStyle(
                      color: isDelivered ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} ${order.items.length == 1 ? 'producto' : 'productos'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasDebt)
                  Text(
                    'Pendiente: \$${order.pendingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
