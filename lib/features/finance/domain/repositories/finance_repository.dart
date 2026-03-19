import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';

abstract class FinanceRepository {
  Future<List<ExpenseModel>> getExpenses();
  Stream<List<ExpenseModel>> watchExpenses();
  Future<void> addExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  
  Future<List<IncomeModel>> getIncomes();
  Stream<List<IncomeModel>> watchIncomes();
  Future<void> addIncome(IncomeModel income);
  Future<void> deleteIncome(String id);
}
