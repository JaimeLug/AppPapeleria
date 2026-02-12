import 'package:hive/hive.dart';
import '../models/income_model.dart';

class IncomeRepository {
  final Box<IncomeModel> _box;

  IncomeRepository(this._box);

  List<IncomeModel> getIncomes() {
    final incomes = _box.values.toList();
    incomes.sort((a, b) => b.date.compareTo(a.date));
    return incomes;
  }

  List<IncomeModel> getIncomesByMonth(DateTime month) {
    return _box.values.where((income) {
      return income.date.year == month.year && income.date.month == month.month;
    }).toList();
  }

  Future<void> addIncome(IncomeModel income) async {
    await _box.put(income.id, income);
  }

  Future<void> deleteIncome(String id) async {
    await _box.delete(id);
  }
}
