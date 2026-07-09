import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../../domain/models/brand_config_model.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/services/desktop_shortcut.dart';

class BrandSettingsPage extends ConsumerStatefulWidget {
  const BrandSettingsPage({super.key});

  @override
  ConsumerState<BrandSettingsPage> createState() => _BrandSettingsPageState();
}

class _BrandSettingsPageState extends ConsumerState<BrandSettingsPage> {
  // Brand
  late TextEditingController _nameController;
  late Color _primaryColor;
  late Color _accentColor;
  late Color _backgroundColor;
  late Color _surfaceColor;
  String? _logoBase64;

  // Límite del tamaño de imagen para no inflar la base de datos.
  static const int _maxLogoBytes = 500 * 1024; // 500 KB

  // Business Profile
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _footerController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(currentBrandConfigProvider);
    _nameController = TextEditingController(text: config.appName);
    _primaryColor = Color(config.primaryColorHex);
    _accentColor = Color(config.accentColorHex);
    _backgroundColor = config.backgroundColorHex != null
        ? Color(config.backgroundColorHex!)
        : AppTheme.backgroundColor;
    _surfaceColor = config.surfaceColorHex != null
        ? Color(config.surfaceColorHex!)
        : AppTheme.cardColor;
    _logoBase64 = config.logoBase64;

    final settings = ref.read(settingsProvider);
    _phoneController = TextEditingController(text: settings.businessPhone);
    _addressController = TextEditingController(text: settings.businessAddress);
    _footerController = TextEditingController(text: settings.receiptFooterMessage);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil y Marca Blanca')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Identidad Visual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Logo del Negocio', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildLogoSection(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _createShortcut,
              icon: const Icon(Icons.add_to_home_screen),
              label: const Text('Crear acceso directo con mi logo'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Pone en tu escritorio un acceso directo a la app con el ícono de tu logo.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Nombre de la Aplicación', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Ej. Mi Papelería App', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildColorPickerColumn(
                  'Color Primario',
                  _primaryColor,
                  (color) => setState(() => _primaryColor = color),
                ),
                const SizedBox(width: 32),
                _buildColorPickerColumn(
                  'Color de Acento',
                  _accentColor,
                  (color) => setState(() => _accentColor = color),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildColorPickerColumn(
                  'Color de Fondo',
                  _backgroundColor,
                  (color) => setState(() => _backgroundColor = color),
                ),
                const SizedBox(width: 32),
                _buildColorPickerColumn(
                  'Color de Tarjetas',
                  _surfaceColor,
                  (color) => setState(() => _surfaceColor = color),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Fondo y tarjetas aplican al modo claro.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _suggestColorsFromLogo,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Sugerir colores desde el logo'),
            ),
            const SizedBox(height: 48),

            const Text('Perfil de Negocio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(hintText: 'Teléfono del negocio', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(hintText: 'Dirección física', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Mensaje en Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _footerController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: '¡Gracias por su compra!', border: OutlineInputBorder()),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveConfig,
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Configuración General'),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final hasLogo = _logoBase64 != null && _logoBase64!.isNotEmpty;
    return Row(
      children: [
        Container(
          height: 96,
          width: 96,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasLogo
              ? Image.memory(base64Decode(_logoBase64!), fit: BoxFit.contain)
              : const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.upload_outlined),
                label: Text(hasLogo ? 'Cambiar logo' : 'Subir logo'),
              ),
              if (hasLogo)
                TextButton.icon(
                  onPressed: () => setState(() => _logoBase64 = null),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text('Quitar logo', style: TextStyle(color: Colors.redAccent)),
                ),
              const Text(
                'PNG o JPG, máximo 500 KB. Se usará en el menú, tickets y el ícono de la ventana.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    if (bytes.length > _maxLogoBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen es muy grande (máx. 500 KB). Usa una versión más ligera.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _logoBase64 = base64Encode(bytes));
  }

  /// Crea un acceso directo en el escritorio con el logo actual como ícono.
  Future<void> _createShortcut() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Creando acceso directo...'), duration: Duration(seconds: 1)),
    );
    final name = _nameController.text.trim();
    final error = await createBrandDesktopShortcut(
      appName: name.isEmpty ? 'Papelería Pro' : name,
      logoBase64: _logoBase64,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? '¡Acceso directo creado en tu escritorio!'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  /// Extrae los colores dominantes del logo (o del logo por defecto) y ofrece
  /// aplicarlos como primario/acento.
  Future<void> _suggestColorsFromLogo() async {
    final Uint8List bytes;
    if (_logoBase64 != null && _logoBase64!.isNotEmpty) {
      bytes = base64Decode(_logoBase64!);
    } else {
      final data = await rootBundle.load('assets/images/logo.png');
      bytes = data.buffer.asUint8List();
    }

    final palette = await PaletteGenerator.fromImageProvider(
      MemoryImage(bytes),
      maximumColorCount: 16,
    );

    final suggestedPrimary = (palette.vibrantColor ??
            palette.dominantColor ??
            palette.darkVibrantColor)
        ?.color;
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

    final allColors = palette.colors.toList();

    final apply = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Colores de tu logo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Colores encontrados:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allColors
                  .map((c) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text('Sugerencia:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _suggestionSwatch('Primario', suggestedPrimary),
                const SizedBox(width: 16),
                if (suggestedAccent != null)
                  _suggestionSwatch('Acento', suggestedAccent),
              ],
            ),
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

  Widget _buildColorPickerColumn(String title, Color currentColor, ValueChanged<Color> onColorChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Selecciona $title'),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: currentColor,
                      onColorChanged: onColorChanged,
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    
    // Save Brand
    final repo = ref.read(brandRepositoryProvider);
    final newConfig = BrandConfigModel(
      appName: _nameController.text.trim(),
      primaryColorHex: _primaryColor.toARGB32(),
      accentColorHex: _accentColor.toARGB32(),
      updatedAt: DateTime.now(),
      logoBase64: _logoBase64,
      backgroundColorHex: _backgroundColor.toARGB32(),
      surfaceColorHex: _surfaceColor.toARGB32(),
    );
    await repo.updateConfig(newConfig);

    // Save Settings Local Data
    final notifier = ref.read(settingsProvider.notifier);
    notifier.updateBusinessInfo(
       name: _nameController.text.trim(),
       phone: _phoneController.text.trim(),
       address: _addressController.text.trim(),
       footerMessage: _footerController.text.trim()
    );

    setState(() => _isSaving = false);
    if(mounted) {
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada exitosamente', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    }
  }
}
