import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../utils/dashboard_constants.dart';
import 'dashboard_widget_wrapper.dart';

class IncomeWidget extends ConsumerWidget {
  final bool isDragging;
  final VoidCallback? onRemove;
  final VoidCallback? onResize;
  final VoidCallback? onResizeHeight;
  
  const IncomeWidget({super.key, this.isDragging = false, this.onRemove, this.onResize, this.onResizeHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return DashboardWidgetWrapper(
      title: 'Ingresos Reales',
      isDragging: isDragging,
      onRemove: onRemove,
      onResize: onResize,
      onResizeHeight: onResizeHeight,
      backgroundColor: Colors.green, // Full Color
      widgetId: DashboardWidgetIds.income,
      child: statsAsync.when(
        data: (stats) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.attach_money, size: 24, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                '\$${stats.totalIncome.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Cobrado este mes',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (_, __) => const Center(child: Text('Error', style: TextStyle(color: Colors.white))),
      ),
    );
  }
}
