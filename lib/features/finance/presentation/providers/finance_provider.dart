import 'package:flutter/foundation.dart';
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
final expensesProvider = StreamProvider.autoDispose<List<ExpenseModel>>((ref) async* {
  final box = Hive.box<ExpenseModel>('expenses');
  
  Future<List<ExpenseModel>> getProcessedExpenses() async {
    final rawList = box.values.toList();
    return await compute((List<ExpenseModel> expenses) {
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    }, rawList);
  }

  yield await getProcessedExpenses();
  
  await for (final _ in box.watch()) {
    yield await getProcessedExpenses();
  }
});

// Incomes List Provider (Reactive)
final incomesProvider = StreamProvider.autoDispose<List<IncomeModel>>((ref) async* {
  final box = Hive.box<IncomeModel>('incomes');
  
  Future<List<IncomeModel>> getProcessedIncomes() async {
    final rawList = box.values.toList();
    return await compute((List<IncomeModel> incomes) {
      incomes.sort((a, b) => b.date.compareTo(a.date));
      return incomes;
    }, rawList);
  }

  yield await getProcessedIncomes();
  
  await for (final _ in box.watch()) {
    yield await getProcessedIncomes();
  }
});

// Unified Transactions Provider
final unifiedTransactionsProvider = StreamProvider.autoDispose<List<FinancialTransaction>>((ref) async* {
  final selectedDate = ref.watch(selectedDateProvider);
  final filter = ref.watch(financeFilterProvider);
  final expensesBox = Hive.box<ExpenseModel>('expenses');
  final incomesBox = Hive.box<IncomeModel>('incomes');
  final ordersBox = Hive.box<OrderModel>('orders');
  
  Future<List<FinancialTransaction>> getTransactions() async {
    final rawExpenses = expensesBox.values.toList();
    final rawIncomes = incomesBox.values.toList();
    final rawOrders = ordersBox.values.toList();

    return await compute((Map<String, dynamic> data) {
      final sDate = data['selectedDate'] as DateTime;
      final f = data['filter'] as String?;
      final expenses = data['expenses'] as List<ExpenseModel>;
      final incomes = data['incomes'] as List<IncomeModel>;
      final orders = data['orders'] as List<OrderModel>;
      
      final transactions = <FinancialTransaction>[];

      // Add Expenses
      if (f == null || f == 'expense') {
        final monthExpenses = expenses.where((e) {
          return e.date.year == sDate.year && e.date.month == sDate.month;
        });
        for (var e in monthExpenses) {
          transactions.add(FinancialTransaction(
            id: e.id, description: e.description, amount: -e.amount, date: e.date, type: 'expense', category: e.category,
          ));
        }
      }

      // Add Manual Incomes
      if (f == null || f == 'income') {
        final monthIncomes = incomes.where((i) {
          return i.date.year == sDate.year && i.date.month == sDate.month;
        });
        for (var i in monthIncomes) {
          transactions.add(FinancialTransaction(
            id: i.id, description: i.description, amount: i.amount, date: i.date, type: 'income', category: i.category,
          ));
        }

        // Add Order Incomes (Advances/Abonos)
        final monthOrders = orders.where((o) {
          final date = o.saleDate ?? o.deliveryDate;
          return date.year == sDate.year && date.month == sDate.month;
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
      return transactions;
    }, {
      'selectedDate': selectedDate,
      'filter': filter,
      'expenses': rawExpenses,
      'incomes': rawIncomes,
      'orders': rawOrders,
    });
  }

  yield await getTransactions();

  final combinedStream = Rx.merge([
    expensesBox.watch(),
    incomesBox.watch(),
    ordersBox.watch(),
  ]);

  await for (final _ in combinedStream) {
    yield await getTransactions();
  }
});

// Monthly Balance Provider (Reactive)
final monthlyBalanceProvider = StreamProvider.autoDispose<Map<String, double>>((ref) async* {
  final selectedDate = ref.watch(selectedDateProvider);
  final ordersBox = Hive.box<OrderModel>('orders');
  final expensesBox = Hive.box<ExpenseModel>('expenses');
  final incomesBox = Hive.box<IncomeModel>('incomes');

  Future<Map<String, double>> calculateBalance() async {
    final rawOrders = ordersBox.values.toList();
    final rawExpenses = expensesBox.values.toList();
    final rawIncomes = incomesBox.values.toList();

    return await compute((Map<String, dynamic> data) {
      final sDate = data['selectedDate'] as DateTime;
      final orders = data['orders'] as List<OrderModel>;
      final expenses = data['expenses'] as List<ExpenseModel>;
      final incomes = data['incomes'] as List<IncomeModel>;

      final currentMonthExpenses = expenses.where((e) {
        return e.date.year == sDate.year && e.date.month == sDate.month;
      });
      final totalExpenses = currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

      final currentMonthOrders = orders.where((o) {
        final date = o.saleDate ?? o.deliveryDate;
        return date.year == sDate.year && date.month == sDate.month;
      });
      
      double totalOrderIncome = 0.0;
      for (var order in currentMonthOrders) {
        double collected = order.totalPrice - order.pendingBalance;
        if (collected < 0) collected = 0;
        totalOrderIncome += collected;
      }

      final currentMonthIncomes = incomes.where((i) {
        return i.date.year == sDate.year && i.date.month == sDate.month;
      });
      final totalManualIncome = currentMonthIncomes.fold(0.0, (sum, i) => sum + i.amount);

      final totalIncome = totalOrderIncome + totalManualIncome;

      return {
        'income': totalIncome,
        'expenses': totalExpenses,
        'profit': totalIncome - totalExpenses,
      };
    }, {
      'selectedDate': selectedDate,
      'orders': rawOrders,
      'expenses': rawExpenses,
      'incomes': rawIncomes,
    });
  }

  yield await calculateBalance();

  final combinedStream = Rx.merge([
    ordersBox.watch(),
    expensesBox.watch(),
    incomesBox.watch(),
  ]);

  await for (final _ in combinedStream) {
    yield await calculateBalance();
  }
});
