import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../inventory/presentation/pages/product_management_page.dart';
import '../../../sales/presentation/pages/sales_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../finance/presentation/widgets/month_selector.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../sales/presentation/pages/orders_page.dart';
import '../../../sales/presentation/pages/agenda_page.dart';
import '../../../finance/presentation/pages/expenses_page.dart';
import '../../../sales/presentation/providers/orders_provider.dart';
import 'package:app_papeleria/features/settings/presentation/pages/settings_page.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
    );
  }

  void _navigateTo(int index) {
    // If navigating to Finance (index 5) and PIN is set, ask for PIN
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
          decoration: const InputDecoration(
            labelText: 'Ingresa PIN',
            border: OutlineInputBorder(),
          ),
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
      color: Theme.of(context).cardColor, // Dynamic Background
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
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
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isSelected: _selectedIndex == 0,
            onTap: () => _navigateTo(0),
          ),
           _SidebarItem(
            icon: Icons.list_alt_outlined,
            label: 'Pedidos',
            isSelected: _selectedIndex == 1,
            onTap: () => _navigateTo(1),
          ),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Productos',
            isSelected: _selectedIndex == 2,
            onTap: () => _navigateTo(2),
          ),
          _SidebarItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Ventas',
            isSelected: _selectedIndex == 3,
            onTap: () => _navigateTo(3),
          ),
          _SidebarItem(
            icon: Icons.calendar_today_outlined,
            label: 'Agenda',
            isSelected: _selectedIndex == 4,
            onTap: () => _navigateTo(4),
          ),
          _SidebarItem(
            icon: Icons.attach_money,
            label: 'Finanzas',
            isSelected: _selectedIndex == 5,
            onTap: () => _navigateTo(5),
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Configuración',
            isSelected: _selectedIndex == 6,
            onTap: () => _navigateTo(6),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final settings = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Month Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.dashboardWelcomeTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.dashboardWelcomeSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              // Month Selector from Finance Module
              const MonthSelector(), 
            ],
          ),
          const SizedBox(height: 32),
          
          statsAsync.when(
            data: (stats) {
              final settings = ref.watch(settingsProvider);
              return Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI Cards Grid
                      SizedBox(
                        height: 180, // Fixed height for cards row
                        child: Row(
                          children: [
                            Expanded(
                              child: _BentoCard(
                                title: 'Ingresos Reales',
                                value: '\$${stats.totalIncome.toStringAsFixed(2)}',
                                subtitle: 'Cobrado este mes',
                                icon: Icons.attach_money,
                                color: Colors.green, // Visual distinction
                                isDark: false,
                                onTap: () => _navigateTo(5), // Navigate to Finance
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _BentoCard(
                                title: 'Gastos del Mes',
                                value: '\$${stats.totalExpenses.toStringAsFixed(2)}',
                                subtitle: 'Total egresos',
                                icon: Icons.money_off,
                                color: Colors.redAccent,
                                isDark: false,
                                onTap: () => _navigateTo(5), // Navigate to Finance
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _BentoCard(
                                title: 'Utilidad Neta',
                                value: '\$${stats.netProfit.toStringAsFixed(2)}',
                                subtitle: 'Ingresos - Gastos',
                                icon: Icons.trending_up,
                                // Dynamic Color Logic: Green if > 0, Red if < 0, Grey if 0
                                color: stats.netProfit > 0 
                                    ? Colors.green 
                                    : (stats.netProfit < 0 ? Colors.red : Colors.grey), 
                                isDark: true,
                                onTap: () => _navigateTo(5), // Navigate to Finance
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _BentoCard(
                                title: 'Por Cobrar',
                                value: '\$${stats.accountsReceivable.toStringAsFixed(2)}',
                                subtitle: 'Saldo pendiente global',
                                icon: Icons.account_balance_wallet_outlined,
                                color: Colors.orange,
                                isDark: false,
                                onTap: () => _navigateTo(1), // Navigate to Orders
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _BentoCard(
                                title: 'Por Entregar',
                                value: '${stats.pendingDeliveriesCount}',
                                subtitle: stats.urgentOrdersCount > 0 
                                    ? '${stats.urgentOrdersCount} Urgentes 🚨' 
                                    : 'Pedidos pendientes',
                                icon: Icons.local_shipping_outlined,
                                color: stats.urgentOrdersCount > 0 ? Colors.redAccent : Colors.blueGrey,
                                isDark: stats.urgentOrdersCount > 0, // Make text white if red
                                onTap: () => _navigateTo(1), // Navigate to Orders
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Bottom Sections: Next Deliveries & Top Products
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Next Deliveries
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.dashboardTitles['orders'] ?? 'Próximas Entregas', 
                                  style: Theme.of(context).textTheme.headlineSmall
                                ),
                                const SizedBox(height: 16),
                                if (stats.nextDeliveries.isEmpty)
                                  _buildEmptyState('No hay entregas pendientes')
                                else
                                  ...stats.nextDeliveries.map((order) => Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                                        child: const Icon(Icons.inventory_2_outlined, color: AppTheme.secondaryColor),
                                      ),
                                      title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        'Entrega: ${DateFormat('dd/MM/yyyy').format(order.deliveryDate)}\n${order.items.length} productos',
                                      ),
                                      trailing: Chip(
                                        label: Text(_translateStatus(order.deliveryStatus)),
                                        backgroundColor: Colors.orange.withOpacity(0.1),
                                        labelStyle: const TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                  )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          
                          // Top Products
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.dashboardTitles['metrics'] ?? 'Top Productos (Mes)', 
                                  style: Theme.of(context).textTheme.headlineSmall
                                ),
                                const SizedBox(height: 16),
                                if (stats.topProducts.isEmpty)
                                  _buildEmptyState('No hay ventas este mes')
                                else
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                                      ],
                                    ),
                                    child: Column(
                                      children: stats.topProducts.map((entry) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${entry.value}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                                            ),
                                          ],
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error cargando dashboard: $err', style: const TextStyle(color: Colors.red))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[50]?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!.withOpacity(0.2)),
      ),
      child: Text(message, style: TextStyle(color: Colors.grey[500])),
    );
  }

  String _translateStatus(String status) {
    const statusMap = {
      'pending': 'Pendiente',
      'delivered': 'Entregado',
      'cancelled': 'Cancelado',
      'Pending': 'Pendiente',
      'Delivered': 'Entregado',
      'Cancelled': 'Cancelado',
    };
    return statusMap[status] ?? status;
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

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _BentoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
            decoration: BoxDecoration(
              color: isDark ? color : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      icon,
                      color: isDark ? Colors.white : color,
                      size: 28,
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward,
                        color: isDark ? Colors.white.withOpacity(0.7) : Theme.of(context).iconTheme.color?.withOpacity(0.3),
                        size: 20,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: isDark ? Colors.white : Theme.of(context).textTheme.displaySmall?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 28, // Slightly adjusted for fit
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.9) : Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.7) : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
