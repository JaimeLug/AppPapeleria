import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';

import '../../../sales/presentation/providers/orders_provider.dart';
import '../providers/date_provider.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../data/repositories/offline_first_finance_repository.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/providers/remote_repositories_providers.dart';

// Filter Provider
final financeFilterProvider = StateProvider<String?>((ref) => null); // null, 'income', 'expense'

// Repository
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final expenseBox = Hive.box<ExpenseModel>('expenses');
  final incomeBox = Hive.box<IncomeModel>('incomes');
  final remoteRepo = ref.watch(remoteFinanceRepositoryProvider);
  final syncManager = ref.watch(syncManagerProvider);

  return OfflineFirstFinanceRepository(
    remoteRepo,
    expenseBox,
    incomeBox,
    syncManager,
  );
});

// Expenses List Provider (Reactive)
final expensesProvider = StreamProvider.autoDispose<List<ExpenseModel>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.watchExpenses().asyncMap((expenses) async {
    return await compute((List<ExpenseModel> list) {
      final sorted = List<ExpenseModel>.from(list);
      sorted.sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    }, expenses);
  });
});

// Incomes List Provider (Reactive)
final incomesProvider = StreamProvider.autoDispose<List<IncomeModel>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.watchIncomes().asyncMap((incomes) async {
    return await compute((List<IncomeModel> list) {
      final sorted = List<IncomeModel>.from(list);
      sorted.sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    }, incomes);
  });
});

// Unified Transactions Provider
final unifiedTransactionsProvider = Provider.autoDispose<AsyncValue<List<FinancialTransaction>>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final filter = ref.watch(financeFilterProvider);
  
  final expensesAsync = ref.watch(expensesProvider);
  final incomesAsync = ref.watch(incomesProvider);
  final ordersAsync = ref.watch(ordersStreamProvider);

  if (expensesAsync is AsyncLoading || incomesAsync is AsyncLoading || ordersAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  final expenses = expensesAsync.value ?? [];
  final incomes = incomesAsync.value ?? [];
  final orders = ordersAsync.value ?? [];

  final transactions = <FinancialTransaction>[];

  // Add Expenses
  if (filter == null || filter == 'expense') {
    final monthExpenses = expenses.where((e) {
      return e.date.year == selectedDate.year && e.date.month == selectedDate.month;
    });
    for (var e in monthExpenses) {
      transactions.add(FinancialTransaction(
        id: e.id, description: e.description, amount: -e.amount, date: e.date, type: 'expense', category: e.category,
      ));
    }
  }

  // Add Manual Incomes
  if (filter == null || filter == 'income') {
    final monthIncomes = incomes.where((i) {
      return i.date.year == selectedDate.year && i.date.month == selectedDate.month;
    });
    for (var i in monthIncomes) {
      transactions.add(FinancialTransaction(
        id: i.id, description: i.description, amount: i.amount, date: i.date, type: 'income', category: i.category,
      ));
    }

    // Add Order Incomes (Advances/Abonos)
    final monthOrders = orders.where((o) {
      final date = o.saleDate ?? o.deliveryDate;
      return date.year == selectedDate.year && date.month == selectedDate.month;
    });
    for (var o in monthOrders) {
      double collected = o.totalPrice - o.pendingBalance;
      if (collected > 0.01) {
        transactions.add(FinancialTransaction(
          id: 'order_${o.id}', description: 'Venta - ${o.customerName}', amount: collected, date: o.saleDate ?? o.deliveryDate, type: 'income', category: 'Pedido',
        ));
      }
    }
  }

  transactions.sort((a, b) => b.date.compareTo(a.date));
  return AsyncData(transactions);
});

// Monthly Balance Provider (Reactive)
final monthlyBalanceProvider = Provider.autoDispose<AsyncValue<Map<String, double>>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  
  final expensesAsync = ref.watch(expensesProvider);
  final incomesAsync = ref.watch(incomesProvider);
  final ordersAsync = ref.watch(ordersStreamProvider);

  if (expensesAsync is AsyncLoading || incomesAsync is AsyncLoading || ordersAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  final expenses = expensesAsync.value ?? [];
  final incomes = incomesAsync.value ?? [];
  final orders = ordersAsync.value ?? [];

  final currentMonthExpenses = expenses.where((e) {
    return e.date.year == selectedDate.year && e.date.month == selectedDate.month;
  });
  final totalExpenses = currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

  final currentMonthOrders = orders.where((o) {
    final date = o.saleDate ?? o.deliveryDate;
    return date.year == selectedDate.year && date.month == selectedDate.month;
  });
  
  double totalOrderIncome = 0.0;
  for (var order in currentMonthOrders) {
    double collected = order.totalPrice - order.pendingBalance;
    if (collected < 0) collected = 0;
    totalOrderIncome += collected;
  }

  final currentMonthIncomes = incomes.where((i) {
    return i.date.year == selectedDate.year && i.date.month == selectedDate.month;
  });
  final totalManualIncome = currentMonthIncomes.fold(0.0, (sum, i) => sum + i.amount);

  final totalIncome = totalOrderIncome + totalManualIncome;

  return AsyncData({
    'income': totalIncome,
    'expenses': totalExpenses,
    'profit': totalIncome - totalExpenses,
  });
});
