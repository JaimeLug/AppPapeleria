import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../finance/presentation/providers/date_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../sales/presentation/providers/orders_provider.dart';
import '../../../finance/presentation/providers/finance_provider.dart';
import '../../../sales/domain/entities/order.dart';

class DashboardStats {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double accountsReceivable;
  final int pendingDeliveriesCount;
  final int urgentOrdersCount;
  final List<OrderEntity> nextDeliveries;
  final List<MapEntry<String, int>> topProducts;

  DashboardStats({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.accountsReceivable,
    required this.pendingDeliveriesCount,
    required this.urgentOrdersCount,
    required this.nextDeliveries,
    required this.topProducts,
  });
}

final dashboardStatsProvider = Provider.autoDispose<AsyncValue<DashboardStats>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final settings = ref.watch(settingsProvider);
  
  final ordersAsync = ref.watch(ordersStreamProvider);
  final expensesAsync = ref.watch(expensesProvider);
  final incomesAsync = ref.watch(incomesProvider);

  if (ordersAsync is AsyncLoading || expensesAsync is AsyncLoading || incomesAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  if (ordersAsync is AsyncError) return AsyncError(ordersAsync.error!, ordersAsync.stackTrace!);
  if (expensesAsync is AsyncError) return AsyncError(expensesAsync.error!, expensesAsync.stackTrace!);
  if (incomesAsync is AsyncError) return AsyncError(incomesAsync.error!, incomesAsync.stackTrace!);

  final allOrders = ordersAsync.value ?? [];
  final allExpenses = expensesAsync.value ?? [];
  final allIncomes = incomesAsync.value ?? [];

  // 1. Filtered Lists (by Selected Month)
  final monthOrders = allOrders.where((o) {
    final date = o.saleDate ?? o.deliveryDate;
    return date.year == selectedDate.year && date.month == selectedDate.month;
  }).toList();

  final monthExpenses = allExpenses.where((e) {
    return e.date.year == selectedDate.year && e.date.month == selectedDate.month;
  }).toList();

  final monthIncomes = allIncomes.where((i) {
    return i.date.year == selectedDate.year && i.date.month == selectedDate.month;
  }).toList();

  // 2. Financials
  double incomeFromOrders = 0.0;
  for (var o in monthOrders) {
    double collected = o.totalPrice - o.pendingBalance;
    if (collected < 0) collected = 0;
    incomeFromOrders += collected;
  }

  double incomeManual = monthIncomes.fold(0.0, (sum, i) => sum + i.amount);

  final totalIncome = incomeFromOrders + incomeManual;
  final totalExpenses = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
  final netProfit = totalIncome - totalExpenses;

  // 3. Accounts Receivable
  final double accountsReceivable = allOrders.fold(0.0, (sum, o) => sum + o.pendingBalance);

  // 4. Pending Deliveries & Urgent
  final pendingDeliveries = allOrders.where((o) => o.deliveryStatus == 'pending').toList();
  final pendingDeliveriesCount = pendingDeliveries.length;
  
  // Urgent Calculation
  final now = DateTime.now();
  final urgentOrdersCount = pendingDeliveries.where((o) {
    final difference = o.deliveryDate.difference(now).inDays;
    return difference >= 0 && difference <= settings.urgentOrderThresholdDays;
  }).length;

  // 5. Next 3 Deliveries
  final nextDeliveriesList = List<OrderEntity>.from(pendingDeliveries);
  nextDeliveriesList.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
  final nextDeliveries = nextDeliveriesList.take(3).toList();

  // 6. Top Products
  final productCounts = <String, int>{};
  for (var o in monthOrders) {
    for (var item in o.items) {
      productCounts[item.productName] = (productCounts[item.productName] ?? 0) + item.quantity.toInt();
    }
  }
  final sortedProducts = productCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topProducts = sortedProducts.take(3).toList();

  return AsyncData(DashboardStats(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    accountsReceivable: accountsReceivable,
    pendingDeliveriesCount: pendingDeliveriesCount,
    urgentOrdersCount: urgentOrdersCount,
    nextDeliveries: nextDeliveries,
    topProducts: topProducts,
  ));
});
