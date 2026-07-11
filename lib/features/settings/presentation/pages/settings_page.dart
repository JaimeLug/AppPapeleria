import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';
import 'package:app_papeleria/features/settings/presentation/widgets/category_editor_dialog.dart';
import 'package:app_papeleria/features/settings/presentation/widgets/customer_manager_dialog.dart';
import 'package:app_papeleria/features/settings/presentation/pages/app_colors_page.dart';
import 'package:app_papeleria/features/settings/presentation/pages/brand_settings_page.dart';
import 'package:app_papeleria/features/settings/presentation/widgets/settings_dialogs.dart';
import 'package:app_papeleria/features/auth/presentation/logout_helper.dart';

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
                


                // Section 2: Dashboard Personalization
                _buildSectionTitle(context, 'Personalización del Dashboard', Icons.dashboard_customize),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Theme.of(context).primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Tip: Usa la palabra {nombre} en el título para saludar dinámicamente al usuario conectado (Ej: ¡Hola {nombre}!).', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13))),
                          ],
                        ),
                      ),
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
                        leading: Icon(Icons.category, color: Theme.of(context).primaryColor),
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
                        leading: Icon(Icons.people, color: Theme.of(context).primaryColor),
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

                // Section 4: White Label & Appearance
                _buildSectionTitle(context, 'Perfil, Identidad y Apariencia', Icons.palette),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.branding_watermark, color: Theme.of(context).primaryColor),
                        title: const Text('Perfil de Negocio y Marca Blanca'),
                        subtitle: const Text('Administrar identidad corporativa y tema visual global'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandSettingsPage()));
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.palette_outlined, color: Theme.of(context).primaryColor),
                        title: const Text('Colores de la App'),
                        subtitle: const Text('Paleta completa: generales, menú lateral y dashboard'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AppColorsPage()));
                        },
                      ),
                      const Divider(),
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

                // Section 5: Security
                _buildSectionTitle(context, 'Seguridad', Icons.lock),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('PIN de Acceso a Finanzas'),
                        subtitle: Text(settings.securityPin != null && settings.securityPin!.isNotEmpty ? 'PIN Activo (****)' : 'Sin protección'),
                        leading: Icon(Icons.security, color: Theme.of(context).colorScheme.secondary),
                        trailing: ElevatedButton(
                          onPressed: () => _showPinDialog(context, notifier, settings.securityPin),
                          child: Text(settings.securityPin != null && settings.securityPin!.isNotEmpty ? 'Gestionar PIN' : 'Establecer PIN'),
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
                        children: ref.watch(databaseStatsProvider).when(
                          data: (stats) => [
                            _buildStatItem('Pedidos', stats['orders']?.toString() ?? '0'),
                            _buildStatItem('Clientes', stats['customers']?.toString() ?? '0'),
                            _buildStatItem('Productos', stats['products']?.toString() ?? '0'),
                            _buildStatItem('Inventario', stats['inventoryItems']?.toString() ?? '0'),
                          ],
                          loading: () => [const CircularProgressIndicator(), const CircularProgressIndicator(), const CircularProgressIndicator(), const CircularProgressIndicator()],
                          error: (_, __) => [const Text('Error'), const Text('Error'), const Text('Error'), const Text('Error')],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup guardado exitosamente')));
                                } catch (e) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restaurado. Reiniciando vistas...')));
                                  } 
                                } catch (e) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
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
                const SizedBox(height: 32),
                
                // Section 7: Account
                _buildSectionTitle(context, 'Cuenta de Usuario', Icons.person_outline),
                _buildCard(
                  context,
                  child: ListTile(
                    title: const Text('Cerrar Sesión'),
                    subtitle: const Text('Desvincular cuenta de este dispositivo'),
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      onPressed: () => confirmSaveAndSignOut(context, ref),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Text('Versión 1.3.0', style: TextStyle(color: Colors.grey[400])),
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
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).textTheme.headlineSmall?.color,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  void _showPinDialog(BuildContext context, SettingsNotifier notifier, String? currentPin) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        notifier: notifier,
        currentPin: currentPin,
        onRemove: () {
          Navigator.pop(context);
          _showRemovePinDialog(context, notifier);
        },
      ),
    );
  }

  void _showRemovePinDialog(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => RemovePinDialog(notifier: notifier),
    );
  }

  void _showResetDialog(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => ResetDialog(notifier: notifier),
    );
  }
}
