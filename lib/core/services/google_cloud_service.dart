import 'dart:convert';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../exceptions/auth_exception.dart';

// Feature imports with correct paths
import '../../features/sales/domain/entities/order.dart';
import '../../features/sales/data/models/order_model.dart';
import '../../features/sales/data/models/order_item_model.dart';
import '../../features/sales/data/models/customer_model.dart';
import '../../features/finance/data/models/expense_model.dart';
import '../../features/inventory/data/models/product_model.dart';
import '../../features/inventory/domain/entities/product.dart';
import '../../features/finance/data/models/income_model.dart';
import 'package:uuid/uuid.dart';
import '../../features/sales/domain/entities/customer.dart';

class GoogleCloudService {
  static final GoogleCloudService _instance = GoogleCloudService._internal();
  factory GoogleCloudService() => _instance;
  GoogleCloudService._internal();

  AuthClient? _client;
  final _scopes = [
    sheets.SheetsApi.spreadsheetsScope,
    calendar.CalendarApi.calendarScope,
  ];

  static const _credentialsKey = 'google_credentials';

  bool get isAuthenticated => _client != null;

  /// Initialize and authenticate with Google
  Future<bool> authenticate() async {
    try {
      final settingsBox = Hive.box('settings');
      final settingsMap = settingsBox.get('appSettings');
      if (settingsMap == null) return false;
      
      final settings = Map<String, dynamic>.from(settingsMap);
      final clientId = settings['googleClientId'];
      final clientSecret = settings['googleClientSecret'];

      if (clientId == null || clientSecret == null) {
        print('Google Client ID o Secret no configurados');
        return false;
      }

      final identifier = ClientId(clientId, clientSecret);

      _client = await clientViaUserConsent(identifier, _scopes, (url) {
        launchUrl(Uri.parse(url));
      });

      if (_client != null) {
        await _saveCredentials(_client!.credentials);
        print('Autenticación exitosa con Google Cloud');
        return true;
      }
      return false;
    } catch (e) {
      print('Error de autenticación: $e');
      return false;
    }
  }

  /// Load stored credentials from Hive and authenticate
  Future<bool> authenticateFromStoredCredentials() async {
    try {
      final settingsBox = Hive.box('settings');
      final credentialsJson = settingsBox.get(_credentialsKey);
      
      if (credentialsJson == null) return false;

      final settingsMap = settingsBox.get('appSettings');
      if (settingsMap == null) return false;
      
      final settings = Map<String, dynamic>.from(settingsMap);
      final clientId = settings['googleClientId'];
      final clientSecret = settings['googleClientSecret'];

      if (clientId == null || clientSecret == null) return false;

      final credentialsMap = json.decode(credentialsJson as String);
      final credentials = AccessCredentials(
        AccessToken(
          credentialsMap['accessToken']['type'],
          credentialsMap['accessToken']['data'],
          DateTime.parse(credentialsMap['accessToken']['expiry']),
        ),
        credentialsMap['refreshToken'],
        _scopes,
      );

      final identifier = ClientId(clientId, clientSecret);
      _client = authenticatedClient(http.Client(), credentials);
      print('Sesión restaurada exitosamente');
      return true;
    } catch (e) {
      print('Error restaurando sesión: $e');
      return false;
    }
  }

  /// Save credentials to Hive
  Future<void> _saveCredentials(AccessCredentials credentials) async {
    final credentialsMap = {
      'accessToken': {
        'type': credentials.accessToken.type,
        'data': credentials.accessToken.data,
        'expiry': credentials.accessToken.expiry.toIso8601String(),
      },
      'refreshToken': credentials.refreshToken,
    };

    final settingsBox = Hive.box('settings');
    await settingsBox.put(_credentialsKey, json.encode(credentialsMap));
  }

