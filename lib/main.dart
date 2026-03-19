import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/inventory/data/models/product_model.dart';
import 'features/sales/data/models/customer_model.dart';
import 'features/sales/data/models/order_item_model.dart';
import 'features/sales/data/models/order_model.dart';
import 'features/finance/data/models/expense_model.dart';
import 'features/finance/data/models/income_model.dart';
import 'features/inventory/data/models/inventory_item_model.dart';
import 'features/inventory/data/models/stock_movement_model.dart';

import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'core/services/sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables gracefully
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Advertencia: No se encontró archivo .env. Asegúrate de crearlo o verificar que esté en assets.');
  }

  // Initialize Supabase
  bool isSupabaseConfigured = false;
  String supabaseUrl = '';
  String supabaseAnonKey = '';
  
  if (dotenv.isInitialized) {
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }
  
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      isSupabaseConfigured = true;
      debugPrint('Supabase inicializado correctamente.');
  } else {
      debugPrint('Advertencia: Faltan llaves de Supabase en .env');
  }

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
    debugPrint('Error crítico al abrir cajas de Hive: $e');
    debugPrint('Intentando recuperación automática (borrado de datos locales)...');
    
    try {
      // Close everything first
      await Hive.close();
      // Crucial delay for Windows to release file locks
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final boxesToRemove = [
        'customers', 'orders', 'products', 'expenses', 
        'incomes', 'inventoryItems', 'stockMovements', 'settings'
      ];
      
      for (final boxName in boxesToRemove) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          debugPrint('Caja $boxName eliminada con éxito.');
        } catch (error) {
          debugPrint('No se pudo eliminar $boxName: $error');
          // In Windows, sometimes we need to wait more or the file is just stubborn
        }
      }
      
      // Re-initialize and retry
      await Future.delayed(const Duration(milliseconds: 500));
      await Hive.openBox<CustomerModel>('customers');
      await Hive.openBox<OrderModel>('orders');
      await Hive.openBox<ProductModel>('products');
      await Hive.openBox<ExpenseModel>('expenses');
      await Hive.openBox<IncomeModel>('incomes');
      await Hive.openBox<InventoryItemModel>('inventoryItems');
      await Hive.openBox<StockMovementModel>('stockMovements');
      await Hive.openBox('settings');
      debugPrint('Recuperación completada. La aplicación debería iniciar ahora.');
    } catch (recoveryError) {
      debugPrint('Fallo total en la recuperación de Hive: $recoveryError');
      // If we still fail, we allow the app to try to run, 
      // but it will likely crash later when accessing providers.
    }
  }
  
  runApp(
    ProviderScope(
      child: MyApp(isSupabaseConfigured: isSupabaseConfigured),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool isSupabaseConfigured;
  const MyApp({super.key, this.isSupabaseConfigured = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wake up the SyncManager
    ref.watch(syncManagerProvider);
    
    final isDarkMode = ref.watch(settingsProvider.select((s) => s.isDarkMode));

    if (!isSupabaseConfigured) {
      return MaterialApp(
        title: 'Corateca App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Sin base de Datos\nRevisa tu conexión en el entorno',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final authStateAsync = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Corateca App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: authStateAsync.when(
        data: (authState) {
          if (authState.session != null) {
            return const DashboardPage();
          } else {
            return const LoginScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Error de Autenticación: $err')),
        ),
      ),
    );
  }
}
