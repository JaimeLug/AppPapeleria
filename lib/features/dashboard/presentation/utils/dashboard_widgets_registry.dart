import 'package:flutter/material.dart';
import 'dashboard_constants.dart';
import '../widgets/income_widget.dart';
import '../widgets/expense_widget.dart';
import '../widgets/net_profit_widget.dart';
import '../widgets/receivable_widget.dart';
import '../widgets/pending_deliveries_widget.dart';
import '../widgets/next_deliveries_widget.dart';
import '../widgets/top_products_widget.dart';
import '../widgets/trend_chart_widget.dart';
import '../widgets/corateca_clock_widget.dart';
import '../widgets/quick_note_widget.dart';

class DashboardWidgetRegistry {
  static final Map<String, Widget Function(BuildContext, bool, VoidCallback?, VoidCallback?, VoidCallback?)> _builders = {};
  static final Map<String, WidgetMetadata> _metadata = {};

  static void register(String id, Widget Function(BuildContext, bool, VoidCallback?, VoidCallback?, VoidCallback?) builder, WidgetMetadata metadata) {
    _builders[id] = builder;
    _metadata[id] = metadata;
  }

  static void initialize() {
    register(
      DashboardWidgetIds.income,
      (context, isDragging, onRemove, onResize, onResizeHeight) => IncomeWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Ingresos Reales',
        icon: Icons.attach_money,
        description: 'Muestra el total cobrado en el mes actual.',
      ),
    );
    
    register(
      DashboardWidgetIds.expenses,
      (context, isDragging, onRemove, onResize, onResizeHeight) => ExpenseWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Gastos del Mes',
        icon: Icons.money_off,
        description: 'Muestra el total de egresos en el mes actual.',
      ),
    );
    
    register(
      DashboardWidgetIds.netProfit,
      (context, isDragging, onRemove, onResize, onResizeHeight) => NetProfitWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Utilidad Neta',
        icon: Icons.trending_up,
        description: 'Ingresos menos gastos. Indica si hay ganancia o pérdida.',
      ),
    );

    register(
      DashboardWidgetIds.accountsReceivable,
      (context, isDragging, onRemove, onResize, onResizeHeight) => ReceivableWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Por Cobrar',
        icon: Icons.account_balance_wallet_outlined,
        description: 'Saldo total pendiente de cobro de todos los clientes.',
      ),
    );

    register(
      DashboardWidgetIds.pendingDeliveries,
      (context, isDragging, onRemove, onResize, onResizeHeight) => PendingDeliveriesWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Conteo Entregas',
        icon: Icons.local_shipping_outlined,
        description: 'Número de pedidos pendientes de entrega.',
      ),
    );

    register(
      DashboardWidgetIds.nextDeliveries,
      (context, isDragging, onRemove, onResize, onResizeHeight) => NextDeliveriesWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Lista Entregas',
        icon: Icons.list_alt,
        description: 'Lista detallada de las próximas entregas.',
      ),
    );

    register(
      DashboardWidgetIds.topProducts,
      (context, isDragging, onRemove, onResize, onResizeHeight) => TopProductsWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Top Productos',
        icon: Icons.bar_chart,
        description: 'Los productos más vendidos este mes.',
      ),
    );

    register(
      DashboardWidgetIds.trendChart,
      (context, isDragging, onRemove, onResize, onResizeHeight) => TrendChartWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Tendencia',
        icon: Icons.show_chart,
        description: 'Gráfico de ingresos de los últimos 7 días.',
      ),
    );

    register(
      DashboardWidgetIds.clock,
      (context, isDragging, onRemove, onResize, onResizeHeight) => CoratecaClockWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Reloj',
        icon: Icons.access_time,
        description: 'La hora y fecha actual con estilo.',
      ),
    );

    register(
      DashboardWidgetIds.quickNote,
      (context, isDragging, onRemove, onResize, onResizeHeight) => QuickNoteWidget(isDragging: isDragging, onRemove: onRemove, onResize: onResize, onResizeHeight: onResizeHeight),
      const WidgetMetadata(
        displayName: 'Notas Rápidas',
        icon: Icons.note_alt_outlined,
        description: 'Un espacio para escribir recordatorios rápidos.',
      ),
    );
  }

  static Widget build(String id, BuildContext context, {bool isDragging = false, VoidCallback? onRemove, VoidCallback? onResize, VoidCallback? onResizeHeight}) {
    // Ensure initialized (lazy init pattern or call in main, but safe here)
    if (_builders.isEmpty) initialize();

    final builder = _builders[id];
    if (builder != null) {
      return builder(context, isDragging, onRemove, onResize, onResizeHeight);
    }
    return Container(
      height: 100,
      width: 100,
      color: Colors.red,
      child: Center(child: Text('Unknown: $id', style: const TextStyle(color: Colors.white, fontSize: 10))),
    );
  }

  static WidgetMetadata? getMetadata(String id) {
    if (_metadata.isEmpty) initialize();
    return _metadata[id];
  }

  static List<String> get availableWidgetIds {
     if (_builders.isEmpty) initialize();
     return _builders.keys.toList();
  }
}

class WidgetMetadata {
  final String displayName;
  final IconData icon;
  final String description;

  const WidgetMetadata({
    required this.displayName,
    required this.icon,
    required this.description,
  });
}
