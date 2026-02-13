import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
// ignore: unused_import
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../../../features/sales/data/models/order_model.dart';
import '../../../../features/sales/data/models/customer_model.dart';
import '../../../../features/inventory/data/models/product_model.dart';
import '../../../../features/finance/data/models/expense_model.dart';
import '../../../../features/finance/data/models/income_model.dart';

// --- State Model ---
import '../../../../features/dashboard/domain/models/dashboard_widget_config.dart';

// --- State Model ---
class AppSettings {
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessSocials;
  final String receiptFooterMessage;
  final bool isDarkMode;
  final int urgentOrderThresholdDays;
  final String? securityPin;
  
  // Dashboard Personalization
  final String dashboardWelcomeTitle;
  final String dashboardWelcomeSubtitle;
  
  // Google Cloud Integration
  final String? googleClientId;
  final String? googleClientSecret;
  final String? googleSheetId;
  final bool syncSheetsEnabled;
  final bool syncCalendarEnabled;
  final Map<String, String> dashboardTitles;
  final List<String> productCategories;
  
  // Phase 19.2: Changed from List<String> to List<DashboardWidgetConfig>
  final List<DashboardWidgetConfig>? dashboardLayout;
  
  final String quickNoteContent;

  const AppSettings({
    this.businessName = 'Corateca.',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessSocials = '',
    this.receiptFooterMessage = '¡Gracias por tu compra!',
    this.isDarkMode = false,
    this.urgentOrderThresholdDays = 3,
    this.securityPin,
    this.dashboardWelcomeTitle = '¡Hola, crea magia hoy! ✨',
    this.dashboardWelcomeSubtitle = 'Resumen de tu papelería creativa',
    this.googleClientId,
    this.googleClientSecret,
    this.googleSheetId = '1nDpb3WlAhD-XtIvx_CPuM87UlDntvhY1NxCr_XapM8w',
    this.syncSheetsEnabled = false,
    this.syncCalendarEnabled = false,
    this.dashboardTitles = const {
      'orders': 'Próximas Entregas',
      'metrics': 'Resumen del Negocio',
      'summary': 'Estado de Pedidos',
    },
    this.productCategories = const [],
    this.dashboardLayout,
    this.quickNoteContent = '',
  });

