import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'config/theme/app_theme.dart';
import 'features/finance/data/models/expense_model.dart';
import 'features/finance/data/models/income_model.dart';
import 'features/inventory/data/models/inventory_item_model.dart';
import 'features/inventory/data/models/product_model.dart';
import 'features/inventory/data/models/stock_movement_model.dart';
import 'features/sales/data/models/customer_model.dart';
import 'features/sales/data/models/order_item_model.dart';
import 'features/sales/data/models/order_model.dart';
import 'features/settings/domain/models/brand_config_model.dart';
import 'features/settings/presentation/providers/theme_provider.dart';

import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/session_gate.dart';
import 'core/services/sync_manager.dart';
import 'core/services/window_branding.dart';

/// Navigator global para poder mostrar diálogos desde el interceptor de cierre.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// True en plataformas de escritorio donde window_manager está disponible.
bool get isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

void main() {
  // Captura global de errores asíncronos no manejados.
  runZonedGuarded(_bootstrap, (error, stack) {
    debugPrint('Error no capturado en la app: $error');
    debugPrint('$stack');
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Errores del framework de Flutter (build, layout, gestos...).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError capturado: ${details.exceptionAsString()}');
  };

  // En escritorio, interceptamos el botón de cerrar la ventana para guardar
  // el trabajo antes de salir.
  if (isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
  }

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
  
  String? initializationError;

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
  Hive.registerAdapter(BrandConfigModelAdapter());
  
  try {
    await Hive.openBox<CustomerModel>('customers');
    await Hive.openBox<OrderModel>('orders');
    await Hive.openBox<ProductModel>('products');
    await Hive.openBox<ExpenseModel>('expenses');
    await Hive.openBox<IncomeModel>('incomes');
    await Hive.openBox<InventoryItemModel>('inventoryItems');
    await Hive.openBox<StockMovementModel>('stockMovements');
    await Hive.openBox('settings');
    await Hive.openBox<BrandConfigModel>('brandConfigBox');
  } catch (e) {
    initializationError = 'No se pudo abrir la base local de Hive: $e';
    debugPrint('Error crítico al abrir cajas de Hive: $e');
    debugPrint('No se borraron datos locales automáticamente.');
  }
  
  runApp(
    ProviderScope(
      child: MyApp(
        isSupabaseConfigured: isSupabaseConfigured,
        initializationError: initializationError,
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final bool isSupabaseConfigured;
  final String? initializationError;

  const MyApp({
    super.key,
    this.isSupabaseConfigured = true,
    this.initializationError,
  });

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (isDesktop) {
      windowManager.addListener(this);
      // Ícono inicial de la ventana según el logo de marca actual.
      applyWindowIcon(ref.read(currentBrandConfigProvider).logoBase64);
    }
  }

  @override
  void dispose() {
    if (isDesktop) windowManager.removeListener(this);
    super.dispose();
  }

  /// Interceptor del botón de cerrar la ventana (escritorio). Si hay sesión
  /// activa, avisa y —si el usuario confirma— guarda todo y cierra sesión
  /// antes de salir.
  @override
  void onWindowClose() async {
    final session = widget.isSupabaseConfigured
        ? Supabase.instance.client.auth.currentSession
        : null;
    final ctx = navigatorKey.currentContext;

    // Sin sesión (o sin BD configurada): cerrar directo.
    if (session == null || ctx == null) {
      await windowManager.destroy();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        title: const Text('Cerrar aplicación'),
        content: const Text(
          'Tienes una sesión abierta. Antes de salir guardaremos tu trabajo '
          'en la nube y cerraremos tu sesión. ¿Deseas salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('GUARDAR Y SALIR'),
          ),
        ],
      ),
    );

    if (shouldExit != true) return; // Cancelado: la app sigue abierta.
    if (!mounted) return;

    final progressCtx = navigatorKey.currentContext;
    if (progressCtx != null) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: progressCtx,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Guardando tu trabajo en la nube...')),
            ],
          ),
        ),
      );
    }

    try {
      await ref.read(syncManagerProvider).forceSyncAll();
      await ref.read(loginControllerProvider.notifier).signOut();
    } catch (_) {
      // Aun si algo falla, permitimos salir; lo local queda intacto.
    }

    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    // Actualiza el ícono de la ventana en vivo cuando cambia el logo de marca.
    if (isDesktop) {
      ref.listen(
        currentBrandConfigProvider.select((c) => c.logoBase64),
        (_, next) => applyWindowIcon(next),
      );
    }

    final isSupabaseConfigured = widget.isSupabaseConfigured;
    final initializationError = widget.initializationError;

    if (initializationError != null) {
      return MaterialApp(
        title: 'Papelería Pro',
        debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storage_outlined,
                    size: 80,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo abrir la base local',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    initializationError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    final isDarkMode = ref.watch(settingsProvider.select((s) => s.isDarkMode));

    if (!isSupabaseConfigured) {
      return MaterialApp(
        title: 'Papelería Pro',
        debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
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

    // Wake up the SyncManager only after Supabase is initialized.
    ref.watch(syncManagerProvider);

    final brandConfig = ref.watch(currentBrandConfigProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return MaterialApp(
      title: brandConfig.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme(
        primaryColor: Color(brandConfig.primaryColorHex),
        secondaryColor: Color(brandConfig.accentColorHex),
        background: brandConfig.backgroundColorHex != null
            ? Color(brandConfig.backgroundColorHex!)
            : null,
        surface: brandConfig.surfaceColorHex != null
            ? Color(brandConfig.surfaceColorHex!)
            : null,
      ),
      darkTheme: AppTheme.darkTheme(
        primaryColor: Color(brandConfig.primaryColorHex),
        secondaryColor: Color(brandConfig.accentColorHex),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: authStateAsync.when(
        data: (authState) {
          if (authState.session != null) {
            return const SessionGate();
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
