import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/theme_provider.dart';
import '../utils/dashboard_constants.dart';

/// Paleta efectiva de las tarjetas del dashboard: los colores configurados en
/// la marca (Colores de la App) o, si no se han personalizado, los defaults
/// cálidos de [DashboardPalette].
class BrandDashboardPalette {
  final Color receivable;
  final Color income;
  final Color expense;
  final Color neutral;
  final Color negative;

  const BrandDashboardPalette({
    required this.receivable,
    required this.income,
    required this.expense,
    required this.neutral,
    required this.negative,
  });
}

final dashboardPaletteProvider = Provider<BrandDashboardPalette>((ref) {
  final config = ref.watch(currentBrandConfigProvider);
  Color pick(int? hex, Color fallback) => hex != null ? Color(hex) : fallback;
  return BrandDashboardPalette(
    receivable: pick(config.dashReceivableColorHex, DashboardPalette.receivable),
    income: pick(config.dashIncomeColorHex, DashboardPalette.income),
    expense: pick(config.dashExpenseColorHex, DashboardPalette.expense),
    neutral: pick(config.dashNeutralColorHex, DashboardPalette.neutral),
    negative: pick(config.dashNegativeColorHex, DashboardPalette.negative),
  );
});
