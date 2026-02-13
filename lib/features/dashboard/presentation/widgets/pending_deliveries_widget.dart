import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../utils/dashboard_constants.dart';
import 'dashboard_widget_wrapper.dart';

class PendingDeliveriesWidget extends ConsumerWidget {
  final bool isDragging;
  final VoidCallback? onRemove;
  final VoidCallback? onResize;
  final VoidCallback? onResizeHeight;

  const PendingDeliveriesWidget({super.key, this.isDragging = false, this.onRemove, this.onResize, this.onResizeHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      data: (stats) {
        final hasUrgent = stats.urgentOrdersCount > 0;
        final color = hasUrgent ? Colors.redAccent : Colors.blueGrey;

        return DashboardWidgetWrapper(
          title: 'Por Entregar',
          isDragging: isDragging,
          onRemove: onRemove,
          onResize: onResize,
      onResizeHeight: onResizeHeight,
          backgroundColor: color, // Full Color
          widgetId: DashboardWidgetIds.pendingDeliveries,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_shipping_outlined, size: 24, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  '${stats.pendingDeliveriesCount}',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  hasUrgent ? '${stats.urgentOrdersCount} Urgentes 🚨' : 'Pedidos pendientes',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => DashboardWidgetWrapper(
        title: 'Por Entregar',
        child: const Center(child: CircularProgressIndicator()),
        isDragging: isDragging,
      ),
      error: (_, __) => DashboardWidgetWrapper(
        title: 'Por Entregar',
        child: const Center(child: Text('Error')),
        isDragging: isDragging,
      ),
    );
  }
}
