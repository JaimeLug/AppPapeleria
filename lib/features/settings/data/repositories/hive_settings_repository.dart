import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../presentation/providers/settings_provider.dart';

import '../../../../features/sales/data/models/order_model.dart';
import '../../../../features/sales/data/models/customer_model.dart';
import '../../../../features/inventory/data/models/product_model.dart';
import '../../../../features/inventory/data/models/inventory_item_model.dart';
import '../../../../features/inventory/data/models/stock_movement_model.dart';
import '../../../../features/finance/data/models/expense_model.dart';
import '../../../../features/finance/data/models/income_model.dart';

class HiveSettingsRepository implements SettingsRepository {
  final Box _settingsBox;

  HiveSettingsRepository(this._settingsBox);

  @override
  Future<AppSettings> getSettings() async {
    final data = _settingsBox.get('appSettings');
    if (data != null) {
      return AppSettings.fromMap(Map<String, dynamic>.from(data));
    }
    return const AppSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('appSettings', settings.toMap());
  }

  @override
  Future<Map<String, int>> getDatabaseStats() async {
    return {
      'orders': Hive.box<OrderModel>('orders').length,
      'customers': Hive.box<CustomerModel>('customers').length,
      'products': Hive.box<ProductModel>('products').length,
      'inventoryItems': Hive.box<InventoryItemModel>('inventoryItems').length,
      'stockMovements': Hive.box<StockMovementModel>('stockMovements').length,
      'expenses': Hive.box<ExpenseModel>('expenses').length,
      'incomes': Hive.box<IncomeModel>('incomes').length,
    };
  }

  @override
  Future<void> exportBackup(AppSettings currentSettings) async {
    final customersBox = Hive.box<CustomerModel>('customers');
    final ordersBox = Hive.box<OrderModel>('orders');
    final productsBox = Hive.box<ProductModel>('products');
    final expensesBox = Hive.box<ExpenseModel>('expenses');
    final incomesBox = Hive.box<IncomeModel>('incomes');

    final allData = {
      'settings': currentSettings.toMap(),
      'customers': customersBox.values.map((e) => e.toJson()).toList(),
      'orders': ordersBox.values.map((e) => e.toJson()).toList(),
      'products': productsBox.values.map((e) => e.toJson()).toList(),
      'expenses': expensesBox.values.map((e) => e.toJson()).toList(),
      'incomes': incomesBox.values.map((e) => e.toJson()).toList(),
      'backupDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    
    final jsonString = jsonEncode(allData);
    final fileName = 'backup_papeleria_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
    
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar Backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(jsonString);
    }
  }

  @override
  Future<void> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (!data.containsKey('customers') || !data.containsKey('orders')) {
        throw Exception('Formato de backup inválido');
      }

      // Restore logic (simplified for implementation)
      await _restoreBox<CustomerModel>('customers', data['customers'], CustomerModel.fromJson);
      await _restoreBox<OrderModel>('orders', data['orders'], OrderModel.fromJson);
      await _restoreBox<ProductModel>('products', data['products'], ProductModel.fromJson);
      await _restoreBox<ExpenseModel>('expenses', data['expenses'], ExpenseModel.fromJson);
      await _restoreBox<IncomeModel>('incomes', data['incomes'], IncomeModel.fromJson);

      if (data['settings'] != null) {
        await _settingsBox.put('appSettings', data['settings']);
      }
    }
  }

  @override
  Future<void> performAdvancedSync(String mode, AppSettings settings) async {
    // googleService and sheetId were previously used here for Google Sheets sync.

    if (mode == 'incremental_export' || mode == 'overwrite_cloud') {
      // Google Sheets sync is deprecated in favor of Supabase. 
      // This section should be migrated to Supabase bulk operations if needed.
      debugPrint('LOG: Advanced Sync (Sheets) is no longer supported.');
    } else if (mode == 'merge_import' || mode == 'total_restore') {
      debugPrint('LOG: Advanced Sync (Sheets) is no longer supported.');
    }
  }

  Future<void> _restoreBox<T>(String boxName, dynamic jsonData, T Function(Map<String, dynamic>) fromJson) async {
    final box = Hive.box<T>(boxName);
    await box.clear();
    if (jsonData != null) {
      for (var item in (jsonData as List)) {
        final model = fromJson(Map<String, dynamic>.from(item));
        final id = (model as dynamic).id;
        await box.put(id, model);
      }
    }
  }

  @override
  Future<void> factoryReset(String pin) async {
    if (pin != '2308') throw Exception('PIN de Desarrollador incorrecto');
    
    await Hive.box<OrderModel>('orders').clear();
    await Hive.box<CustomerModel>('customers').clear();
    await Hive.box<ProductModel>('products').clear();
    await Hive.box<ExpenseModel>('expenses').clear();
    await Hive.box<IncomeModel>('incomes').clear();
    await Hive.box<InventoryItemModel>('inventoryItems').clear();
    await Hive.box<StockMovementModel>('stockMovements').clear();
    await _settingsBox.clear();
  }
}
