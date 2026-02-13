import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../utils/dashboard_constants.dart';
import 'dashboard_widget_wrapper.dart';

class NextDeliveriesWidget extends ConsumerWidget {
  final bool isDragging;
  final VoidCallback? onRemove;
  final VoidCallback? onResize;
  final VoidCallback? onResizeHeight;

  const NextDeliveriesWidget({super.key, this.isDragging = false, this.onRemove, this.onResize, this.onResizeHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DashboardWidgetWrapper(
      title: 'Próximas Entregas',
      isDragging: isDragging,
      onRemove: onRemove,
      onResize: onResize,
      onResizeHeight: onResizeHeight,
      widgetId: DashboardWidgetIds.nextDeliveries,
      child: statsAsync.when(
        data: (stats) {
           if (stats.nextDeliveries.isEmpty) {
             return Center(
               child: Text('Todo entregado 🎉', style: TextStyle(color: Colors.grey[400])),
             );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            itemCount: stats.nextDeliveries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = stats.nextDeliveries[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF383838) : Colors.grey[50], 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDarkMode ? Colors.transparent : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                      child: const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.secondaryColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 13,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                             DateFormat('dd/MM HH:mm').format(order.deliveryDate),
                             style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error')),
      ),
    );
  }
}
