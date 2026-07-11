import 'package:flutter/material.dart';

/// Paleta semántica de las tarjetas del dashboard (rediseño 2026, tonos
/// cálidos del mockup). Los colores comunican el TIPO de dato, por eso son
/// fijos y no dependen de la marca blanca.
class DashboardPalette {
  static const Color receivable = Color(0xFFE0961F); // Ocre — por cobrar
  static const Color income = Color(0xFF1E7A4D); // Verde — ingresos/utilidad
  static const Color expense = Color(0xFFC05621); // Naranja quemado — gastos
  static const Color negative = Color(0xFFB3402E); // Rojo ladrillo — pérdida/urgente
  static const Color neutral = Color(0xFF5E7A8C); // Azul pizarra — entregas
}

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
