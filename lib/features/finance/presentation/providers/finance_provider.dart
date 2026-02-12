import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/income_repository.dart';
import '../../../sales/data/models/order_model.dart';
import '../providers/date_provider.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../../sales/domain/entities/order.dart';

// Filter Provider
final financeFilterProvider = StateProvider<String?>((ref) => null); // null, 'income', 'expense'

// Repositories
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final box = Hive.box<ExpenseModel>('expenses');
  return ExpenseRepository(box);
});

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  final box = Hive.box<IncomeModel>('incomes');
  return IncomeRepository(box);
});

// Expenses List Provider (Reactive)
final expensesProvider = StreamProvider.autoDispose<List<ExpenseModel>>((ref) {
  final box = Hive.box<ExpenseModel>('expenses');
  
  Stream<List<ExpenseModel>> getStream() {
    return box.watch().map((event) {
      final expenses = box.values.toList();
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    });
  }

  final initial = box.values.toList();
  initial.sort((a, b) => b.date.compareTo(a.date));

  return Stream.value(initial).concatWith([getStream()]);
});

// Incomes List Provider (Reactive)
final incomesProvider = StreamProvider.autoDispose<List<IncomeModel>>((ref) {
  final box = Hive.box<IncomeModel>('incomes');
  
  Stream<List<IncomeModel>> getStream() {
    return box.watch().map((event) {
      final incomes = box.values.toList();
      incomes.sort((a, b) => b.date.compareTo(a.date));
      return incomes;
    });
  }

  final initial = box.values.toList();
  initial.sort((a, b) => b.date.compareTo(a.date));

  return Stream.value(initial).concatWith([getStream()]);
});

// Unified Transactions Provider
final unifiedTransactionsProvider = StreamProvider.autoDispose<List<FinancialTransaction>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final filter = ref.watch(financeFilterProvider);
  final expensesBox = Hive.box<ExpenseModel>('expenses');
  final incomesBox = Hive.box<IncomeModel>('incomes');
  final ordersBox = Hive.box<OrderModel>('orders');
  
  List<FinancialTransaction> getTransactions() {
    final transactions = <FinancialTransaction>[];

    // Add Expenses
    if (filter == null || filter == 'expense') {
      final monthExpenses = expensesBox.values.where((e) {
        return e.date.year == selectedDate.year && e.date.month == selectedDate.month;
      });
      
      for (var e in monthExpenses) {
        transactions.add(FinancialTransaction(
          id: e.id,
          description: e.description,
          amount: -e.amount, // Negative for expense
          date: e.date,
          type: 'expense',
          category: e.category,
        ));
      }
    }

    // Add Manual Incomes
    if (filter == null || filter == 'income') {
      final monthIncomes = incomesBox.values.where((i) {
        return i.date.year == selectedDate.year && i.date.month == selectedDate.month;
      });

      for (var i in monthIncomes) {
        transactions.add(FinancialTransaction(
          id: i.id,
          description: i.description,
          amount: i.amount,
          date: i.date,
          type: 'income',
          category: i.category,
        ));
      }

      // Add Order Incomes (Advances/Abonos)
      final monthOrders = ordersBox.values.where((o) {
        final date = o.saleDate ?? o.deliveryDate;
        return date.year == selectedDate.year && date.month == selectedDate.month;
      });

      for (var o in monthOrders) {
        double collected = o.totalPrice - o.pendingBalance;
        if (collected > 0.01) {
          transactions.add(FinancialTransaction(
            id: 'order_${o.id}',
            description: 'Venta - ${o.customerName}',
            amount: collected,
            date: o.saleDate ?? o.deliveryDate,
            type: 'income',
            category: 'Pedido',
          ));
        }
      }
    }

    // Sort descending
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  return Stream.fromIterable([getTransactions()]).mergeWith([
    expensesBox.watch().map((_) => getTransactions()),
    incomesBox.watch().map((_) => getTransactions()),
    ordersBox.watch().map((_) => getTransactions()),
  ]);
});

// Monthly Balance Provider (Reactive)
final monthlyBalanceProvider = StreamProvider.autoDispose<Map<String, double>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider); // Watch selected date
  final ordersBox = Hive.box<OrderModel>('orders');
  final expensesBox = Hive.box<ExpenseModel>('expenses');
  final incomesBox = Hive.box<IncomeModel>('incomes');

  // Helper to calculate balance
  Map<String, double> calculateBalance() {
    // Use selectedDate instead of DateTime.now()
    
    // Expenses
    final currentMonthExpenses = expensesBox.values.where((e) {
      return e.date.year == selectedDate.year && e.date.month == selectedDate.month;
    });
    final totalExpenses = currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Incomes from Orders
    final currentMonthOrders = ordersBox.values.where((o) {
      final date = o.saleDate ?? o.deliveryDate;
      return date.year == selectedDate.year && date.month == selectedDate.month;
    });
    
    double totalOrderIncome = 0.0;
    for (var order in currentMonthOrders) {
      // Logic: Collected = Total - Pending.
      double collected = order.totalPrice - order.pendingBalance;
      if (collected < 0) collected = 0;
      totalOrderIncome += collected;
    }

    // Manual Incomes
    final currentMonthIncomes = incomesBox.values.where((i) {
      return i.date.year == selectedDate.year && i.date.month == selectedDate.month;
    });
    final totalManualIncome = currentMonthIncomes.fold(0.0, (sum, i) => sum + i.amount);

    final totalIncome = totalOrderIncome + totalManualIncome;

    return {
      'income': totalIncome,
      'expenses': totalExpenses,
      'profit': totalIncome - totalExpenses,
    };
  }

  // Combine streams from all 3 boxes
  return Stream.fromIterable([calculateBalance()]).mergeWith([
    ordersBox.watch().map((_) => calculateBalance()),
    expensesBox.watch().map((_) => calculateBalance()),
    incomesBox.watch().map((_) => calculateBalance()),
  ]);
});
