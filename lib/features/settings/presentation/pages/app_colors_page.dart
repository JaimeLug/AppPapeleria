import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:palette_generator/palette_generator.dart';
import '../providers/theme_provider.dart';
import '../../domain/models/brand_config_model.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../dashboard/presentation/utils/dashboard_constants.dart';

/// Menú dedicado de colores: aquí se configura TODA la paleta de la app
/// (marca global, sincronizada entre dispositivos). Cada slot puede
/// restaurarse a su color por defecto del tema.
class AppColorsPage extends ConsumerStatefulWidget {
  const AppColorsPage({super.key});

  @override
  ConsumerState<AppColorsPage> createState() => _AppColorsPageState();
}

class _AppColorsPageState extends ConsumerState<AppColorsPage> {
  // Generales (primario/acento son obligatorios; el resto null = default)
  late Color _primaryColor;
  late Color _accentColor;
  int? _backgroundHex;
  int? _surfaceHex;
  int? _sidebarHex;

  // Dashboard (null = default de DashboardPalette)
  int? _dashReceivableHex;
  int? _dashIncomeHex;
  int? _dashExpenseHex;
  int? _dashNeutralHex;
  int? _dashNegativeHex;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(currentBrandConfigProvider);
    _primaryColor = Color(config.primaryColorHex);
    _accentColor = Color(config.accentColorHex);
    _backgroundHex = config.backgroundColorHex;
    _surfaceHex = config.surfaceColorHex;
    _sidebarHex = config.sidebarColorHex;
    _dashReceivableHex = config.dashReceivableColorHex;
    _dashIncomeHex = config.dashIncomeColorHex;
    _dashExpenseHex = config.dashExpenseColorHex;
    _dashNeutralHex = config.dashNeutralColorHex;
    _dashNegativeHex = config.dashNegativeColorHex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colores de la App')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Colores Generales'),
            _slotTile(
              label: 'Primario',
              subtitle: 'Botones, ítem activo del menú, acentos',
              color: _primaryColor,
              onChanged: (c) => setState(() => _primaryColor = c),
              onReset: () => setState(() => _primaryColor = AppTheme.defaultPrimary),
            ),
            _slotTile(
              label: 'Acento',
              subtitle: 'Detalles secundarios e íconos',
              color: _accentColor,
              onChanged: (c) => setState(() => _accentColor = c),
              onReset: () => setState(() => _accentColor = AppTheme.defaultSecondary),
            ),
            _slotTile(
              label: 'Fondo (modo claro)',
              color: _backgroundHex != null ? Color(_backgroundHex!) : AppTheme.backgroundColor,
              isCustom: _backgroundHex != null,
              onChanged: (c) => setState(() => _backgroundHex = c.toARGB32()),
              onReset: () => setState(() => _backgroundHex = null),
            ),
            _slotTile(
              label: 'Tarjetas (modo claro)',
              color: _surfaceHex != null ? Color(_surfaceHex!) : AppTheme.cardColor,
              isCustom: _surfaceHex != null,
              onChanged: (c) => setState(() => _surfaceHex = c.toARGB32()),
              onReset: () => setState(() => _surfaceHex = null),
            ),
            _slotTile(
              label: 'Menú lateral',
              color: _sidebarHex != null ? Color(_sidebarHex!) : AppTheme.sidebarColor,
              isCustom: _sidebarHex != null,
              onChanged: (c) => setState(() => _sidebarHex = c.toARGB32()),
              onReset: () => setState(() => _sidebarHex = null),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _suggestColorsFromLogo,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Sugerir primario y acento desde el logo'),
            ),
            const SizedBox(height: 32),

            _sectionTitle('Tarjetas del Dashboard'),
            _slotTile(
              label: 'Por Cobrar',
              color: _dashReceivableHex != null ? Color(_dashReceivableHex!) : DashboardPalette.receivable,
              isCustom: _dashReceivableHex != null,
              onChanged: (c) => setState(() => _dashReceivableHex = c.toARGB32()),
              onReset: () => setState(() => _dashReceivableHex = null),
            ),
            _slotTile(
              label: 'Ingresos y utilidad positiva',
              color: _dashIncomeHex != null ? Color(_dashIncomeHex!) : DashboardPalette.income,
              isCustom: _dashIncomeHex != null,
              onChanged: (c) => setState(() => _dashIncomeHex = c.toARGB32()),
              onReset: () => setState(() => _dashIncomeHex = null),
            ),
            _slotTile(
              label: 'Gastos',
              color: _dashExpenseHex != null ? Color(_dashExpenseHex!) : DashboardPalette.expense,
              isCustom: _dashExpenseHex != null,
              onChanged: (c) => setState(() => _dashExpenseHex = c.toARGB32()),
              onReset: () => setState(() => _dashExpenseHex = null),
            ),
            _slotTile(
              label: 'Entregas / neutro',
              color: _dashNeutralHex != null ? Color(_dashNeutralHex!) : DashboardPalette.neutral,
              isCustom: _dashNeutralHex != null,
              onChanged: (c) => setState(() => _dashNeutralHex = c.toARGB32()),
              onReset: () => setState(() => _dashNeutralHex = null),
            ),
            _slotTile(
              label: 'Urgente / pérdida',
              color: _dashNegativeHex != null ? Color(_dashNegativeHex!) : DashboardPalette.negative,
              isCustom: _dashNegativeHex != null,
              onChanged: (c) => setState(() => _dashNegativeHex = c.toARGB32()),
              onReset: () => setState(() => _dashNegativeHex = null),
            ),
            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: _restoreAllDefaults,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restaurar toda la paleta por defecto'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveColors,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Colores'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
          const Divider(),
        ],
      ),
    );
  }

  /// Fila de un slot de color: nombre, swatch tocable y botón de restaurar.
  Widget _slotTile({
    required String label,
    String? subtitle,
    required Color color,
    required ValueChanged<Color> onChanged,
    required VoidCallback onReset,
    bool isCustom = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (!isCustom)
                  const Text('Por defecto',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          InkWell(
            onTap: () => _pickColor(label, color, onChanged),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 72,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, size: 20),
            tooltip: 'Restaurar por defecto',
            onPressed: onReset,
          ),
        ],
      ),
    );
  }

  void _pickColor(String label, Color current, ValueChanged<Color> onChanged) {
    Color temp = current;
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('Color: $label'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (c) => temp = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              onChanged(temp);
              Navigator.pop(dctx);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _restoreAllDefaults() {
    setState(() {
      _primaryColor = AppTheme.defaultPrimary;
      _accentColor = AppTheme.defaultSecondary;
      _backgroundHex = null;
      _surfaceHex = null;
      _sidebarHex = null;
      _dashReceivableHex = null;
      _dashIncomeHex = null;
      _dashExpenseHex = null;
      _dashNeutralHex = null;
      _dashNegativeHex = null;
    });
  }

  /// Extrae colores dominantes del logo actual y sugiere primario/acento.
  Future<void> _suggestColorsFromLogo() async {
    final config = ref.read(currentBrandConfigProvider);
    final Uint8List bytes;
    if (config.logoBase64 != null && config.logoBase64!.isNotEmpty) {
      bytes = base64Decode(config.logoBase64!);
    } else {
      final data = await rootBundle.load('assets/images/logo.png');
      bytes = data.buffer.asUint8List();
    }

    final palette = await PaletteGenerator.fromImageProvider(
      MemoryImage(bytes),
      maximumColorCount: 16,
    );

    final suggestedPrimary =
        (palette.vibrantColor ?? palette.dominantColor ?? palette.darkVibrantColor)?.color;
    final suggestedAccent = (palette.lightVibrantColor ??
            palette.mutedColor ??
            palette.darkMutedColor ??
            palette.dominantColor)
        ?.color;

    if (!mounted) return;
    if (suggestedPrimary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron extraer colores del logo.')),
      );
      return;
    }

    final apply = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Colores de tu logo'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _suggestionSwatch('Primario', suggestedPrimary),
            const SizedBox(width: 16),
            if (suggestedAccent != null) _suggestionSwatch('Acento', suggestedAccent),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('USAR ESTOS'),
          ),
        ],
      ),
    );

    if (apply == true) {
      setState(() {
        _primaryColor = suggestedPrimary;
        if (suggestedAccent != null) _accentColor = suggestedAccent;
      });
    }
  }

  Widget _suggestionSwatch(String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          width: 56,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
        ),
      ],
    );
  }

  Future<void> _saveColors() async {
    setState(() => _isSaving = true);

    // Conserva identidad (nombre/logo) y solo cambia los colores.
    final current = ref.read(currentBrandConfigProvider);
    final repo = ref.read(brandRepositoryProvider);
    final newConfig = BrandConfigModel(
      appName: current.appName,
      logoBase64: current.logoBase64,
      primaryColorHex: _primaryColor.toARGB32(),
      accentColorHex: _accentColor.toARGB32(),
      backgroundColorHex: _backgroundHex,
      surfaceColorHex: _surfaceHex,
      sidebarColorHex: _sidebarHex,
      dashReceivableColorHex: _dashReceivableHex,
      dashIncomeColorHex: _dashIncomeHex,
      dashExpenseColorHex: _dashExpenseHex,
      dashNeutralColorHex: _dashNeutralHex,
      dashNegativeColorHex: _dashNegativeHex,
      updatedAt: DateTime.now(),
    );
    await repo.updateConfig(newConfig);

    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colores guardados', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
