import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/inventory/data/models/product_model.dart';
import 'features/inventory/presentation/pages/product_management_page.dart';
import 'features/sales/data/models/customer_model.dart';
import 'features/sales/data/models/order_item_model.dart';
import 'features/sales/data/models/order_model.dart';
import 'features/finance/data/models/expense_model.dart';
import 'features/finance/data/models/income_model.dart';
import 'features/inventory/data/models/inventory_item_model.dart';
import 'features/inventory/data/models/stock_movement_model.dart';
import 'core/services/google_cloud_service.dart';

import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/settings/presentation/pages/google_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Spanish locale for date formatting
  await initializeDateFormatting('es_ES', null);
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(OrderModelAdapter());
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(OrderItemModelAdapter());
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(IncomeModelAdapter());
  Hive.registerAdapter(InventoryItemModelAdapter());
  Hive.registerAdapter(StockMovementModelAdapter());
  
  try {
    await Hive.openBox<CustomerModel>('customers');
    await Hive.openBox<OrderModel>('orders');
    await Hive.openBox<ProductModel>('products');
    await Hive.openBox<ExpenseModel>('expenses');
    await Hive.openBox<IncomeModel>('incomes');
    await Hive.openBox<InventoryItemModel>('inventoryItems');
    await Hive.openBox<StockMovementModel>('stockMovements');
    await Hive.openBox('settings');
  } catch (e) {
    print('Error opening box, deleting old data: $e');
    // Close any open boxes first just in case
    await Hive.close(); 
    
    // Delete all boxes from disk
    await Hive.deleteBoxFromDisk('customers');
    await Hive.deleteBoxFromDisk('orders');
    await Hive.deleteBoxFromDisk('products');
    await Hive.deleteBoxFromDisk('expenses');
    await Hive.deleteBoxFromDisk('incomes');
    await Hive.deleteBoxFromDisk('inventoryItems');
    await Hive.deleteBoxFromDisk('stockMovements');
    await Hive.deleteBoxFromDisk('settings');
    
    // Retry opening boxes
    await Hive.openBox<CustomerModel>('customers');
    await Hive.openBox<OrderModel>('orders');
    await Hive.openBox<ProductModel>('products');
    await Hive.openBox<ExpenseModel>('expenses');
    await Hive.openBox<IncomeModel>('incomes');
    await Hive.openBox<InventoryItemModel>('inventoryItems');
    await Hive.openBox<StockMovementModel>('stockMovements');
    await Hive.openBox('settings');
  }
  
  // Attempt silent Google Cloud authentication
  bool needsLogin = false;
  try {
    final googleService = GoogleCloudService();
    final success = await googleService.authenticateFromStoredCredentials();
    if (success) {
      print('Google Cloud: Sesión restaurada automáticamente');
    } else {
      // Check if sync is enabled
      final settingsBox = Hive.box('settings');
      final settingsMap = settingsBox.get('appSettings');
      if (settingsMap != null) {
        final settings = Map<String, dynamic>.from(settingsMap);
        if (settings['syncSheetsEnabled'] == true || settings['syncCalendarEnabled'] == true) {
          needsLogin = true;
          print('Google Cloud: Sesión no restaurada y sincronización activa, forzando login.');
        }
      }
    }
  } catch (e) {
    print('Google Cloud: Error al restaurar la sesión - $e');
  }
  
  runApp(
    ProviderScope(
      child: MyApp(needsLogin: needsLogin),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool needsLogin;
  const MyApp({super.key, this.needsLogin = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(settingsProvider.select((s) => s.isDarkMode));

    return MaterialApp(
      title: 'Corateca App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: needsLogin ? const GoogleLoginPage() : const DashboardPage(),
    );
  }
}

