import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../../../../core/services/google_cloud_service.dart';

class ExpenseRepository {
  final Box<ExpenseModel> _box;

  ExpenseRepository(this._box);

  List<ExpenseModel> getExpenses() {
    final expenses = _box.values.toList();
    expenses.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
    return expenses;
  }

  List<ExpenseModel> getExpensesByMonth(DateTime month) {
    return _box.values.where((expense) {
      return expense.date.year == month.year && expense.date.month == month.month;
    }).toList();
  }



  Future<void> addExpense(ExpenseModel expense) async {
    await _box.put(expense.id, expense);

    // --- Google Cloud Sync ---
    try {
      final settingsBox = Hive.box('settings');
      final settingsMap = settingsBox.get('appSettings');
      if (settingsMap != null) {
         final settings = Map<String, dynamic>.from(settingsMap);
         if (settings['syncSheetsEnabled'] == true && settings['googleSheetId'] != null) {
            final googleService = GoogleCloudService();
            if (googleService.isAuthenticated) {
               print('LOG: Syncing expense to Sheets...');
               await googleService.appendExpenseToSheet(settings['googleSheetId'], expense);
            }
         }
      }
    } catch (e) {
      print('LOG: Error syncing expense: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
    
    try {
      final googleService = GoogleCloudService();
      if (googleService.isAuthenticated) {
         final settingsBox = Hive.box('settings');
         final settingsMap = settingsBox.get('appSettings');
         if (settingsMap != null) {
           final settings = Map<String, dynamic>.from(settingsMap);
           if (settings['syncSheetsEnabled'] == true && settings['googleSheetId'] != null) {
             final sheetId = settings['googleSheetId'] as String;
             if (sheetId.isNotEmpty) {
               await googleService.deleteRowById(sheetId, 'Gastos', id);
             }
           }
         }
      }
    } catch (e) {
      print('LOG: Error deleting expense from cloud: $e');
    }
  }
}