  /// Logout and clear credentials
  Future<void> logout() async {
    try {
      _client?.close();
      _client = null;
      final settingsBox = Hive.box('settings');
      await settingsBox.delete(_credentialsKey);
      print('Sesión cerrada y credenciales eliminadas');
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // --- Sheets Utility Methods ---

  Future<void> clearSheet(String spreadsheetId, String sheetName) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    final sheetsApi = sheets.SheetsApi(_client!);
    try {
      await sheetsApi.spreadsheets.values.clear(sheets.ClearValuesRequest(), spreadsheetId, '$sheetName!A2:Z1000');
      print('Hoja $sheetName limpiada');
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in clearSheet: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      if (_isMissingSheetError(e)) {
        print('Hoja $sheetName no existe, omitiendo limpieza');
        return; // Not an error - sheet doesn't exist yet
      }
      print('Error limpiando hoja $sheetName: $e');
    }
  }

  Future<Set<String>> _getExistingIds(String spreadsheetId, String sheetName) async {
    if (_client == null || spreadsheetId.isEmpty) return {};
    final sheetsApi = sheets.SheetsApi(_client!);
    try {
      final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, '$sheetName!A2:A');
      if (res.values == null) return {};
      return res.values!.map((row) => row[0].toString()).toSet();
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in _getExistingIds: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      if (_isMissingSheetError(e)) {
        print('Hoja $sheetName no encontrada, asumiendo vacía');
        return {}; // Sheet doesn't exist - return empty set
      }
      print('Error obteniendo IDs de $sheetName: $e');
      return {};
    }
  }

  // --- Deletion Logic ---

