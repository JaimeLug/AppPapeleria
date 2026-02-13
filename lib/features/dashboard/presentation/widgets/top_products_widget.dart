import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../utils/dashboard_constants.dart';
import 'dashboard_widget_wrapper.dart';

class TopProductsWidget extends ConsumerWidget {
  final bool isDragging;
  final VoidCallback? onRemove;
  final VoidCallback? onResize;
  final VoidCallback? onResizeHeight;

  const TopProductsWidget({super.key, this.isDragging = false, this.onRemove, this.onResize, this.onResizeHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return DashboardWidgetWrapper(
      title: 'Top Productos',
      isDragging: isDragging,
      onRemove: onRemove,
      onResize: onResize,
      onResizeHeight: onResizeHeight,
      widgetId: DashboardWidgetIds.topProducts,
      child: statsAsync.when(
        data: (stats) {
          if (stats.topProducts.isEmpty) {
             return Center(
               child: Text('Sin ventas este mes', style: TextStyle(color: Colors.grey[400])),
             );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            itemCount: stats.topProducts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = stats.topProducts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                         entry.key, 
                         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                         overflow: TextOverflow.ellipsis,
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
