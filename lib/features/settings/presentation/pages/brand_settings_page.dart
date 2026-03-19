import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../../domain/models/brand_config_model.dart';

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
      primaryColorHex: _primaryColor.value,
      accentColorHex: _accentColor.value,
      updatedAt: DateTime.now(),
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
