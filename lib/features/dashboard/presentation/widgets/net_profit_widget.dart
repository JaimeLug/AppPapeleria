import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../utils/dashboard_constants.dart';
import 'dashboard_widget_wrapper.dart';

class NetProfitWidget extends ConsumerWidget {
  final bool isDragging;
  final VoidCallback? onRemove;
  final VoidCallback? onResize;
  final VoidCallback? onResizeHeight;

  const NetProfitWidget({super.key, this.isDragging = false, this.onRemove, this.onResize, this.onResizeHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      data: (stats) {
        final profit = stats.netProfit;
        Color color = Colors.grey;
        IconData icon = Icons.trending_flat;
        
        if (profit > 0) {
          color = Colors.green;
          icon = Icons.trending_up;
        } else if (profit < 0) {
          color = Colors.red;
          icon = Icons.trending_down;
        }

        return DashboardWidgetWrapper(
          title: 'Utilidad Neta',
          isDragging: isDragging,
          onRemove: onRemove,
          onResize: onResize,
      onResizeHeight: onResizeHeight,
          backgroundColor: color, // Dynamic Full Color
          widgetId: DashboardWidgetIds.netProfit,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(icon, size: 24, color: Colors.white),
                 const SizedBox(height: 4),
                 Text(
                   '\$${profit.toStringAsFixed(2)}',
                   style: const TextStyle(
                     fontSize: 28,
                     fontWeight: FontWeight.bold,
                     color: Colors.white,
                   ),
                 ),
                 const Text(
                   'Ingresos - Gastos',
                   style: TextStyle(color: Colors.white70, fontSize: 13),
                 ),
              ],
            ),
          ),
        );
      },
      loading: () => DashboardWidgetWrapper(
        title: 'Utilidad Neta',
        child: const Center(child: CircularProgressIndicator()),
        isDragging: isDragging,
      ),
      error: (_, __) => DashboardWidgetWrapper(
        title: 'Utilidad Neta',
        child: const Center(child: Text('Error')),
        isDragging: isDragging,
      ),
    );
  }
}
