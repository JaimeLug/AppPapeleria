import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/repositories/finance_repository.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import 'supabase_finance_repository.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/services/pending_delete_queue.dart';

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
    _fetchRemoteExpenses(); // Fetch inicial inmediato
    final remoteSub = _remoteRepo.watchExpenses().listen(
      _reconcileExpenses,
      onError: (e) => debugPrint('Realtime gastos: $e'),
    );
    yield _expenseBox.values.toList();
    try {
      await for (final _ in _expenseBox.watch()) {
        yield _expenseBox.values.toList();
      }
    } finally {
      await remoteSub.cancel();
    }
  }

  @override
  Stream<List<IncomeModel>> watchIncomes() async* {
    _fetchRemoteIncomes(); // Fetch inicial inmediato
    final remoteSub = _remoteRepo.watchIncomes().listen(
      _reconcileIncomes,
      onError: (e) => debugPrint('Realtime ingresos: $e'),
    );
    yield _incomeBox.values.toList();
    try {
      await for (final _ in _incomeBox.watch()) {
        yield _incomeBox.values.toList();
      }
    } finally {
      await remoteSub.cancel();
    }
  }

  Future<void> _fetchRemoteExpenses() async {
    try {
      final remote = await _remoteRepo.getExpenses();
      await _reconcileExpenses(remote);
    } catch (e) {
      debugPrint('Error en fetch remoto de gastos: $e');
    }
  }

  Future<void> _reconcileExpenses(List<ExpenseModel> remote) async {
    final remoteIds = <String>{};
    for (var expense in remote) {
      remoteIds.add(expense.id);
      final local = _expenseBox.get(expense.id);
      if (local == null || expense.updatedAt.isAfter(local.updatedAt)) {
        await _expenseBox.put(expense.id, expense);
      }
    }
    // Poda segura: solo elimina lo que el servidor confirma como borrado.
    final candidates = _expenseBox.values
        .where((e) => !remoteIds.contains(e.id))
        .map((e) => e.id)
        .toList();
    if (candidates.isNotEmpty) {
      final confirmed = await _remoteRepo.deletedExpenseIdsAmong(candidates);
      for (final id in confirmed) {
        await _expenseBox.delete(id);
      }
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
    await PendingDeleteQueue.add('expense', id);
    await _expenseBox.delete(id);
    _syncManager.syncPendingData();
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
      await _reconcileIncomes(remote);
    } catch (e) {
      debugPrint('Error en fetch remoto de ingresos: $e');
    }
  }

  Future<void> _reconcileIncomes(List<IncomeModel> remote) async {
    final remoteIds = <String>{};
    for (var income in remote) {
      remoteIds.add(income.id);
      final local = _incomeBox.get(income.id);
      if (local == null || income.updatedAt.isAfter(local.updatedAt)) {
        await _incomeBox.put(income.id, income);
      }
    }
    // Poda segura: solo elimina lo que el servidor confirma como borrado.
    final candidates = _incomeBox.values
        .where((i) => !remoteIds.contains(i.id))
        .map((i) => i.id)
        .toList();
    if (candidates.isNotEmpty) {
      final confirmed = await _remoteRepo.deletedIncomeIdsAmong(candidates);
      for (final id in confirmed) {
        await _incomeBox.delete(id);
      }
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
    await PendingDeleteQueue.add('income', id);
    await _incomeBox.delete(id);
    _syncManager.syncPendingData();
  }
}
