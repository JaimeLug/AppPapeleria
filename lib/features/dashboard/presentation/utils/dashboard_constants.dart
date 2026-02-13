class DashboardWidgetIds {
  static const String income = 'widget_income';
  static const String expenses = 'widget_expenses';
  static const String netProfit = 'widget_net_profit';
  static const String accountsReceivable = 'widget_receivable';
  static const String pendingDeliveries = 'widget_pending_deliveries';
  static const String nextDeliveries = 'widget_next_deliveries';
  static const String topProducts = 'widget_top_products';
  static const String trendChart = 'widget_trend_chart';
  static const String clock = 'widget_clock';
  static const String quickNote = 'widget_quick_note';

  static const List<String> defaultLayout = [
    expenses,
    income,
    netProfit,
    pendingDeliveries,
    accountsReceivable,
    quickNote,
    nextDeliveries,
    topProducts,
  ];
}