  AppSettings copyWith({
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessSocials,
    String? receiptFooterMessage,
    bool? isDarkMode,
    int? urgentOrderThresholdDays,
    String? securityPin,
    String? dashboardWelcomeTitle,
    String? dashboardWelcomeSubtitle,
    String? googleClientId,
    String? googleClientSecret,
    String? googleSheetId,
    bool? syncSheetsEnabled,
    bool? syncCalendarEnabled,
    Map<String, String>? dashboardTitles,
    List<String>? productCategories,
    List<DashboardWidgetConfig>? dashboardLayout,
    String? quickNoteContent,
  }) {
    return AppSettings(
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessSocials: businessSocials ?? this.businessSocials,
      receiptFooterMessage: receiptFooterMessage ?? this.receiptFooterMessage,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      urgentOrderThresholdDays: urgentOrderThresholdDays ?? this.urgentOrderThresholdDays,
      securityPin: securityPin ?? this.securityPin,
      dashboardWelcomeTitle: dashboardWelcomeTitle ?? this.dashboardWelcomeTitle,
      dashboardWelcomeSubtitle: dashboardWelcomeSubtitle ?? this.dashboardWelcomeSubtitle,
      googleClientId: googleClientId ?? this.googleClientId,
      googleClientSecret: googleClientSecret ?? this.googleClientSecret,
      googleSheetId: googleSheetId ?? this.googleSheetId,
      syncSheetsEnabled: syncSheetsEnabled ?? this.syncSheetsEnabled,
      syncCalendarEnabled: syncCalendarEnabled ?? this.syncCalendarEnabled,
      dashboardTitles: dashboardTitles ?? this.dashboardTitles,
      productCategories: productCategories ?? this.productCategories,
      dashboardLayout: dashboardLayout ?? this.dashboardLayout,
      quickNoteContent: quickNoteContent ?? this.quickNoteContent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessSocials': businessSocials,
      'receiptFooterMessage': receiptFooterMessage,
      'isDarkMode': isDarkMode,
      'urgentOrderThresholdDays': urgentOrderThresholdDays,
      'securityPin': securityPin,
      'dashboardWelcomeTitle': dashboardWelcomeTitle,
      'dashboardWelcomeSubtitle': dashboardWelcomeSubtitle,
      'googleClientId': googleClientId,
      'googleClientSecret': googleClientSecret,
      'googleSheetId': googleSheetId,
      'syncSheetsEnabled': syncSheetsEnabled,
      'syncCalendarEnabled': syncCalendarEnabled,
      'dashboardTitles': dashboardTitles,
      'productCategories': productCategories,
      'dashboardLayout': dashboardLayout?.map((e) => e.toMap()).toList(),
      'quickNoteContent': quickNoteContent,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    // Migration Logic
    List<DashboardWidgetConfig>? layout;
    if (map['dashboardLayout'] != null) {
      final rawLayout = map['dashboardLayout'] as List;
      if (rawLayout.isNotEmpty) {
        if (rawLayout.first is String) {
          // Migration: Convert List<String> to List<DashboardWidgetConfig>
          layout = rawLayout.map((id) => DashboardWidgetConfig(id: id as String)).toList();
        } else {
          // Standard: List<Map>
          layout = rawLayout.map((e) => DashboardWidgetConfig.fromMap(Map<String, dynamic>.from(e))).toList();
        }
      } else {
        layout = [];
      }
    }

    return AppSettings(
      businessName: map['businessName'] ?? 'Corateca.',
      businessAddress: map['businessAddress'] ?? '',
      businessPhone: map['businessPhone'] ?? '',
      businessSocials: map['businessSocials'] ?? '',
      receiptFooterMessage: map['receiptFooterMessage'] ?? '¡Gracias por tu compra!',
      isDarkMode: map['isDarkMode'] ?? false,
      urgentOrderThresholdDays: map['urgentOrderThresholdDays'] ?? 3,
      securityPin: map['securityPin'],
      dashboardWelcomeTitle: map['dashboardWelcomeTitle'] ?? '¡Hola, crea magia hoy! ✨',
      dashboardWelcomeSubtitle: map['dashboardWelcomeSubtitle'] ?? 'Resumen de tu papelería creativa',
      googleClientId: map['googleClientId'],
      googleClientSecret: map['googleClientSecret'],
      googleSheetId: map['googleSheetId'] ?? '1nDpb3WlAhD-XtIvx_CPuM87UlDntvhY1NxCr_XapM8w',
      syncSheetsEnabled: map['syncSheetsEnabled'] ?? false,
      syncCalendarEnabled: map['syncCalendarEnabled'] ?? false,
      dashboardTitles: map['dashboardTitles'] != null ? Map<String, String>.from(map['dashboardTitles']) : const {
        'orders': 'Próximas Entregas',
        'metrics': 'Resumen del Negocio',
        'summary': 'Estado de Pedidos',
      },
      productCategories: map['productCategories'] != null ? List<String>.from(map['productCategories']) : const [],
      dashboardLayout: layout,
      quickNoteContent: map['quickNoteContent'] ?? '',
    );
  }
}

// --- Notifier ---
class SettingsNotifier extends StateNotifier<AppSettings> {
  final Box _box;

  SettingsNotifier(this._box) : super(const AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final data = _box.get('appSettings');
    if (data != null) {
      final map = Map<String, dynamic>.from(data);
      state = AppSettings.fromMap(map);
    }
  }

  Future<void> _saveSettings() async {
    await _box.put('appSettings', state.toMap());
  }

  // Actions
  void updateBusinessInfo({
    String? name,
    String? address,
    String? phone,
    String? socials,
    String? footerMessage,
  }) {
    state = state.copyWith(
      businessName: name,
      businessAddress: address,
      businessPhone: phone,
      businessSocials: socials,
      receiptFooterMessage: footerMessage,
    );
    _saveSettings();
  }

  void toggleTheme(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
    _saveSettings();
  }

  void setUrgentThreshold(int days) {
    state = state.copyWith(urgentOrderThresholdDays: days);
    _saveSettings();
  }

  void setSecurityPin(String? pin) {
    state = state.copyWith(securityPin: pin);
    _saveSettings();
  }
  
  void removeSecurityPin(String currentPin) {
    if (state.securityPin == currentPin) {
      state = state.copyWith(securityPin: null);
      _saveSettings();
    } else {
      throw Exception('PIN incorrecto');
    }
  }

