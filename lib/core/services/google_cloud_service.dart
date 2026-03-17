import 'dart:convert';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../exceptions/auth_exception.dart';

// Feature imports with correct paths
import '../../features/sales/domain/entities/order.dart';
import '../../features/sales/data/models/order_model.dart';
import '../../features/sales/data/models/order_item_model.dart';
import '../../features/sales/data/models/customer_model.dart';
import '../../features/finance/data/models/expense_model.dart';
import '../../features/inventory/data/models/product_model.dart';
import '../../features/inventory/domain/entities/product.dart';
import '../../features/inventory/data/models/inventory_item_model.dart';
import '../../features/inventory/data/models/stock_movement_model.dart';
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
  final _storage = const FlutterSecureStorage();

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
      
      String? credentialsJson = await _storage.read(key: _credentialsKey);
      
      // Fallback to Hive for migration if secure storage is empty
      if (credentialsJson == null) {
         final oldCredentials = settingsBox.get(_credentialsKey);
         if (oldCredentials != null) {
             print('Migrando credenciales de Hive a SecureStorage');
             credentialsJson = oldCredentials as String;
             await _storage.write(key: _credentialsKey, value: credentialsJson);
             await settingsBox.delete(_credentialsKey); // Clean old
         } else {
             return false;
         }
      }

      final settingsMap = settingsBox.get('appSettings');
      if (settingsMap == null) return false;
      
      final settings = Map<String, dynamic>.from(settingsMap);
      final clientId = settings['googleClientId'];
      final clientSecret = settings['googleClientSecret'];

      if (clientId == null || clientSecret == null) return false;

      final credentialsMap = json.decode(credentialsJson);
      final credentials = AccessCredentials(
        AccessToken(
          credentialsMap['accessToken']['type'],
          credentialsMap['accessToken']['data'],
          DateTime.parse(credentialsMap['accessToken']['expiry']).toUtc(),
        ),
        credentialsMap['refreshToken'],
        _scopes,
      );

      final identifier = ClientId(clientId, clientSecret);
      _client = autoRefreshingClient(identifier, credentials, http.Client());
      print('Sesión restaurada exitosamente (con Auto-Refresh)');
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

    await _storage.write(key: _credentialsKey, value: json.encode(credentialsMap));
  }

  /// Logout and clear credentials
  Future<void> logout() async {
    try {
      _client?.close();
      _client = null;
      await _storage.delete(key: _credentialsKey);
      
      // Also clean old Hive credentials just in case
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
      return res.values!.map((row) => row.isNotEmpty ? row[0].toString() : '').where((e) => e.isNotEmpty).toSet();
    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      if (_isMissingSheetError(e)) return {};
      print('Error obteniendo IDs de $sheetName: $e');
      return {};
    }
  }

  Future<Map<String, int>> _getExistingIdsWithIndex(String spreadsheetId, String sheetName) async {
    if (_client == null || spreadsheetId.isEmpty) return {};
    final sheetsApi = sheets.SheetsApi(_client!);
    try {
      final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, '$sheetName!A2:A');
      if (res.values == null) return {};
      final map = <String, int>{};
      for (int i = 0; i < res.values!.length; i++) {
        final row = res.values![i];
        if (row.isNotEmpty) {
          map[row[0].toString()] = i + 2; // +2 since A2 is index 0
        }
      }
      return map;
    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      if (_isMissingSheetError(e)) return {};
      print('Error obteniendo IDs con índice de $sheetName: $e');
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
      throw Exception('Fallo de Red: No se pudo eliminar la fila en Google Sheets. ($e)');
    }
  }

  // --- Legacy Single-Item Methods (for real-time sync) ---

  Future<void> upsertOrderInSheet(String spreadsheetId, OrderEntity order) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    try {
      final sheetName = 'Pedidos';
      final headers = ['ID', 'Fecha', 'Cliente', 'Productos', 'Total', 'Anticipo', 'Saldo', 'Fecha Entrega', 'Estado', 'Event ID'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);

      final row = [
        order.id,
        (order.saleDate ?? DateTime.now()).toIso8601String(),
        order.customerName,
        order.items.map((i) => '${i.quantity}x ${i.productName}').join(', '),
        order.totalPrice.toStringAsFixed(2),
        (order.totalPrice - order.pendingBalance).toStringAsFixed(2),
        order.pendingBalance.toStringAsFixed(2),
        order.deliveryDate.toIso8601String(),
        order.status,
        order.googleEventId ?? '',
      ];

      final sheetsApi = sheets.SheetsApi(_client!);
      
      // Find row index (fetch Column A)
      final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, '$sheetName!A:A');
      final values = res.values;
      int rowIndex = -1;
      
      if (values != null) {
        for (int i = 0; i < values.length; i++) {
          if (values[i].isNotEmpty && values[i][0].toString() == order.id) {
            rowIndex = i + 1; // 1-based index for A1 notation
            break;
          }
        }
      }

      final valueRange = sheets.ValueRange(values: [row]);
      
      if (rowIndex != -1) {
         // Update existing row
         await sheetsApi.spreadsheets.values.update(
            valueRange,
            spreadsheetId,
            '$sheetName!A$rowIndex',
            valueInputOption: 'USER_ENTERED',
         );
      } else {
         // Append new row
         await sheetsApi.spreadsheets.values.append(
            valueRange,
            spreadsheetId,
            '$sheetName!A2',
            valueInputOption: 'USER_ENTERED',
         );
      }
      print('Pedido ${order.id} sincronizado exitosamente en Sheets (Upsert)');
    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      print('Error sincronizando pedido individual en Sheets: $e');
      throw Exception('Fallo de Red: No se pudo subir el pedido a Google Sheets. ($e)');
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
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      print('Error sincronizando gasto individual: $e');
      throw Exception('Fallo de Red: No se pudo subir el gasto a Google Sheets. ($e)');
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
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      print('Error sincronizando ingreso individual: $e');
      throw Exception('Fallo de Red: No se pudo subir el ingreso a Google Sheets. ($e)');
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
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      print('Error sincronizando producto individual: $e');
      throw Exception('Fallo de Red: No se pudo subir el producto a Google Sheets. ($e)');
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
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      print('Error sincronizando cliente individual: $e');
      throw Exception('Fallo de Red: No se pudo subir el cliente a Google Sheets. ($e)');
    }
  }

  Future<void> upsertInventoryItemInSheet(String spreadsheetId, InventoryItemModel item) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    try {
      final sheetName = 'Inventario';
      final headers = ['ID', 'Nombre', 'SKU', 'Tipo', 'Unidad Medida', 'Stock Actual', 'Stock Mínimo', 'Costo Unitario', 'Estado'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);

      final row = [
        item.id,
        item.name,
        item.sku ?? '',
        item.itemType,
        item.unitOfMeasure,
        item.currentStock.toStringAsFixed(2),
        item.minimumStock.toStringAsFixed(2),
        item.unitCost.toStringAsFixed(2),
        item.isDeleted ? 'Eliminado' : 'Activo',
      ];

      final sheetsApi = sheets.SheetsApi(_client!);
      
      final res = await sheetsApi.spreadsheets.values.get(spreadsheetId, '$sheetName!A:A');
      final values = res.values;
      int rowIndex = -1;
      
      if (values != null) {
        for (int i = 0; i < values.length; i++) {
          if (values[i].isNotEmpty && values[i][0].toString() == item.id) {
            rowIndex = i + 1;
            break;
          }
        }
      }

      final valueRange = sheets.ValueRange(values: [row]);
      
      if (rowIndex != -1) {
         await sheetsApi.spreadsheets.values.update(
            valueRange, spreadsheetId, '$sheetName!A$rowIndex',
            valueInputOption: 'USER_ENTERED',
         );
      } else {
         await sheetsApi.spreadsheets.values.append(
            valueRange, spreadsheetId, '$sheetName!A2',
            valueInputOption: 'USER_ENTERED',
         );
      }
    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      print('Error sincronizando ítem de inventario: $e');
      throw Exception('Fallo de Red: No se pudo subir el inventario a Google Sheets. ($e)');
    }
  }

  Future<void> appendStockMovementToSheet(String spreadsheetId, StockMovementModel movement) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    try {
      final sheetName = 'Historial_Stock';
      final headers = ['ID', 'Item ID', 'Tipo Movimiento', 'Cantidad', 'Fecha', 'Razón'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);

      final row = [
        movement.id,
        movement.itemId,
        movement.movementType,
        movement.quantity.toStringAsFixed(2),
        movement.date.toIso8601String(),
        movement.reason,
      ];

      final sheetsApi = sheets.SheetsApi(_client!);
      await sheetsApi.spreadsheets.values.append(sheets.ValueRange(values: [row]), spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      print('Error sincronizando movimiento de stock: $e');
      throw Exception('Fallo de Red: No se pudo subir el movimiento de stock a Google Sheets. ($e)');
    }
  }

  // --- Sheets Export Methods ---

  Future<void> bulkExportOrders(String spreadsheetId, List<OrderEntity> orders, {bool overwrite = false}) async {
    if (_client == null || spreadsheetId.isEmpty || orders.isEmpty) return;
    try {
      final sheetName = 'Pedidos';
      final headers = ['ID', 'Fecha', 'Cliente', 'Productos', 'Total', 'Anticipo', 'Saldo', 'Fecha Entrega', 'Estado', 'Event ID'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);
      
      if (overwrite) await clearSheet(spreadsheetId, sheetName);

      final existingMap = overwrite ? <String, int>{} : await _getExistingIdsWithIndex(spreadsheetId, sheetName);
      
      final toUpdate = <sheets.ValueRange>[];
      final toInsertList = <List<Object>>[];
      
      for (var o in orders) {
        final rowData = [
          o.id,
          (o.saleDate ?? DateTime.now()).toIso8601String(),
          o.customerName,
          o.items.map((i) => '${i.quantity}x ${i.productName}').join(', '),
          o.totalPrice.toStringAsFixed(2),
          (o.totalPrice - o.pendingBalance).toStringAsFixed(2),
          o.pendingBalance.toStringAsFixed(2),
          o.deliveryDate.toIso8601String(),
          o.status,
          o.googleEventId ?? '',
        ];

        if (existingMap.containsKey(o.id)) {
          final rowIdx = existingMap[o.id]!;
          toUpdate.add(sheets.ValueRange(
            range: '$sheetName!A$rowIdx',
            values: [rowData],
          ));
        } else {
          toInsertList.add(rowData);
        }
      }

      final sheetsApi = sheets.SheetsApi(_client!);

      if (toUpdate.isNotEmpty) {
        final batchUpdateRequest = sheets.BatchUpdateValuesRequest(
          data: toUpdate,
          valueInputOption: 'USER_ENTERED',
        );
        await sheetsApi.spreadsheets.values.batchUpdate(batchUpdateRequest, spreadsheetId);
      }

      if (toInsertList.isNotEmpty) {
        final valueRange = sheets.ValueRange(values: toInsertList);
        await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
      }
      
    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
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

      final existingMap = overwrite ? <String, int>{} : await _getExistingIdsWithIndex(spreadsheetId, sheetName);
      
      final toUpdate = <sheets.ValueRange>[];
      final toInsertList = <List<Object>>[];
      
      for (var e in expenses) {
        final rowData = [
          e.id,
          e.date.toIso8601String(),
          e.description,
          e.amount.toStringAsFixed(2),
          e.category,
        ];

        if (existingMap.containsKey(e.id)) {
          final rowIdx = existingMap[e.id]!;
          toUpdate.add(sheets.ValueRange(
            range: '$sheetName!A$rowIdx',
            values: [rowData],
          ));
        } else {
          toInsertList.add(rowData);
        }
      }

      final sheetsApi = sheets.SheetsApi(_client!);

      if (toUpdate.isNotEmpty) {
        final batchUpdateRequest = sheets.BatchUpdateValuesRequest(
          data: toUpdate,
          valueInputOption: 'USER_ENTERED',
        );
        await sheetsApi.spreadsheets.values.batchUpdate(batchUpdateRequest, spreadsheetId);
      }

      if (toInsertList.isNotEmpty) {
        final valueRange = sheets.ValueRange(values: toInsertList);
        await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
      }
      
    } catch (e) {
      if (_isAuthError(e)) {
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

      final existingMap = overwrite ? <String, int>{} : await _getExistingIdsWithIndex(spreadsheetId, sheetName);
      
      final toUpdate = <sheets.ValueRange>[];
      final toInsertList = <List<Object>>[];
      
      for (var i in incomes) {
        final rowData = [
          i.id,
          i.date.toIso8601String(),
          i.description,
          i.amount.toStringAsFixed(2),
          i.category,
        ];

        if (existingMap.containsKey(i.id)) {
          final rowIdx = existingMap[i.id]!;
          toUpdate.add(sheets.ValueRange(
            range: '$sheetName!A$rowIdx',
            values: [rowData],
          ));
        } else {
          toInsertList.add(rowData);
        }
      }

      final sheetsApi = sheets.SheetsApi(_client!);

      if (toUpdate.isNotEmpty) {
        final batchUpdateRequest = sheets.BatchUpdateValuesRequest(
          data: toUpdate,
          valueInputOption: 'USER_ENTERED',
        );
        await sheetsApi.spreadsheets.values.batchUpdate(batchUpdateRequest, spreadsheetId);
      }

      if (toInsertList.isNotEmpty) {
        final valueRange = sheets.ValueRange(values: toInsertList);
        await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
      }
      
    } catch (e) {
      if (_isAuthError(e)) {
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

      final existingMap = overwrite ? <String, int>{} : await _getExistingIdsWithIndex(spreadsheetId, sheetName);
      
      final toUpdate = <sheets.ValueRange>[];
      final toInsertList = <List<Object>>[];

      for (var c in customers) {
        final rowData = [
          c.id, c.name, c.phone
        ];

        if (existingMap.containsKey(c.id)) {
          final rowIdx = existingMap[c.id]!;
          toUpdate.add(sheets.ValueRange(
            range: '$sheetName!A$rowIdx',
            values: [rowData],
          ));
        } else {
          toInsertList.add(rowData);
        }
      }

      final sheetsApi = sheets.SheetsApi(_client!);

      if (toUpdate.isNotEmpty) {
        final batchUpdateRequest = sheets.BatchUpdateValuesRequest(
          data: toUpdate,
          valueInputOption: 'USER_ENTERED',
        );
        await sheetsApi.spreadsheets.values.batchUpdate(batchUpdateRequest, spreadsheetId);
      }

      if (toInsertList.isNotEmpty) {
        final valueRange = sheets.ValueRange(values: toInsertList);
        await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
      }

    } catch (e) {
      if (_isAuthError(e)) {
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

      final existingMap = overwrite ? <String, int>{} : await _getExistingIdsWithIndex(spreadsheetId, sheetName);
      
      final toUpdate = <sheets.ValueRange>[];
      final toInsertList = <List<Object>>[];

      for (var p in products) {
        final rowData = [
          p.id, p.name, p.basePrice, p.extraCost, p.category, p.notes ?? ''
        ];

        if (existingMap.containsKey(p.id)) {
          final rowIdx = existingMap[p.id]!;
          toUpdate.add(sheets.ValueRange(
            range: '$sheetName!A$rowIdx',
            values: [rowData],
          ));
        } else {
          toInsertList.add(rowData);
        }
      }

      final sheetsApi = sheets.SheetsApi(_client!);

      if (toUpdate.isNotEmpty) {
        final batchUpdateRequest = sheets.BatchUpdateValuesRequest(
          data: toUpdate,
          valueInputOption: 'USER_ENTERED',
        );
        await sheetsApi.spreadsheets.values.batchUpdate(batchUpdateRequest, spreadsheetId);
      }

      if (toInsertList.isNotEmpty) {
        final valueRange = sheets.ValueRange(values: toInsertList);
        await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
      }

    } catch (e) {
      if (_isAuthError(e)) {
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

      final existingMap = overwrite ? <String, int>{} : await _getExistingIdsWithIndex(spreadsheetId, sheetName);
      
      final toUpdate = <sheets.ValueRange>[];
      final toInsertList = <List<Object>>[];

      for (var cat in categories) {
        final rowData = [
          cat, cat // Category name is used as ID
        ];

        if (existingMap.containsKey(cat)) {
          final rowIdx = existingMap[cat]!;
          toUpdate.add(sheets.ValueRange(
            range: '$sheetName!A$rowIdx',
            values: [rowData],
          ));
        } else {
          toInsertList.add(rowData);
        }
      }

      final sheetsApi = sheets.SheetsApi(_client!);

      if (toUpdate.isNotEmpty) {
        final batchUpdateRequest = sheets.BatchUpdateValuesRequest(
          data: toUpdate,
          valueInputOption: 'USER_ENTERED',
        );
        await sheetsApi.spreadsheets.values.batchUpdate(batchUpdateRequest, spreadsheetId);
      }

      if (toInsertList.isNotEmpty) {
        final valueRange = sheets.ValueRange(values: toInsertList);
        await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
      }

    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error exportación masiva categorías: $e');
      rethrow;
    }
  }

  Future<void> bulkExportInventory(String spreadsheetId, List<InventoryItemModel> items, {bool overwrite = false}) async {
    if (_client == null || spreadsheetId.isEmpty || items.isEmpty) return;
    try {
      final sheetName = 'Inventario';
      final headers = ['ID', 'Nombre', 'SKU', 'Tipo', 'Unidad Medida', 'Stock Actual', 'Stock Mínimo', 'Costo Unitario', 'Estado'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);
      
      if (overwrite) await clearSheet(spreadsheetId, sheetName);

      final existingMap = overwrite ? <String, int>{} : await _getExistingIdsWithIndex(spreadsheetId, sheetName);
      
      final toUpdate = <sheets.ValueRange>[];
      final toInsertList = <List<Object>>[];

      for (var item in items) {
        final rowData = [
          item.id,
          item.name,
          item.sku ?? '',
          item.itemType,
          item.unitOfMeasure,
          item.currentStock.toStringAsFixed(2),
          item.minimumStock.toStringAsFixed(2),
          item.unitCost.toStringAsFixed(2),
          item.isDeleted ? 'Eliminado' : 'Activo',
        ];

        if (existingMap.containsKey(item.id)) {
          final rowIdx = existingMap[item.id]!;
          toUpdate.add(sheets.ValueRange(
            range: '$sheetName!A$rowIdx',
            values: [rowData],
          ));
        } else {
          toInsertList.add(rowData);
        }
      }

      final sheetsApi = sheets.SheetsApi(_client!);

      if (toUpdate.isNotEmpty) {
        final batchUpdateRequest = sheets.BatchUpdateValuesRequest(
          data: toUpdate,
          valueInputOption: 'USER_ENTERED',
        );
        await sheetsApi.spreadsheets.values.batchUpdate(batchUpdateRequest, spreadsheetId);
      }

      if (toInsertList.isNotEmpty) {
        final valueRange = sheets.ValueRange(values: toInsertList);
        await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
      }

    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      print('Error exportación masiva inventario: $e');
      rethrow;
    }
  }

  Future<void> bulkExportStockMovements(String spreadsheetId, List<StockMovementModel> movements, {bool overwrite = false}) async {
    if (_client == null || spreadsheetId.isEmpty || movements.isEmpty) return;
    try {
      final sheetName = 'Historial_Stock';
      final headers = ['ID', 'Item ID', 'Tipo Movimiento', 'Cantidad', 'Fecha', 'Razón'];
      await _ensureSheetExists(spreadsheetId, sheetName, headers);
      
      if (overwrite) await clearSheet(spreadsheetId, sheetName);

      final existingMap = overwrite ? <String, int>{} : await _getExistingIdsWithIndex(spreadsheetId, sheetName);
      
      final toUpdate = <sheets.ValueRange>[];
      final toInsertList = <List<Object>>[];

      for (var m in movements) {
        final rowData = [
          m.id,
          m.itemId,
          m.movementType,
          m.quantity.toStringAsFixed(2),
          m.date.toIso8601String(),
          m.reason,
        ];

        if (existingMap.containsKey(m.id)) {
          final rowIdx = existingMap[m.id]!;
          toUpdate.add(sheets.ValueRange(
            range: '$sheetName!A$rowIdx',
            values: [rowData],
          ));
        } else {
          toInsertList.add(rowData);
        }
      }

      final sheetsApi = sheets.SheetsApi(_client!);

      if (toUpdate.isNotEmpty) {
        final batchUpdateRequest = sheets.BatchUpdateValuesRequest(
          data: toUpdate,
          valueInputOption: 'USER_ENTERED',
        );
        await sheetsApi.spreadsheets.values.batchUpdate(batchUpdateRequest, spreadsheetId);
      }

      if (toInsertList.isNotEmpty) {
        final valueRange = sheets.ValueRange(values: toInsertList);
        await sheetsApi.spreadsheets.values.append(valueRange, spreadsheetId, '$sheetName!A2', valueInputOption: 'USER_ENTERED');
      }

    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado.');
      }
      print('Error exportación masiva historial stock: $e');
      rethrow;
    }
  }

  // --- Sheets Import Method ---

  Future<void> importFromSheets(String spreadsheetId, {bool replaceLocal = false}) async {
    if (_client == null || spreadsheetId.isEmpty) return;
    final sheetsApi = sheets.SheetsApi(_client!);

    // Phase 1: Descarga Atómica de Seguridad
    // Descargamos TODAS las hojas antes de tocar la base de datos local para evitar
    // dejar la app vacía si se corta el internet a la mitad.
    final Map<String, sheets.ValueRange?> allRes = {};
    try {
      final sheetsToGet = [
        'Clientes!A2:C', 
        'Productos!A2:F', 
        'Gastos!A2:E', 
        'Ingresos!A2:E', 
        'Categorías!A2:B', 
        'Pedidos!A2:J'
      ];
      for (var s in sheetsToGet) {
        final key = s.split('!')[0];
        try {
          allRes[key] = await sheetsApi.spreadsheets.values.get(spreadsheetId, s);
        } catch (e) {
          if (_isMissingSheetError(e)) {
            allRes[key] = null;
          } else {
            rethrow; // Corta la ejecución completa si hay un error real de red
          }
        }
      }
    } catch (e) {
      if (_isAuthError(e)) {
        print('Auth error detected in importFromSheets download phase: $e');
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, desconéctate y vuelve a conectar tu cuenta.');
      }
      print('Error de red durante la descarga de hojas. Abortando restauración para proteger datos locales: $e');
      rethrow;
    }

    // Phase 2: Borrado y Escritura (Solo se ejecuta si la descarga fue 100% exitosa)
    try {
      // 1. Clientes
      if (allRes['Clientes']?.values != null) {
        final box = Hive.box<CustomerModel>('customers');
        if (replaceLocal) await box.clear();
        for (var row in allRes['Clientes']!.values!) {
          if (row.length >= 2 && row[1].toString().trim().isNotEmpty) {
            final id = row[0].toString();
            final c = CustomerModel(
              id: id.isNotEmpty ? id : const Uuid().v4(),
              name: row[1].toString(),
              phone: row.length > 2 ? row[2].toString() : '',
            );
            await box.put(c.id, c);
          }
        }
      }

      // 2. Productos
      if (allRes['Productos']?.values != null) {
        final box = Hive.box<ProductModel>('products');
        if (replaceLocal) await box.clear();
        for (var row in allRes['Productos']!.values!) {
          if (row.length >= 2 && row[1].toString().trim().isNotEmpty) {
            final id = row[0].toString();
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

      // 3. Gastos
      if (allRes['Gastos']?.values != null) {
        final box = Hive.box<ExpenseModel>('expenses');
        if (replaceLocal) await box.clear();
        for (var row in allRes['Gastos']!.values!) {
          if (row.length >= 4 && row[2].toString().trim().isNotEmpty) {
            final id = row[0].toString();
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

      // 4. Ingresos
      if (allRes['Ingresos']?.values != null) {
        final box = Hive.box<IncomeModel>('incomes');
        if (replaceLocal) await box.clear();
        for (var row in allRes['Ingresos']!.values!) {
          if (row.length >= 4 && row[2].toString().trim().isNotEmpty) {
            final id = row[0].toString();
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

      // 5. Categorías
      if (allRes['Categorías']?.values != null) {
        final settingsBox = Hive.box('settings');
        final settingsMap = Map<String, dynamic>.from(settingsBox.get('appSettings') ?? {});
        
        final List<String> categories = List<String>.from(settingsMap['productCategories'] ?? []);
        if (replaceLocal) categories.clear();

        for (var row in allRes['Categorías']!.values!) {
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

      // 6. Pedidos
      if (allRes['Pedidos']?.values != null) {
        final box = Hive.box<OrderModel>('orders');
        if (replaceLocal) await box.clear();
        for (var row in allRes['Pedidos']!.values!) {
          if (row.length >= 3 && row[2].toString().trim().isNotEmpty) {
            final id = row[0].toString();
            final eventIdFromSheet = row.length >= 10 && row[9].toString().trim().isNotEmpty ? row[9].toString() : null;
            
            OrderModel orderToSave;
            if (box.containsKey(id)) {
                final existing = box.get(id)!;
                final updatedEntity = existing.copyWith(
                  customerName: row[2].toString(),
                  totalPrice: double.tryParse(row[4].toString()) ?? existing.totalPrice,
                  pendingBalance: double.tryParse(row[6].toString()) ?? existing.pendingBalance,
                  deliveryDate: DateTime.tryParse(row[7].toString()) ?? existing.deliveryDate,
                  status: row.length > 8 ? row[8].toString() : existing.status,
                  saleDate: DateTime.tryParse(row[1].toString()) ?? existing.saleDate,
                  isSynced: true,
                  googleEventId: eventIdFromSheet ?? existing.googleEventId,
                );
                orderToSave = OrderModel.fromEntity(updatedEntity);
            } else {
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
                googleEventId: eventIdFromSheet,
              );
            }
            await box.put(orderToSave.id, orderToSave);
          }
        }
      }
      
      print('Importación atómica desde Sheets completada');
    } catch (e) {
      print('Error durante fase local de importación: $e');
      rethrow;
    }
  }

  // --- Calendar Methods ---

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
    } catch (e) { 
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, vuelve a iniciar sesión.');
      }
      print('Error creando evento: $e'); 
      throw Exception('Fallo de Red: No se pudo crear evento en Calendar. ($e)');
    }
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
      if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, vuelve a iniciar sesión.');
      }
      final errorStr = e.toString();
      if (errorStr.contains('404') || errorStr.contains('notFound')) {
        print('LOG: Evento no encontrado en Google Calendar (404). Marcando para re-creación.');
        return false;
      }
      print('Error editando evento en Calendar: $e');
      throw Exception('Fallo de Red: No se pudo actualizar evento en Calendar. ($e)');
    }
  }

  Future<void> deleteCalendarEvent(String eventId) async {
    if (_client == null) return;
    final calendarApi = calendar.CalendarApi(_client!);
    try {
      await calendarApi.events.delete('primary', eventId);
    } catch (e) { 
       if (_isAuthError(e)) {
        await logout();
        throw AuthException('Tu sesión de Google ha caducado. Por favor, vuelve a iniciar sesión.');
      }
      print('Error borrando evento: $e'); 
      throw Exception('Fallo de Red: No se pudo borrar evento en Calendar. ($e)');
    }
  }

  Future<Map<String, dynamic>> syncAllCalendarEvents(List<OrderEntity> orders) async {
    int created = 0, updated = 0, errors = 0;
    List<OrderEntity> syncedOrders = [];

    for (var o in orders) {
      try {
        if (o.googleEventId == null) {
          final id = await createCalendarEvent(o);
          if (id != null) {
            created++; 
            syncedOrders.add(o.copyWith(googleEventId: id));
          } else {
            errors++;
          }
        } else {
          final ok = await updateCalendarEvent(o.googleEventId!, o);
          if (ok) {
            updated++;
            syncedOrders.add(o);
          } else {
            final id = await createCalendarEvent(o);
            if (id != null) {
              created++;
              syncedOrders.add(o.copyWith(googleEventId: id));
            } else {
              errors++;
            }
          }
        }
        // Rate limiting
        await Future.delayed(const Duration(milliseconds: 250));
      } catch (e) {
        errors++;
        if (_isAuthError(e)) {
          rethrow;
        }
      }
    }
    return {'created': created, 'updated': updated, 'errors': errors, 'syncedOrders': syncedOrders};
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
