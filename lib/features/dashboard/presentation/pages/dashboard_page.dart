import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../inventory/presentation/pages/product_management_page.dart';
import '../../../sales/presentation/pages/sales_page.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../finance/presentation/widgets/month_selector.dart';
import '../providers/dashboard_provider.dart';
import '../../../sales/presentation/pages/orders_page.dart';
import '../../../sales/presentation/pages/agenda_page.dart';
import '../../../finance/presentation/pages/expenses_page.dart';
import '../../../sales/presentation/providers/orders_provider.dart';
import 'package:app_papeleria/features/settings/presentation/pages/settings_page.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';
import '../../domain/models/dashboard_widget_config.dart';
import '../../presentation/widgets/dashboard_widget_wrapper.dart'; // Needed for type checking/stack wrapping if explicit
import '../utils/dashboard_constants.dart';
import '../utils/dashboard_widgets_registry.dart';
import '../widgets/add_widget_sheet.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;
  bool _isDragging = false; // We can track this if DashboardWidgetWrapper notifies us, 
                            // or imply it via DragTarget. But Draggable is now deep inside.
                            // To update FAB we need to know. 
                            // For now, FAB might not turn red unless we lift state.
                            // Ignoring FAB visual change for strict adherence to "Handle Only" first,
                            // OR we accept that FAB might stay static if not getting callbacks.
                            // Users requested "Elimina LongPressDragabble... Activacion... ::".
                            // I will keep Layout responsive first.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context),
          // Main Content
          Expanded(
            child: _selectedIndex == 0
                ? _buildDashboardContent(context)
                : _selectedIndex == 1
                    ? const OrdersPage()
                    : _selectedIndex == 2
                        ? const ProductManagementPage()
                        : _selectedIndex == 3
                            ? const SalesPage()
                            : _selectedIndex == 4
                                ? const AgendaPage()
                                : _selectedIndex == 5
                                    ? const ExpensesPage()
                                    : _selectedIndex == 6
                                        ? const SettingsPage()
                                        : const Center(child: Text('Coming Soon')),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? _buildMutantFab(context) : null,
    );
  }

  Widget _buildMutantFab(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (data) => true,
      onAccept: (widgetId) {
        _removeWidget(widgetId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Widget eliminado')),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        // _isDragging logic needs to be hoisted to make this perfect, 
        // but for now relying on target state is decent feedback.
        return AnimatedScale(
          scale: isTargeted ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            onPressed: _showAddWidgetSheet,
            backgroundColor: isTargeted ? Colors.redAccent : AppTheme.primaryColor,
            child: Icon(
              isTargeted ? Icons.delete_outline : Icons.add,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  void _navigateTo(int index) {
    if (index == 5) {
      final settings = ref.read(settingsProvider);
      if (settings.securityPin != null && settings.securityPin!.isNotEmpty) {
        _showPinDialog(index, settings.securityPin!);
        return;
      }
    }
    setState(() => _selectedIndex = index);
  }

  void _showPinDialog(int targetIndex, String correctPin) {
    // ... same logic
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloqueo de Seguridad'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Ingresa PIN', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (controller.text == correctPin) {
                Navigator.pop(context);
                setState(() => _selectedIndex = targetIndex);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN Incorrecto'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 40, fit: BoxFit.contain),
                const SizedBox(width: 12),
                Text(
                  'Corateca.',
                  style: GoogleFonts.quicksand(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          _SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', isSelected: _selectedIndex == 0, onTap: () => _navigateTo(0)),
          _SidebarItem(icon: Icons.list_alt_outlined, label: 'Pedidos', isSelected: _selectedIndex == 1, onTap: () => _navigateTo(1)),
          _SidebarItem(icon: Icons.inventory_2_outlined, label: 'Productos', isSelected: _selectedIndex == 2, onTap: () => _navigateTo(2)),
          _SidebarItem(icon: Icons.shopping_bag_outlined, label: 'Ventas', isSelected: _selectedIndex == 3, onTap: () => _navigateTo(3)),
          _SidebarItem(icon: Icons.calendar_today_outlined, label: 'Agenda', isSelected: _selectedIndex == 4, onTap: () => _navigateTo(4)),
          _SidebarItem(icon: Icons.attach_money, label: 'Finanzas', isSelected: _selectedIndex == 5, onTap: () => _navigateTo(5)),
          const Spacer(),
          _SidebarItem(icon: Icons.settings_outlined, label: 'Configuración', isSelected: _selectedIndex == 6, onTap: () => _navigateTo(6)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    // Optimization: Select only the fields we trigger rebuilds on. 
    // Watching the whole provider caused full rebuilds on QuickNote changes.
    final layout = ref.watch(settingsProvider.select((s) => s.dashboardLayout)) 
                   ?? DashboardWidgetIds.defaultLayout.map((id) => DashboardWidgetConfig(id: id)).toList();
    
    final welcomeTitle = ref.watch(settingsProvider.select((s) => s.dashboardWelcomeTitle));
    final welcomeSubtitle = ref.watch(settingsProvider.select((s) => s.dashboardWelcomeSubtitle));

    ref.watch(dashboardStatsProvider); 

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(welcomeTitle, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text(welcomeSubtitle, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
              const MonthSelector(),
            ],
          ),
          const SizedBox(height: 32),

          // Dynamic Layout
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                
                // --- PHASE 19.4: HEADER FIX & 4-COLUMN GRID ---
                // User requested 4 columns base instead of 5.
                int cols = 4; 
                
                // Responsive adjustments
                if (width < 600) cols = 2;
                else if (width < 900) cols = 3;
                // else if (width < 1100) cols = 3; // Maybe keep 3 longer? 
                // > 900 -> 4 columns is standard desktop.
                
                final spacing = 16.0;
                final unitWidth = (width - ((cols - 1) * spacing)) / cols;
                
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: layout.map((config) => _buildTargetWidget(config, context, unitWidth, cols, spacing)).toList(),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetWidget(DashboardWidgetConfig config, BuildContext context, double unitWidth, int totalCols, double spacing) {
    // Calculate effective width based on span
    final effectiveSpan = config.widthSpan > totalCols ? totalCols : config.widthSpan;
    final width = (unitWidth * effectiveSpan) + ((effectiveSpan - 1) * spacing);
    
    // Height logic 
    const double baseHeight = 140.0;
    final height = (baseHeight * config.heightSpan) + ((config.heightSpan - 1) * spacing);
    
    final widgetContent = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      child: DashboardWidgetRegistry.build(
        config.id, 
        context, 
        isDragging: false, 
        onRemove: () => _removeWidget(config.id),
        onResize: () => _resizeWidgetWidth(config), // Width Resize
        onResizeHeight: _canResizeHeight(config.id) ? () => _resizeWidgetHeight(config) : null, // Height Resize
      ),
    );

    // Target for DROPPING reordering
    return DragTarget<String>(
      onWillAccept: (incomingId) => incomingId != null && incomingId != config.id,
      onAccept: (incomingId) => _reorderWidget(incomingId, config.id),
      builder: (context, candidateData, rejectedData) {
         return widgetContent;
      },
    );
  }

  bool _canResizeHeight(String id) {
    // Restrictions: Financial cards (Income, Expenses, etc.) are fixed height x1.
    // Lists and Charts can be resized.
    if (id == DashboardWidgetIds.income || 
        id == DashboardWidgetIds.expenses || 
        id == DashboardWidgetIds.netProfit || 
        id == DashboardWidgetIds.accountsReceivable ||
        id == DashboardWidgetIds.pendingDeliveries ||
        id == DashboardWidgetIds.clock) {
      return false;
    }
    return true; // Trend, Top Products, Next Deliveries, Quick Note, etc.
  }

  void _resizeWidgetWidth(DashboardWidgetConfig config) {
    // 1 -> 2 -> [3/4] -> 1
    int maxSpan = 4; // Max columns is usually 4
    
    int newSpan = config.widthSpan + 1;
    if (newSpan > maxSpan) newSpan = 1;
    
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentLayout = List<DashboardWidgetConfig>.from(ref.read(settingsProvider).dashboardLayout ?? []);
    
    final index = currentLayout.indexWhere((c) => c.id == config.id);
    if (index != -1) {
      currentLayout[index] = config.copyWith(widthSpan: newSpan);
      settingsNotifier.updateDashboardLayout(currentLayout);
    }
  }

  void _resizeWidgetHeight(DashboardWidgetConfig config) {
    // 1 -> 2 -> 3 -> 1
    int maxSpan = 3;
    
    int newSpan = config.heightSpan + 1;
    if (newSpan > maxSpan) newSpan = 1;
    
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentLayout = List<DashboardWidgetConfig>.from(ref.read(settingsProvider).dashboardLayout ?? []);
    
    final index = currentLayout.indexWhere((c) => c.id == config.id);
    if (index != -1) {
      currentLayout[index] = config.copyWith(heightSpan: newSpan);
      settingsNotifier.updateDashboardLayout(currentLayout);
    }
  }

  void _removeWidget(String id) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentLayout = List<DashboardWidgetConfig>.from(ref.read(settingsProvider).dashboardLayout ?? []);
    currentLayout.removeWhere((c) => c.id == id);
    settingsNotifier.updateDashboardLayout(currentLayout);
  }

  void _addWidget(String id) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentLayout = List<DashboardWidgetConfig>.from(ref.read(settingsProvider).dashboardLayout ?? []);
    if (!currentLayout.any((c) => c.id == id)) {
      currentLayout.add(DashboardWidgetConfig(id: id));
      settingsNotifier.updateDashboardLayout(currentLayout);
    }
  }

  void _reorderWidget(String incomingId, String targetId) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentLayout = List<DashboardWidgetConfig>.from(ref.read(settingsProvider).dashboardLayout ?? []);
    
    final oldIndex = currentLayout.indexWhere((c) => c.id == incomingId);
    final newIndex = currentLayout.indexWhere((c) => c.id == targetId);
    
    if (oldIndex != -1 && newIndex != -1) {
      final item = currentLayout.removeAt(oldIndex);
      currentLayout.insert(newIndex, item);
      settingsNotifier.updateDashboardLayout(currentLayout);
    }
  }

  void _showAddWidgetSheet() {
    final layout = ref.read(settingsProvider).dashboardLayout ?? [];
    // Convert to List<String> for the sheet
    final currentIds = layout.map((c) => c.id).toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddWidgetSheet(
        currentLayout: currentIds,
        onAdd: _addWidget,
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