  // Google Cloud Actions
  void updateGoogleConfig({
    String? clientId,
    String? clientSecret,
    String? sheetId,
    bool? syncSheets,
    bool? syncCalendar,
  }) {
    state = state.copyWith(
      googleClientId: clientId,
      googleClientSecret: clientSecret,
      googleSheetId: sheetId,
      syncSheetsEnabled: syncSheets,
      syncCalendarEnabled: syncCalendar,
    );
    _saveSettings();
  }
 
  void updateDashboardTitles(Map<String, String> titles) {
    state = state.copyWith(dashboardTitles: titles);
    _saveSettings();
  }

  void updateDashboardWelcome({String? title, String? subtitle}) {
    state = state.copyWith(
      dashboardWelcomeTitle: title,
      dashboardWelcomeSubtitle: subtitle,
    );
    _saveSettings();
  }

  void updateDashboardLayout(List<DashboardWidgetConfig> layout) {
    state = state.copyWith(dashboardLayout: layout);
    _saveSettings();
  }

  void updateQuickNote(String content) {
    state = state.copyWith(quickNoteContent: content);
    _saveSettings();
  }

  // --- Developer Tools ---

  Future<void> exportBackup() async {
    try {
      // 1. Gather all data
      final customersBox = Hive.box<CustomerModel>('customers');
      final ordersBox = Hive.box<OrderModel>('orders');
      final productsBox = Hive.box<ProductModel>('products');
      final expensesBox = Hive.box<ExpenseModel>('expenses');
      final incomesBox = Hive.box<IncomeModel>('incomes');

      final allData = {
        'settings': _box.get('appSettings') ?? state.toMap(),
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
    } catch (e) {
      print('Backup Failed: $e');
      rethrow;
    }
  }
  
  Future<void> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        // Validation (Basic)
        if (!data.containsKey('customers') || !data.containsKey('orders')) {
          throw Exception('Formato de backup inválido');
        }

        // Clear and Restore
        // 1. Customers
        final customersBox = Hive.box<CustomerModel>('customers');
        await customersBox.clear();
        for (var item in (data['customers'] as List)) {
          final model = CustomerModel.fromJson(item);
          await customersBox.put(model.id, model);
        }

        // 2. Orders
        final ordersBox = Hive.box<OrderModel>('orders');
        await ordersBox.clear();
        for (var item in (data['orders'] as List)) {
          final model = OrderModel.fromJson(item);
          await ordersBox.put(model.id, model);
        }
        
        // 3. Products
        final productsBox = Hive.box<ProductModel>('products');
        await productsBox.clear();
        for (var item in (data['products'] as List)) {
          final model = ProductModel.fromJson(item);
          await productsBox.put(model.id, model);
        }
        
        // 4. Expenses
        final expensesBox = Hive.box<ExpenseModel>('expenses');
        await expensesBox.clear();
        if (data['expenses'] != null) {
          for (var item in (data['expenses'] as List)) {
             final model = ExpenseModel.fromJson(item);
             await expensesBox.put(model.id, model);
          }
        }
        
        // 5. Incomes
        final incomesBox = Hive.box<IncomeModel>('incomes');
        await incomesBox.clear();
        if (data['incomes'] != null) {
          for (var item in (data['incomes'] as List)) {
             final model = IncomeModel.fromJson(item);
             await incomesBox.put(model.id, model);
          }
        }

        // 6. Settings
        if (data['settings'] != null) {
          final map = Map<String, dynamic>.from(data['settings']);
          state = AppSettings.fromMap(map);
          await _saveSettings();
        }
      }
    } catch (e) {
      print('Start Import Failed: $e');
      rethrow;
    }
  }

  Future<void> factoryReset(String pin) async {
    if (pin != '2308') {
      throw Exception('PIN de Desarrollador incorrecto');
    }
    
    // Clear Google Cloud credentials
    await _box.delete('googleAccessCredentials');
    
    await _box.clear();
    await Hive.box<CustomerModel>('customers').clear();
    await Hive.box<OrderModel>('orders').clear();
    await Hive.box<ProductModel>('products').clear();
    await Hive.box<ExpenseModel>('expenses').clear();
    await Hive.box<IncomeModel>('incomes').clear();
    state = const AppSettings(); // Reset state
  }
}

// --- Provider ---
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final box = Hive.box('settings');
  return SettingsNotifier(box);
});
