import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_papeleria/config/theme/app_theme.dart';
import 'package:app_papeleria/core/services/google_cloud_service.dart';
import 'package:app_papeleria/features/finance/data/models/expense_model.dart';
import 'package:app_papeleria/features/finance/data/models/income_model.dart';
import 'package:app_papeleria/features/finance/presentation/providers/finance_provider.dart';
import 'package:app_papeleria/features/inventory/data/models/product_model.dart';
import 'package:app_papeleria/features/inventory/presentation/providers/product_providers.dart';
import 'package:app_papeleria/features/sales/data/models/customer_model.dart';
import 'package:app_papeleria/features/sales/data/models/order_model.dart';
import 'package:app_papeleria/features/sales/presentation/providers/customer_provider.dart';
import 'package:app_papeleria/features/sales/presentation/providers/orders_provider.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';
import 'package:app_papeleria/features/settings/presentation/widgets/category_editor_dialog.dart';
import 'package:app_papeleria/features/settings/presentation/widgets/customer_manager_dialog.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _footerController;
  late TextEditingController _pinController;
  late TextEditingController _dashboardTitleController;
  late TextEditingController _dashboardSubtitleController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: settings.businessName);
    _addressController = TextEditingController(text: settings.businessAddress);
    _phoneController = TextEditingController(text: settings.businessPhone);
    _footerController = TextEditingController(text: settings.receiptFooterMessage);
    _pinController = TextEditingController(text: settings.securityPin ?? '');
    _dashboardTitleController = TextEditingController(text: settings.dashboardWelcomeTitle);
    _dashboardSubtitleController = TextEditingController(text: settings.dashboardWelcomeSubtitle);

    // Fixed Sheet ID for v1.3.0
    const fixedSheetId = '1nDpb3WlAhD-XtIvx_CPuM87UlDntvhY1NxCr_XapM8w';
    if (settings.googleSheetId != fixedSheetId) {
      Future.microtask(() => ref.read(settingsProvider.notifier).updateGoogleConfig(sheetId: fixedSheetId));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    _pinController.dispose();
    _dashboardTitleController.dispose();
    _dashboardSubtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                
                // Section 1: Business Profile
                _buildSectionTitle(context, 'Perfil del Negocio', Icons.store),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      _buildTextField(
                        context: context,
                        controller: _nameController, 
                        label: 'Nombre de la Papelería', 
                        icon: Icons.business,
                        onChanged: (val) => notifier.updateBusinessInfo(name: val),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              controller: _phoneController, 
                              label: 'Teléfono', 
                              icon: Icons.phone,
                              onChanged: (val) => notifier.updateBusinessInfo(phone: val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              controller: _addressController, 
                              label: 'Dirección', 
                              icon: Icons.location_on,
                              onChanged: (val) => notifier.updateBusinessInfo(address: val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context: context,
                        controller: _footerController, 
                        label: 'Mensaje al pie del ticket', 
                        icon: Icons.receipt_long, 
                        maxLines: 2,
                        onChanged: (val) => notifier.updateBusinessInfo(footerMessage: val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Section 2: Dashboard Personalization
                _buildSectionTitle(context, 'Personalización del Dashboard', Icons.dashboard_customize),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      _buildTextField(
                        context: context,
                        controller: _dashboardTitleController,
                        label: 'Título del Dashboard',
                        icon: Icons.title,
                        onChanged: (val) => notifier.updateDashboardWelcome(title: val),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context: context,
                        controller: _dashboardSubtitleController,
                        label: 'Subtítulo del Dashboard',
                        icon: Icons.subtitles,
                        onChanged: (val) => notifier.updateDashboardWelcome(subtitle: val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Section 3: Catalog Management
                _buildSectionTitle(context, 'Gestión de Catálogos', Icons.inventory),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.category, color: AppTheme.primaryColor),
                        title: const Text('Categorías de Productos'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => const CategoryEditorDialog(),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.people, color: AppTheme.primaryColor),
                        title: const Text('Administrar Clientes'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color),
                        onTap: () {
                           showDialog(
                            context: context,
                            builder: (_) => const CustomerManagerDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Section 3: Appearance & Notifications
                _buildSectionTitle(context, 'Apariencia y Alertas', Icons.palette),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Modo Oscuro'),
                        secondary: const Icon(Icons.dark_mode),
                        value: settings.isDarkMode,
                        onChanged: (val) => notifier.toggleTheme(val),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Umbral de Pedido Urgente'),
                        subtitle: Text('${settings.urgentOrderThresholdDays} días antes de la entrega'),
                        leading: const Icon(Icons.notification_important, color: Colors.orange),
                        trailing: SizedBox(
                          width: 150,
                          child: Slider(
                            value: settings.urgentOrderThresholdDays.toDouble(),
                            min: 1,
                            max: 7,
                            divisions: 6,
                            label: '${settings.urgentOrderThresholdDays} días',
                            onChanged: (val) => notifier.setUrgentThreshold(val.toInt()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Section 4: Security
                _buildSectionTitle(context, 'Seguridad', Icons.lock),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('PIN de Acceso a Finanzas'),
                        subtitle: Text(settings.securityPin != null && settings.securityPin!.isNotEmpty ? 'PIN Activo (****)' : 'Sin protección'),
                        leading: const Icon(Icons.security, color: AppTheme.secondaryColor),
                        trailing: ElevatedButton(
                          onPressed: () => _showPinDialog(context, notifier, settings.securityPin),
                          child: Text(settings.securityPin != null && settings.securityPin!.isNotEmpty ? 'Gestionar PIN' : 'Establecer PIN'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Section 5: Cloud Connection
                _buildSectionTitle(context, 'Conexión en la Nube', Icons.cloud_sync),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Sincronizar Pedidos (Sheets)'),
                        subtitle: const Text('Requiere ID de Hoja de Cálculo'),
                        value: settings.syncSheetsEnabled,
                        onChanged: (val) => notifier.updateGoogleConfig(syncSheets: val),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Eventos en Calendario'),
                        subtitle: const Text('Crear evento al confirmar pedido'),
                        value: settings.syncCalendarEnabled,
                        onChanged: (val) => notifier.updateGoogleConfig(syncCalendar: val),
                      ),
                      const Divider(),
                       _buildTextField(
                        context: context,
                        controller: TextEditingController(text: settings.googleSheetId)
                          ..selection = TextSelection.fromPosition(TextPosition(offset: settings.googleSheetId?.length ?? 0)),
                        label: 'ID de Google Sheet',
                        icon: Icons.table_chart,
                        onChanged: (val) => notifier.updateGoogleConfig(sheetId: val),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.sync_problem),
                          label: const Text('MENÚ DE SINCRONIZACIÓN AVANZADA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          onPressed: () => _showAdvancedSyncDialog(context, ref, settings),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Autenticar con Google'),
                          onPressed: () async {
                             if (settings.googleClientId == null || settings.googleClientSecret == null) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faltan credenciales (Configurar en Desarrollador)')));
                               return;
                             }
                             
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Row(
                                   children: [
                                     SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                     SizedBox(width: 16),
                                     Text('Autenticando...'),
                                   ],
                                 ),
                                 duration: Duration(seconds: 30),
                               ),
                             );
                             
                             try {
                               final googleService = GoogleCloudService();
                               await googleService.authenticate();
                               if (context.mounted) {
                                 ScaffoldMessenger.of(context).clearSnackBars();
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text('¡Autenticado con Google exitosamente!'), backgroundColor: Colors.green),
                                 );
                               }
                             } catch (e) {
                               if (context.mounted) {
                                 ScaffoldMessenger.of(context).clearSnackBars();
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
                                 );
                               }
                             }
                          },
                        ),
                      ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Actualizar Calendario Completo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple,
                              side: const BorderSide(color: Colors.purple),
                            ),
                            onPressed: () async {
                              final googleService = GoogleCloudService();
                              if (!googleService.isAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero debes autenticarte con Google')));
                                return;
                              }
                              
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        ),
                                        SizedBox(width: 16),
                                        Text('Sincronizando calendario...'),
                                      ],
                                    ),
                                    duration: Duration(seconds: 60),
                                  ),
                                );
                                
                                // Get all pending orders
                                final ordersBox = Hive.box<OrderModel>('orders');
                                final pendingOrders = ordersBox.values.where((o) => o.deliveryStatus == 'pending').toList();
                                
                                final result = await googleService.syncAllCalendarEvents(pendingOrders);
                                
                                // Update orders with new event IDs
                                for (final order in pendingOrders) {
                                  if (order.googleEventId != null) {
                                    await ordersBox.put(order.id, order);
                                  }
                                }
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✓ Calendario sincronizado: ${result['created']} creados, ${result['updated']} actualizados'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error sincronizando calendario: $e'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Section 6: Developer Tools
                _buildSectionTitle(context, 'Herramientas del Desarrollador', Icons.code),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Pedidos', Hive.box<OrderModel>('orders').length.toString()),
                          _buildStatItem('Clientes', Hive.box<CustomerModel>('customers').length.toString()),
                          _buildStatItem('Productos', Hive.box<ProductModel>('products').length.toString()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      ListTile(
                        title: const Text('Configurar API Google'),
                        subtitle: Text(settings.googleClientId != null ? 'Credenciales cargadas' : 'No configurado'),
                        trailing: const Icon(Icons.lock_outline),
                        onTap: () => _showGoogleCredentialsDialog(context, notifier, settings),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Exportar Backup'),
                              onPressed: () async {
                                try {
                                  await notifier.exportBackup();
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup guardado exitosamente')));
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                           Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.upload),
                              label: const Text('Importar Backup'),
                              onPressed: () async {
                                try {
                                  await notifier.importBackup();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restaurado. Reiniciando vistas...')));
                                    // Optional: Trigger full app refresh if needed, but providers notify listeners so it should update.
                                  } 
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Resetear Base de Datos (Fábrica)'),
                          onPressed: () => _showResetDialog(context, notifier),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Text('Versión 1.2.1', style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(height: 4),
                      Text('Desarrollado con ❤️ por Jaime Lugo', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Centro de Configuración',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Personaliza tu experiencia y gestiona tu negocio',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).textTheme.headlineSmall?.color, // Dynamic color
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Dynamic Card Color
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        labelStyle: Theme.of(context).inputDecorationTheme.labelStyle,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        Text(label, style: TextStyle(color: Colors.grey[600])), // Consider making this dynamic too if needed
      ],
    );
  }

  void _showPinDialog(BuildContext context, SettingsNotifier notifier, String? currentPin) {
    bool isEditing = currentPin != null && currentPin.isNotEmpty;
    final controller = TextEditingController(); // For new PIN
    final oldController = TextEditingController(); // For confirming old PIN if removing
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Gestionar PIN' : 'Establecer PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             if (isEditing) ...[
               const Text('Acciones disponibles:'),
               const SizedBox(height: 16),
               SizedBox(
                 width: double.infinity,
                 child: OutlinedButton(
                   onPressed: () {
                     Navigator.pop(context);
                     _showRemovePinDialog(context, notifier);
                   },
                   style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                   child: const Text('Eliminar PIN'),
                 ),
               ),
               const SizedBox(height: 16),
               const Text('O cambiar PIN:'),
             ],
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nuevo PIN (4 dígitos)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length == 4) {
                notifier.setSecurityPin(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Actualizado')));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  void _showRemovePinDialog(BuildContext context, SettingsNotifier notifier) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Ingresa el PIN actual',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
               try {
                 notifier.removeSecurityPin(controller.text);
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Eliminado')));
               } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Incorrecto')));
               }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsNotifier notifier) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset de Fábrica', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esta acción BORRARÁ TODOS LOS PEDIDOS, CLIENTES Y DATOS. No se puede deshacer.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN de Desarrollador',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await notifier.factoryReset(pinController.text);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sistema restablecido de fábrica')));
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Incorrecto. Acción cancelada.')));
                }
              }
            },
            child: const Text('BORRAR TODO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGoogleCredentialsDialog(BuildContext context, SettingsNotifier notifier, AppSettings settings) {
      final pinController = TextEditingController();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Configuración Cloud'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Introduce PIN de Desarrollador (2308)'),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                 decoration: const InputDecoration(labelText: 'PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (pinController.text == '2308') {
                  Navigator.pop(context);
                  _showGoogleConfigForm(context, notifier, settings);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Incorrecto')));
                }
              },
              child: const Text('Acceder'),
            ),
          ],
        ),
      );
  }

  void _showGoogleConfigForm(BuildContext context, SettingsNotifier notifier, AppSettings settings) {
    final clientIdController = TextEditingController(text: settings.googleClientId);
    final clientSecretController = TextEditingController(text: settings.googleClientSecret);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Credenciales de Google Cloud'),
        content: SizedBox(
          width: 400,
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Text('Introduce el Client ID y Client Secret de tu proyecto en Google Cloud Console.'),
                const SizedBox(height: 16),
               TextField(
                 controller: clientIdController,
                 decoration: const InputDecoration(labelText: 'Client ID', border: OutlineInputBorder()),
               ),
               const SizedBox(height: 16),
               TextField(
                 controller: clientSecretController,
                 decoration: const InputDecoration(labelText: 'Client Secret', border: OutlineInputBorder()),
                 obscureText: true, 
               ),
             ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              notifier.updateGoogleConfig(
                clientId: clientIdController.text,
                clientSecret: clientSecretController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credenciales guardadas')));
            },
             child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // --- Advanced Sync Methods ---

  void _showAdvancedSyncDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sync_problem, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Sincronización Avanzada'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _syncOption(
                context,
                icon: Icons.cloud_upload,
                color: Colors.blue,
                title: 'Exportación Incremental',
                subtitle: 'Sube solo lo nuevo a la nube (No borra nada)',
                onTap: () => _performSync(context, ref, settings, 'incremental_export'),
              ),
              const Divider(),
              _syncOption(
                context,
                icon: Icons.cloud_done,
                color: Colors.green,
                title: 'Sobrescribir Nube',
                subtitle: 'Limpia la nube y sube todo lo local (Nube = Local)',
                onTap: () async {
                  final confirm = await _showConfirm(context, '¿Sobrescribir Nube?', 'Esto borrará los datos actuales en Google Sheets. ¿Continuar?');
                  if (confirm && context.mounted) _performSync(context, ref, settings, 'overwrite_cloud');
                },
              ),
              const Divider(),
              _syncOption(
                context,
                icon: Icons.merge_type,
                color: Colors.orange,
                title: 'Importación Fusionada',
                subtitle: 'Trae lo de la nube sin borrar lo local (Combina)',
                onTap: () => _performSync(context, ref, settings, 'merge_import'),
              ),
              const Divider(),
              _syncOption(
                context,
                icon: Icons.restore_from_trash,
                color: Colors.red,
                title: 'Restauración Total',
                subtitle: 'Borra TODO lo local y trae lo de la nube (Local = Nube)',
                onTap: () async {
                  final pin = await _showPinCodeDialog(context);
                  if (pin == '2308' && context.mounted) {
                    _performSync(context, ref, settings, 'total_restore');
                  } else if (pin != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Incorrecto'), backgroundColor: Colors.red));
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR')),
        ],
      ),
    );
  }

  Widget _syncOption(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _performSync(BuildContext context, WidgetRef ref, AppSettings settings, String mode) async {
    final googleService = GoogleCloudService();
    if (!googleService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No autenticado con Google')));
      return;
    }

    final sheetId = settings.googleSheetId ?? '1nDpb3WlAhD-XtIvx_CPuM87UlDntvhY1NxCr_XapM8w';
    
    // UI Local state for the progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24), 
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                CircularProgressIndicator(), 
                SizedBox(height: 16), 
                Text('Sincronizando...')
              ] 
            )
          )
        )
      ),
    );

    try {
      if (mode == 'incremental_export' || mode == 'overwrite_cloud') {
        final overwrite = mode == 'overwrite_cloud';
        
        await googleService.bulkExportOrders(sheetId, Hive.box<OrderModel>('orders').values.toList(), overwrite: overwrite);
        await googleService.bulkExportExpenses(sheetId, Hive.box<ExpenseModel>('expenses').values.toList(), overwrite: overwrite);
        await googleService.bulkExportIncomes(sheetId, Hive.box<IncomeModel>('incomes').values.toList(), overwrite: overwrite);
        await googleService.bulkExportCustomers(sheetId, Hive.box<CustomerModel>('customers').values.toList(), overwrite: overwrite);
        await googleService.bulkExportProducts(sheetId, Hive.box<ProductModel>('products').values.toList(), overwrite: overwrite);
        await googleService.bulkExportCategories(sheetId, settings.productCategories, overwrite: overwrite);
      } else {
        final replaceLocal = mode == 'total_restore';
        await googleService.importFromSheets(sheetId, replaceLocal: replaceLocal);
        
        ref.invalidate(settingsProvider);
        ref.invalidate(ordersProvider);
        ref.invalidate(productListProvider);
        ref.invalidate(customerListProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(incomesProvider);
        ref.invalidate(unifiedTransactionsProvider);
      }

      if (context.mounted) {
        Navigator.pop(context); // Close progress
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Operación completada con éxito'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close progress
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<bool> _showConfirm(BuildContext context, String title, String msg) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONTINUAR')),
        ],
      )
    ) ?? false;
  }

  Future<String?> _showPinCodeDialog(BuildContext context) async {
    String pin = '';
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PIN de Seguridad'),
        content: TextField(
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Ingrese PIN para Restauración Total'),
          onChanged: (v) => pin = v,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, pin), child: const Text('VALIDAR')),
        ],
      ),
    );
  }
}
