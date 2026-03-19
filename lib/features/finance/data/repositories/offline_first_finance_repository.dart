import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/repositories/finance_repository.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import 'supabase_finance_repository.dart';
import '../../../../core/services/sync_manager.dart';

class OfflineFirstFinanceRepository implements FinanceRepository {
  final SupabaseFinanceRepository _remoteRepo;
  final Box<ExpenseModel> _expenseBox;
  final Box<IncomeModel> _incomeBox;
  final SyncManager _syncManager;

  OfflineFirstFinanceRepository(
    this._remoteRepo,
    this._expenseBox,
    this._incomeBox,
    this._syncManager,
  );

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    final local = _expenseBox.values.toList();
    _fetchRemoteExpenses();
    return local;
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses() async* {
    _fetchRemoteExpenses(); // Background fetch
    yield _expenseBox.values.toList();
    await for (final _ in _expenseBox.watch()) {
      yield _expenseBox.values.toList();
    }
  }

  @override
  Stream<List<IncomeModel>> watchIncomes() async* {
    _fetchRemoteIncomes(); // Background fetch
    yield _incomeBox.values.toList();
    await for (final _ in _incomeBox.watch()) {
      yield _incomeBox.values.toList();
    }
  }

  Future<void> _fetchRemoteExpenses() async {
    try {
      final remote = await _remoteRepo.getExpenses();
      for (var expense in remote) {
        final local = _expenseBox.get(expense.id);
        if (local == null || expense.updatedAt.isAfter(local.updatedAt)) {
          await _expenseBox.put(expense.id, expense);
        }
      }
    } catch (e) {
      debugPrint('Error en fetch remoto de gastos: $e');
    }
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    final model = expense.copyWith(isSynced: false, updatedAt: DateTime.now());
    await _expenseBox.put(model.id, model);
    _syncManager.syncPendingData();
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
    _remoteRepo.deleteExpense(id);
  }

  @override
  Future<List<IncomeModel>> getIncomes() async {
    final local = _incomeBox.values.toList();
    _fetchRemoteIncomes();
    return local;
  }

  Future<void> _fetchRemoteIncomes() async {
    try {
      final remote = await _remoteRepo.getIncomes();
      for (var income in remote) {
        final local = _incomeBox.get(income.id);
        if (local == null || income.updatedAt.isAfter(local.updatedAt)) {
          await _incomeBox.put(income.id, income);
        }
      }
    } catch (e) {
      debugPrint('Error en fetch remoto de ingresos: $e');
    }
  }

  @override
  Future<void> addIncome(IncomeModel income) async {
    final model = IncomeModel(
      id: income.id,
      description: income.description,
      amount: income.amount,
      date: income.date,
      category: income.category,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _incomeBox.put(model.id, model);
    _syncManager.syncPendingData();
  }

  @override
  Future<void> deleteIncome(String id) async {
    await _incomeBox.delete(id);
    _remoteRepo.deleteIncome(id);
  }
}
