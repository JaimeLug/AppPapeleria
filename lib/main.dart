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
import 'core/services/supabase_credentials_store.dart';
import 'core/services/window_branding.dart';
import 'features/onboarding/presentation/pages/onboarding_wizard.dart';
import 'features/onboarding/presentation/pages/database_setup_screen.dart';

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

  // Pinta ALGO de inmediato, antes de toda la inicialización. Si esta pantalla
  // aparece, Flutter puede dibujar (el problema estaría en la inicialización);
  // si la ventana queda en gris total, es un problema de render (GPU/motor).
  runApp(const _StartupSplash());

  // A partir de aquí CADA paso va protegido: pase lo que pase, se llega a
  // runApp(). Si un paso crítico (Hive) falla, se muestra el error en
  // pantalla en vez de dejar la ventana en gris.
  String? initializationError;

  // En escritorio, interceptamos el botón de cerrar la ventana para guardar
  // el trabajo antes de salir.
  if (isDesktop) {
    try {
      await windowManager.ensureInitialized();
      await windowManager.setPreventClose(true);
    } catch (e) {
      debugPrint('window_manager no se pudo inicializar: $e');
    }
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

  // Prioridad: credenciales guardadas (asistente) SOBRE el .env por defecto.
  // Si leer el almacenamiento cifrado falla (p. ej. en un equipo nuevo), no
  // debe tumbar el arranque: se cae al .env.
  try {
    final storedCreds = await SupabaseCredentialsStore.load();
    if (storedCreds != null) {
      supabaseUrl = storedCreds.url;
      supabaseAnonKey = storedCreds.anonKey;
    }
  } catch (e) {
    debugPrint('No se pudieron leer credenciales guardadas: $e');
  }
  if (supabaseUrl.isEmpty && dotenv.isInitialized) {
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ).timeout(const Duration(seconds: 20));
      isSupabaseConfigured = true;
      debugPrint('Supabase inicializado correctamente.');
    } catch (e) {
      // No es fatal: la app puede abrir la pantalla de configuración.
      debugPrint('Supabase.initialize falló: $e');
    }
  } else {
    debugPrint('Advertencia: Faltan llaves de Supabase (ni guardadas ni en .env)');
  }

  // Initialize Spanish locale for date formatting
  try {
    await initializeDateFormatting('es_ES', null);
  } catch (e) {
    debugPrint('initializeDateFormatting falló: $e');
  }

  // Initialize Hive (crítico: sin base local la app no funciona)
  try {
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
    initializationError = 'No se pudo iniciar la base local: $e';
    debugPrint('Error crítico en Hive: $e');
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

/// Pantalla mínima que se pinta antes de inicializar todo. No usa providers
/// ni Supabase (aún no existen). Sirve de splash y de diagnóstico de render.
class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Papelería Pro',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.titleColor,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppTheme.defaultPrimary),
              const SizedBox(height: 16),
              Text(
                'Iniciando…',
                style: TextStyle(color: AppTheme.bodyColor, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
      // Sin credenciales de Supabase: pantalla para ingresarlas. No usa
      // providers que dependan de Supabase (aún no está inicializado).
      return MaterialApp(
        title: 'Papelería Pro',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const DatabaseSetupScreen(),
      );
    }

    // Wake up the SyncManager only after Supabase is initialized.
    ref.watch(syncManagerProvider);

    final brandConfig = ref.watch(currentBrandConfigProvider);
    final authStateAsync = ref.watch(authStateProvider);
    // Primera vez en este dispositivo: muestra el asistente de bienvenida.
    final onboardingDone =
        ref.watch(settingsProvider.select((s) => s.onboardingCompleted));

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
      home: !onboardingDone
          ? const OnboardingWizard(isSupabaseConfigured: true)
          : authStateAsync.when(
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