  Future<void> deleteRowById(String spreadsheetId, String sheetTitle, String id) async {
    if (_client == null || spreadsheetId.isEmpty || id.isEmpty) return;
    
    final sheetsApi = sheets.SheetsApi(_client!);
    
    try {
      // 1. Get sheetId (integer) from sheetTitle
      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      final sheet = spreadsheet.sheets?.firstWhere(
        (s) => s.properties?.title == sheetTitle,
        orElse: () => sheets.Sheet(),
      );
      
      final sheetId = sheet?.properties?.sheetId;
      if (sheetId == null) {
        print('Hoja "$sheetTitle" no encontrada para eliminación.');
        return;
      }

      // 2. Find row index (fetch Column A)
      // Note: We fetch A:A roughly. A1 is header. A2 starts data.
      // API returns values. Index 0 of values corresponds to the range start.
      // If we ask for A:A, values[0] is A1.
      final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, '$sheetTitle!A:A');
      final values = res.values;
      
      if (values == null || values.isEmpty) {
        print('Hoja "$sheetTitle" vacía o sin datos en Columna A.');
        return;
      }

      // Find the index of the row with matching ID
      // We look for strict string equality
      int rowIndex = -1;
      for (int i = 0; i < values.length; i++) {
        if (values[i].isNotEmpty && values[i][0].toString() == id) {
          rowIndex = i; // This is the 0-based index in the 'values' list, which maps to row 'i' in the sheet (0-indexed for API)
          break;
        }
      }

      if (rowIndex == -1) {
        print('ID "$id" no encontrado en hoja "$sheetTitle".');
        return;
      }

      // 3. Execute BatchUpdate with DeleteDimension
      final deleteRequest = sheets.DeleteDimensionRequest(
        range: sheets.DimensionRange(
          sheetId: sheetId,
          dimension: 'ROWS',
          startIndex: rowIndex,
          endIndex: rowIndex + 1,
        ),
      );

      final batchUpdate = sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(deleteDimension: deleteRequest),
        ],
      );

      await sheetsApi.spreadsheets.batchUpdate(batchUpdate, spreadsheetId);
      print('Fila con ID "$id" eliminada de "$sheetTitle" (Row ${rowIndex + 1}).');

    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in deleteRowById: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error eliminando fila en Sheets: $e');
      // We do not rethrow strictly, to Avoid crashing local app flow, 
      // but Repository might handle it if we did. The plan said "notify error but don't stop local delete".
      // We'll just log it here as "Error ignored remotely" or throw if we want the caller to know.
      // For now, let's print.
    }
  }

  // --- Legacy Single-Item Methods (for real-time sync) ---

  Future<void> appendOrderToSheet(String spreadsheetId, OrderEntity order) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    try {
      final sheetName = 'Pedidos';
      final headers = ['ID', 'Fecha', 'Cliente', 'Productos', 'Total', 'Anticipo', 'Saldo', 'Fecha Entrega', 'Estado'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);

      final row = [
        order.id,
        (order.saleDate ?? DateTime.now()).toIso8601String().split('T')[0],
        order.customerName,
        order.items.map((i) => '${i.quantity}x ${i.productName}').join(', '),
        order.totalPrice.toStringAsFixed(2),
        (order.totalPrice - order.pendingBalance).toStringAsFixed(2),
        order.pendingBalance.toStringAsFixed(2),
        order.deliveryDate.toIso8601String().split('T')[0],
        order.status,
      ];

      final sheetsApi = sheets.SheetsApi(_client!);
      final valueRange = sheets.ValueRange(values: [row]);
      await sheetsApi.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        '$sheetName!A2',
        valueInputOption: 'USER_ENTERED',
      );
      print('Pedido ${order.id} sincronizado exitosamente');
    } catch (e) {
      print('Error sincronizando pedido individual: $e');
    }
  }

  Future<void> appendExpenseToSheet(String spreadsheetId, ExpenseModel expense) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    try {
      final sheetName = 'Gastos';
      final headers = ['ID', 'Fecha', 'Descripción', 'Monto', 'Categoría'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);

      final row = [
        expense.id,
        expense.date.toIso8601String().split('T')[0],
        expense.description,
        expense.amount.toStringAsFixed(2),
        expense.category,
      ];

      final sheetsApi = sheets.SheetsApi(_client!);
      await sheetsApi.spreadsheets.values.append(sheets.ValueRange(values: [row]), spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      print('Error sincronizando gasto individual: $e');
    }
  }

  Future<void> appendIncomeToSheet(String spreadsheetId, IncomeModel income) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    try {
      final sheetName = 'Ingresos';
      final headers = ['ID', 'Fecha', 'Descripción', 'Monto', 'Categoría'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);

      final row = [
        income.id,
        income.date.toIso8601String().split('T')[0],
        income.description,
        income.amount.toStringAsFixed(2),
        income.category,
      ];

      final sheetsApi = sheets.SheetsApi(_client!);
      await sheetsApi.spreadsheets.values.append(sheets.ValueRange(values: [row]), spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      print('Error sincronizando ingreso individual: $e');
    }
  }

  Future<void> appendProductToSheet(String spreadsheetId, ProductEntity product) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    try {
      final sheetName = 'Productos';
      final headers = ['ID', 'Nombre', 'Precio Base', 'Costo Extra', 'Categoría', 'Notas'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);

      final row = [
        product.id,
        product.name,
        product.basePrice,
        product.extraCost,
        product.category,
        product.notes ?? '',
      ];

      final sheetsApi = sheets.SheetsApi(_client!);
      await sheetsApi.spreadsheets.values.append(sheets.ValueRange(values: [row]), spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      print('Error sincronizando producto individual: $e');
    }
  }

  Future<void> appendCustomerToSheet(String spreadsheetId, CustomerEntity customer) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    try {
      final sheetName = 'Clientes';
      final headers = ['ID', 'Nombre', 'Teléfono'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);

      final row = [customer.id, customer.name, customer.phone];

      final sheetsApi = sheets.SheetsApi(_client!);
      await sheetsApi.spreadsheets.values.append(sheets.ValueRange(values: [row]), spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      print('Error sincronizando cliente individual: $e');
    }
  }

  // --- Sheets Export Methods ---

  Future<void> bulkExportOrders(String spreadsheetId, List<OrderEntity> orders, {bool overwrite = false}) async {
    if (_client == null || spreadsheetId.isEmpty || orders.isEmpty) return;
    try {
      final sheetName = 'Pedidos';
      final headers = ['ID', 'Fecha', 'Cliente', 'Productos', 'Total', 'Anticipo', 'Saldo', 'Fecha Entrega', 'Estado'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);
      
      if (overwrite) await clearSheet(spreadsheetId, sheetName);

      final existingIds = overwrite ? <String>{} : await _getExistingIds(spreadsheetId, sheetName);
      final newOrders = orders.where((o) => !existingIds.contains(o.id)).toList();

      if (newOrders.isEmpty) return;

      final sheetsApi = sheets.SheetsApi(_client!);
      final rows = newOrders.map((o) => [
        o.id,
        (o.saleDate ?? DateTime.now()).toIso8601String().split('T')[0],
        o.customerName,
        o.items.map((i) => '${i.quantity}x ${i.productName}').join(', '),
        o.totalPrice.toStringAsFixed(2),
        (o.totalPrice - o.pendingBalance).toStringAsFixed(2),
        o.pendingBalance.toStringAsFixed(2),
        o.deliveryDate.toIso8601String().split('T')[0],
        o.status,
      ]).toList();

      final valueRange = sheets.ValueRange(values: rows);
      await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in bulkExportOrders: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error exportación masiva pedidos: $e');
      rethrow;
    }
  }

  Future<void> bulkExportExpenses(String spreadsheetId, List<ExpenseModel> expenses, {bool overwrite = false}) async {
    if (_client == null || spreadsheetId.isEmpty || expenses.isEmpty) return;
    try {
      final sheetName = 'Gastos';
      final headers = ['ID', 'Fecha', 'Descripción', 'Monto', 'Categoría'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);
      
      if (overwrite) await clearSheet(spreadsheetId, sheetName);

      final existingIds = overwrite ? <String>{} : await _getExistingIds(spreadsheetId, sheetName);
      final newExpenses = expenses.where((e) => !existingIds.contains(e.id)).toList();

      if (newExpenses.isEmpty) return;

      final sheetsApi = sheets.SheetsApi(_client!);
      final rows = newExpenses.map((e) => [
        e.id,
        e.date.toIso8601String().split('T')[0],
        e.description,
        e.amount.toStringAsFixed(2),
        e.category,
      ]).toList();
      final valueRange = sheets.ValueRange(values: rows);
      await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in bulkExportExpenses: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error exportación masiva gastos: $e');
      rethrow;
    }
  }

  Future<void> bulkExportIncomes(String spreadsheetId, List<IncomeModel> incomes, {bool overwrite = false}) async {
    if (_client == null || spreadsheetId.isEmpty || incomes.isEmpty) return;
    try {
      final sheetName = 'Ingresos';
      final headers = ['ID', 'Fecha', 'Descripción', 'Monto', 'Categoría'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);
      
      if (overwrite) await clearSheet(spreadsheetId, sheetName);

      final existingIds = overwrite ? <String>{} : await _getExistingIds(spreadsheetId, sheetName);
      final newIncomes = incomes.where((i) => !existingIds.contains(i.id)).toList();

      if (newIncomes.isEmpty) return;

      final sheetsApi = sheets.SheetsApi(_client!);
      final rows = newIncomes.map((i) => [
        i.id,
        i.date.toIso8601String().split('T')[0],
        i.description,
        i.amount.toStringAsFixed(2),
        i.category,
      ]).toList();
      final valueRange = sheets.ValueRange(values: rows);
      await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in bulkExportIncomes: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error exportación masiva ingresos: $e');
      rethrow;
    }
  }

  Future<void> bulkExportCustomers(String spreadsheetId, List<CustomerEntity> customers, {bool overwrite = false}) async {
    if (_client == null || spreadsheetId.isEmpty || customers.isEmpty) return;
    try {
      final sheetName = 'Clientes';
      final headers = ['ID', 'Nombre', 'Teléfono'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);
      
      if (overwrite) await clearSheet(spreadsheetId, sheetName);

      final existingIds = overwrite ? <String>{} : await _getExistingIds(spreadsheetId, sheetName);
      final newCustomers = customers.where((c) => !existingIds.contains(c.id)).toList();

      if (newCustomers.isEmpty) return;

      final sheetsApi = sheets.SheetsApi(_client!);
      final rows = newCustomers.map((c) => [c.id, c.name, c.phone]).toList();
      final valueRange = sheets.ValueRange(values: rows);
      await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in bulkExportCustomers: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error exportación masiva clientes: $e');
      rethrow;
    }
  }

  Future<void> bulkExportProducts(String spreadsheetId, List<ProductEntity> products, {bool overwrite = false}) async {
    if (_client == null || spreadsheetId.isEmpty || products.isEmpty) return;
    try {
      final sheetName = 'Productos';
      final headers = ['ID', 'Nombre', 'Precio Base', 'Costo Extra', 'Categoría', 'Notas'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);
      
      if (overwrite) await clearSheet(spreadsheetId, sheetName);

      final existingIds = overwrite ? <String>{} : await _getExistingIds(spreadsheetId, sheetName);
      final newProducts = products.where((p) => !existingIds.contains(p.id)).toList();

      if (newProducts.isEmpty) return;

      final sheetsApi = sheets.SheetsApi(_client!);
      final rows = newProducts.map((p) => [p.id, p.name, p.basePrice, p.extraCost, p.category, p.notes ?? '']).toList();
      final valueRange = sheets.ValueRange(values: rows);
      await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in bulkExportProducts: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error exportación masiva productos: $e');
      rethrow;
    }
  }

  Future<void> bulkExportCategories(String spreadsheetId, List<String> categories, {bool overwrite = false}) async {
    if (_client == null || spreadsheetId.isEmpty || categories.isEmpty) return;
    try {
      final sheetName = 'Categorías';
      final headers = ['ID', 'Nombre'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);
      
      if (overwrite) await clearSheet(spreadsheetId, sheetName);

      final existingIds = overwrite ? <String>{} : await _getExistingIds(spreadsheetId, sheetName);
      // For categories, we treat the name as ID for simplicity or generate a simple mapping
      final newCategories = categories.where((cat) => !existingIds.contains(cat)).toList();

      if (newCategories.isEmpty) return;

      final sheetsApi = sheets.SheetsApi(_client!);
      final rows = newCategories.map((cat) => [cat, cat]).toList();
      final valueRange = sheets.ValueRange(values: rows);
      await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in bulkExportCategories: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error exportación masiva categorías: $e');
      rethrow;
    }
  }

  // --- Sheets Import Method ---

  Future<void> importFromSheets(String spreadsheetId, {bool replaceLocal = false}) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    final sheetsApi = sheets.SheetsApi(_client!);
    try {
      // 1. Clientes
      try {
        final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Clientes!A2:C');
        if (res.values != null) {
          final box = Hive.box<CustomerModel>('customers');
          if (replaceLocal) await box.clear();
          for (var row in res.values!) {
            if (row.length >= 2 && row[1].toString().trim().isNotEmpty) {
              final id = row[0].toString();
              // UPSERT
              final c = CustomerModel(
                id: id.isNotEmpty ? id : const Uuid().v4(),
                name: row[1].toString(),
                phone: row.length > 2 ? row[2].toString() : '',
              );
              await box.put(c.id, c);
            }
          }
        }
      } catch (e) {
        if (_isAuthError(e)) rethrow;
        if (_isMissingSheetError(e)) {
          print('Hoja Clientes no encontrada, omitiendo importación');
        } else {
          print('Error importando clientes: $e');
        }
      }

      // 2. Productos
      try {
        final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Productos!A2:F');
        if (res.values != null) {
          final box = Hive.box<ProductModel>('products');
          if (replaceLocal) await box.clear();
          for (var row in res.values!) {
            if (row.length >= 2 && row[1].toString().trim().isNotEmpty) {
              final id = row[0].toString();
              // UPSERT
              final p = ProductModel(
                id: id.isNotEmpty ? id : const Uuid().v4(),
                name: row[1].toString(),
                basePrice: double.tryParse(row[2].toString()) ?? 0.0,
                extraCost: double.tryParse(row[3].toString()) ?? 0.0,
                category: row.length > 4 ? row[4].toString() : 'Otros',
                notes: row.length > 5 ? row[5].toString() : null,
              );
              await box.put(p.id, p);
            }
          }
        }
      } catch (e) {
        if (_isAuthError(e)) rethrow;
        if (_isMissingSheetError(e)) {
          print('Hoja Productos no encontrada, omitiendo importación');
        } else {
          print('Error importando productos: $e');
        }
      }

      // 3. Gastos
      try {
        final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Gastos!A2:E');
        if (res.values != null) {
          final box = Hive.box<ExpenseModel>('expenses');
          if (replaceLocal) await box.clear();
          for (var row in res.values!) {
            if (row.length >= 4 && row[2].toString().trim().isNotEmpty) {
              final id = row[0].toString();
              // UPSERT
              final e = ExpenseModel(
                id: id.isNotEmpty ? id : const Uuid().v4(),
                date: DateTime.tryParse(row[1].toString()) ?? DateTime.now(),
                description: row[2].toString(),
                amount: double.tryParse(row[3].toString()) ?? 0.0,
                category: row.length > 4 ? row[4].toString() : 'Otros',
              );
              await box.put(e.id, e);
            }
          }
        }
      } catch (e) {
        if (_isAuthError(e)) rethrow;
        if (_isMissingSheetError(e)) {
          print('Hoja Gastos no encontrada, omitiendo importación');
        } else {
          print('Error importando gastos: $e');
        }
      }

      // 4. Ingresos
      try {
        final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Ingresos!A2:E');
        if (res.values != null) {
          final box = Hive.box<IncomeModel>('incomes');
          if (replaceLocal) await box.clear();
          for (var row in res.values!) {
            if (row.length >= 4 && row[2].toString().trim().isNotEmpty) {
              final id = row[0].toString();
              // UPSERT
              final i = IncomeModel(
                id: id.isNotEmpty ? id : const Uuid().v4(),
                date: DateTime.tryParse(row[1].toString()) ?? DateTime.now(),
                description: row[2].toString(),
                amount: double.tryParse(row[3].toString()) ?? 0.0,
                category: row.length > 4 ? row[4].toString() : 'Otros',
              );
              await box.put(i.id, i);
            }
          }
        }
      } catch (e) {
        if (_isAuthError(e)) rethrow;
        if (_isMissingSheetError(e)) {
          print('Hoja Ingresos no encontrada, omitiendo importación');
        } else {
          print('Error importando ingresos: $e');
        }
      }

      // 5. Categorías
      try {
        final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Categorías!A2:B');
        if (res.values != null) {
          final settingsBox = Hive.box('settings');
          final settingsMap = Map<String, dynamic>.from(settingsBox.get('appSettings') ?? {});
          
          final List<String> categories = List<String>.from(settingsMap['productCategories'] ?? []);
          if (replaceLocal) categories.clear();

          for (var row in res.values!) {
            if (row.length >= 2 && row[1].toString().trim().isNotEmpty) {
              final catName = row[1].toString();
              if (!categories.contains(catName)) {
                categories.add(catName);
              }
            }
          }
          
          if (categories.isNotEmpty) {
            settingsMap['productCategories'] = categories;
            await settingsBox.put('appSettings', settingsMap);
          }
        }
      } catch (e) {
        if (_isAuthError(e)) rethrow;
        if (_isMissingSheetError(e)) {
          print('Hoja Categorías no encontrada, omitiendo importación');
        } else {
          print('Error importando categorías: $e');
        }
      }

      // 6. Pedidos
      try {
        final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Pedidos!A2:I');
        if (res.values != null) {
          final box = Hive.box<OrderModel>('orders');
          if (replaceLocal) await box.clear();
          for (var row in res.values!) {
            if (row.length >= 3 && row[2].toString().trim().isNotEmpty) {
              final id = row[0].toString();
              
              OrderModel orderToSave;
              if (box.containsKey(id)) {
                 // UPSERT: Update existing
                 final existing = box.get(id)!;
                 final updatedEntity = existing.copyWith(
                   customerName: row[2].toString(),
                   totalPrice: double.tryParse(row[4].toString()) ?? existing.totalPrice,
                   pendingBalance: double.tryParse(row[6].toString()) ?? existing.pendingBalance,
                   deliveryDate: DateTime.tryParse(row[7].toString()) ?? existing.deliveryDate,
                   status: row.length > 8 ? row[8].toString() : existing.status,
                   saleDate: DateTime.tryParse(row[1].toString()) ?? existing.saleDate,
                   isSynced: true,
                 );
                 orderToSave = OrderModel.fromEntity(updatedEntity);
              } else {
                 // Insert New
                 orderToSave = OrderModel(
                  id: id.isNotEmpty ? id : const Uuid().v4(),
                  customerName: row[2].toString(),
                  items: [],
                  totalPrice: double.tryParse(row[4].toString()) ?? 0.0,
                  pendingBalance: double.tryParse(row[6].toString()) ?? 0.0,
                  deliveryDate: DateTime.tryParse(row[7].toString()) ?? DateTime.now(),
                  isSynced: true,
                  saleDate: DateTime.tryParse(row[1].toString()) ?? DateTime.now(),
                  status: row.length > 8 ? row[8].toString() : 'Entregado',
                );
              }
              await box.put(orderToSave.id, orderToSave);
            }
          }
        }
      } catch (e) {
        if (_isAuthError(e)) rethrow;
        if (_isMissingSheetError(e)) {
          print('Hoja Pedidos no encontrada, omitiendo importación');
        } else {
          print('Error importando pedidos: $e');
        }
      }
      
      print('Importación desde Sheets completada');
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in importFromSheets: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error en importación general: $e');
      rethrow;
    }
  }

  // --- Calendar Methods ---

  Future<String?> createCalendarEvent(OrderEntity order) async {
    if (_client == null) return null;
    final calendarApi = calendar.CalendarApi(_client!);
    final event = calendar.Event(
      summary: 'Entrega: ${order.customerName}',
      description: 'Saldo: \$${order.pendingBalance}',
      start: calendar.EventDateTime(dateTime: order.deliveryDate, timeZone: 'America/Mexico_City'),
      end: calendar.EventDateTime(dateTime: order.deliveryDate.add(const Duration(minutes: 30)), timeZone: 'America/Mexico_City'),
    );
    try {
      final res = await calendarApi.events.insert(event, 'primary');
      return res.id;
    } catch (e) { print('Error creando evento: $e'); return null; }
  }

  Future<bool> updateCalendarEvent(String eventId, OrderEntity order) async {
    if (_client == null || eventId.isEmpty) return false;
    final calendarApi = calendar.CalendarApi(_client!);
    final event = calendar.Event(
      summary: 'Entrega: ${order.customerName}',
      description: 'Saldo: \$${order.pendingBalance}',
      start: calendar.EventDateTime(dateTime: order.deliveryDate, timeZone: 'America/Mexico_City'),
      end: calendar.EventDateTime(dateTime: order.deliveryDate.add(const Duration(minutes: 30)), timeZone: 'America/Mexico_City'),
    );
    try {
      await calendarApi.events.update(event, 'primary', eventId);
      return true;
    } catch (e) { 
      final errorStr = e.toString();
      if (errorStr.contains('404') || errorStr.contains('notFound')) {
        print('LOG: Evento no encontrado en Google Calendar (404). Marcando para re-creación.');
        return false;
      }
      print('Error editando evento: $e');
      return false; // For other errors, we also return false but log them
    }
  }

  Future<void> deleteCalendarEvent(String eventId) async {
    if (_client == null) return;
    final calendarApi = calendar.CalendarApi(_client!);
    try {
      await calendarApi.events.delete('primary', eventId);
    } catch (e) { print('Error borrando evento: $e'); }
  }

  Future<Map<String, int>> syncAllCalendarEvents(List<OrderEntity> orders) async {
    int created = 0, updated = 0, errors = 0;
    for (var o in orders) {
      if (o.googleEventId == null) {
        final id = await createCalendarEvent(o);
        if (id != null) created++; else errors++;
      } else {
        final ok = await updateCalendarEvent(o.googleEventId!, o);
        if (ok) updated++; else {
          final id = await createCalendarEvent(o);
          if (id != null) created++; else errors++;
        }
      }
    }
    return {'created': created, 'updated': updated, 'errors': errors};
  }

  // --- Helper Methods ---

  Future<void> _ensureSheetExists(String spreadsheetId, String sheetName, List<String> headers) async {
    if (_client == null) return;
    final sheetsApi = sheets.SheetsApi(_client!);
    try {
      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      final exists = (spreadsheet.sheets ?? []).any((s) => s.properties?.title == sheetName);

      if (!exists) {
        final addSheetRequest = sheets.BatchUpdateSpreadsheetRequest(
          requests: [sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: sheetName)))],
        );
        await sheetsApi.spreadsheets.batchUpdate(addSheetRequest, spreadsheetId);
        
        final headerRow = sheets.ValueRange(values: [headers]);
        await sheetsApi.spreadsheets.values.update(headerRow, spreadsheetId, '$sheetName!A1', valueInputOption: 'USER_ENTERED');
      }
    } catch (e) { print('Error asegurando hoja $sheetName: $e'); }
  }

  /// Helper method to detect authentication errors
  bool _isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('401') || 
           errorStr.contains('invalid_token') || 
           errorStr.contains('access was denied') ||
           errorStr.contains('unauthorized');
  }

  /// Helper method to detect missing sheet errors (400 - Unable to parse range)
  bool _isMissingSheetError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('400') && 
           (errorStr.contains('unable to parse range') || 
            errorStr.contains('unable to parse'));
  }
}
