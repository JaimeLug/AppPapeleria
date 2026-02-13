import 'package:hive/hive.dart';
import '../models/income_model.dart';
import '../../../../core/services/google_cloud_service.dart';

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

    // --- Google Cloud Sync ---
    try {
      final settingsBox = Hive.box('settings');
      final settingsMap = settingsBox.get('appSettings');
      if (settingsMap != null) {
         final settings = Map<String, dynamic>.from(settingsMap);
         if (settings['syncSheetsEnabled'] == true && settings['googleSheetId'] != null) {
            final googleService = GoogleCloudService();
            if (googleService.isAuthenticated) {
               print('LOG: Syncing income to Sheets...');
               await googleService.appendIncomeToSheet(settings['googleSheetId'], income);
            }
         }
      }
    } catch (e) {
      print('LOG: Error syncing income: $e');
    }
  }

  Future<void> deleteIncome(String id) async {
    await _box.delete(id);
    
    // --- Google Cloud Sync (Delete) ---
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
               await googleService.deleteRowById(sheetId, 'Ingresos', id);
             }
           }
         }
      }
    } catch (e) {
      print('LOG: Error deleting income from cloud: $e');
    }
  }
}
