import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/services/supabase_credentials_store.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/data/credential_store.dart';
import '../../../settings/domain/models/brand_config_model.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/theme_provider.dart';

/// Asistente de bienvenida que aparece la primera vez que se abre la app.
/// Guía: base de datos (opcional) → iniciar sesión → nombre → logo → colores.
class OnboardingWizard extends ConsumerStatefulWidget {
  /// Si Supabase ya quedó inicializado con credenciales válidas (del .env o
  /// guardadas). Si es false, el paso de base de datos es obligatorio y hay
  /// que reiniciar la app tras guardarlas.
  final bool isSupabaseConfigured;

  const OnboardingWizard({super.key, required this.isSupabaseConfigured});

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

enum _Step { welcome, database, login, name, logo, colors, done }

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  final _steps = _Step.values;
  int _index = 0;

  // Base de datos
  final _dbUrlController = TextEditingController();
  final _dbKeyController = TextEditingController();
  bool _showDbForm = false;
  bool _dbSavedNeedsRestart = false;

  // Login
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;

  // Marca
  final _nameController = TextEditingController();
  String? _logoBase64;
  late Color _primary;
  late Color _accent;

  bool _saving = false;

  static const int _maxLogoBytes = 500 * 1024;

  @override
  void initState() {
    super.initState();
    final config = ref.read(currentBrandConfigProvider);
    _nameController.text = config.appName;
    _logoBase64 = config.logoBase64;
    _primary = Color(config.primaryColorHex);
    _accent = Color(config.accentColorHex);
    _showDbForm = !widget.isSupabaseConfigured;
  }

  @override
  void dispose() {
    _dbUrlController.dispose();
    _dbKeyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  _Step get _current => _steps[_index];

  void _next() {
    if (_index < _steps.length - 1) setState(() => _index++);
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _progressDots(),
                    const SizedBox(height: 24),
                    _buildStep(),
                    const SizedBox(height: 32),
                    _buildNav(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (i) {
        final active = i == _index;
        final done = i < _index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: (active || done)
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildStep() {
    switch (_current) {
      case _Step.welcome:
        return _welcomeStep();
      case _Step.database:
        return _databaseStep();
      case _Step.login:
        return _loginStep();
      case _Step.name:
        return _nameStep();
      case _Step.logo:
        return _logoStep();
      case _Step.colors:
        return _colorsStep();
      case _Step.done:
        return _doneStep();
    }
  }

  // --- Pasos ---

  Widget _welcomeStep() {
    return Column(
      children: [
        Icon(Icons.waving_hand, size: 56, color: Theme.of(context).primaryColor),
        const SizedBox(height: 16),
        Text('¡Bienvenido!',
            style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Vamos a configurar tu aplicación en unos pasos: conexión, tu cuenta, '
          'y la imagen de tu negocio (nombre, logo y colores).',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _databaseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepTitle(Icons.storage_outlined, 'Base de datos'),
        const SizedBox(height: 8),
        if (widget.isSupabaseConfigured && !_showDbForm) ...[
          _infoBox(
            Icons.check_circle,
            Colors.green,
            'Conectada a la base de datos por defecto. No necesitas hacer nada aquí.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showDbForm = true),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Conectar otra base de datos (avanzado)'),
          ),
        ] else ...[
          Text(
            widget.isSupabaseConfigured
                ? 'Ingresa los datos de la otra base de datos de Supabase.'
                : 'Ingresa los datos de tu base de datos de Supabase (Project URL y anon key).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dbUrlController,
            decoration: const InputDecoration(
              labelText: 'Project URL',
              hintText: 'https://xxxxx.supabase.co',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dbKeyController,
            decoration: const InputDecoration(
              labelText: 'anon key',
              hintText: 'eyJhbGciOi...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saveDbCredentials,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar conexión'),
          ),
          if (_dbSavedNeedsRestart) ...[
            const SizedBox(height: 12),
            _infoBox(
              Icons.restart_alt,
              Colors.orange,
              'Conexión guardada. Cierra y vuelve a abrir la app para aplicar la nueva base de datos.',
            ),
          ],
        ],
      ],
    );
  }

  Widget _loginStep() {
    final loginState = ref.watch(loginControllerProvider);
    final session = ref.watch(authStateProvider).value?.session;
    if (session != null) {
      // Ya hay sesión activa (p. ej. quedó de antes): no hace falta volver a entrar.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepTitle(Icons.lock_open_outlined, 'Iniciar sesión'),
          const SizedBox(height: 16),
          _infoBox(
            Icons.check_circle,
            Colors.green,
            'Ya has iniciado sesión${session.user.email != null ? ' como ${session.user.email}' : ''}. Continúa al siguiente paso.',
          ),
        ],
      );
    }
    if (!widget.isSupabaseConfigured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepTitle(Icons.lock_outline, 'Iniciar sesión'),
          const SizedBox(height: 12),
          _infoBox(
            Icons.info_outline,
            Colors.orange,
            'Primero configura la base de datos (paso anterior) y reinicia la app para poder iniciar sesión.',
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepTitle(Icons.lock_outline, 'Iniciar sesión'),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (v) => setState(() => _rememberMe = v ?? false),
            ),
            const Expanded(child: Text('Recordar mis datos en este dispositivo')),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: loginState.isLoading ? null : _submitLogin,
          child: loginState.isLoading
              ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Entrar'),
        ),
      ],
    );
  }

  Widget _nameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepTitle(Icons.badge_outlined, 'Nombre del negocio'),
        const SizedBox(height: 8),
        Text('Aparece en el menú, los tickets y la ventana.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. Papelería La Estrella',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _logoStep() {
    final hasLogo = _logoBase64 != null && _logoBase64!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepTitle(Icons.image_outlined, 'Tu logo'),
        const SizedBox(height: 8),
        Text('Opcional: puedes subirlo ahora o luego en Ajustes.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Center(
          child: Container(
            height: 120, width: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLogo
                ? Image.memory(base64Decode(_logoBase64!), fit: BoxFit.contain)
                : Icon(Icons.image_outlined, size: 48, color: Theme.of(context).dividerColor),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(Icons.upload_outlined),
              label: Text(hasLogo ? 'Cambiar' : 'Subir logo'),
            ),
            if (hasLogo) ...[
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => setState(() => _logoBase64 = null),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text('Quitar', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _colorsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepTitle(Icons.palette_outlined, 'Tus colores'),
        const SizedBox(height: 8),
        Text('Elige el color principal y el de acento. Podrás ajustar toda la '
            'paleta luego en Ajustes › Colores de la App.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            _colorPick('Principal', _primary, (c) => setState(() => _primary = c)),
            const SizedBox(width: 24),
            _colorPick('Acento', _accent, (c) => setState(() => _accent = c)),
          ],
        ),
      ],
    );
  }

  Widget _doneStep() {
    return Column(
      children: [
        Icon(Icons.celebration_outlined, size: 56, color: Theme.of(context).primaryColor),
        const SizedBox(height: 16),
        Text('¡Todo listo!',
            style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Tu aplicación quedó configurada. Podrás cambiar el logo, los colores '
          'y el nombre cuando quieras desde Ajustes.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  // --- Navegación inferior ---

  Widget _buildNav() {
    final isFirst = _index == 0;
    final isLast = _current == _Step.done;
    final loggedIn = ref.watch(authStateProvider).value?.session != null;

    // El paso de login bloquea el avance hasta que haya sesión.
    final canAdvance = _current != _Step.login || loggedIn;

    return Row(
      children: [
        if (!isFirst)
          TextButton(onPressed: _saving ? null : _back, child: const Text('Atrás')),
        const Spacer(),
        if (_canSkip())
          TextButton(
            onPressed: _saving ? null : _next,
            child: const Text('Omitir'),
          ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: (!canAdvance || _saving)
              ? null
              : (isLast ? _finish : _next),
          child: _saving
              ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isLast ? 'Empezar a usar la app' : 'Continuar'),
        ),
      ],
    );
  }

  /// Los pasos de imagen (logo/colores) y la base de datos por defecto se
  /// pueden omitir.
  bool _canSkip() {
    switch (_current) {
      case _Step.database:
        return widget.isSupabaseConfigured;
      case _Step.logo:
      case _Step.colors:
        return true;
      default:
        return false;
    }
  }

  // --- Acciones ---

  Future<void> _saveDbCredentials() async {
    final url = _dbUrlController.text.trim();
    final key = _dbKeyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la URL y la llave anon')),
      );
      return;
    }
    await SupabaseCredentialsStore.save(url, key);
    if (!mounted) return;
    setState(() => _dbSavedNeedsRestart = true);
  }

  Future<void> _submitLogin() async {
    ref.read(loginControllerProvider.notifier).clearError();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa correo y contraseña')),
      );
      return;
    }
    final ok = await ref.read(loginControllerProvider.notifier).signIn(email, password);
    if (!mounted) return;
    if (ok) {
      if (_rememberMe) {
        await CredentialStore.save(email, password);
      } else {
        await CredentialStore.clear();
      }
      if (mounted) _next();
    } else {
      final error = ref.read(loginControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No se pudo iniciar sesión'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    if (bytes.length > _maxLogoBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen es muy grande (máx. 500 KB).'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => _logoBase64 = base64Encode(bytes));
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    // Guarda la marca (preservando los slots que no toca el asistente).
    final current = ref.read(currentBrandConfigProvider);
    final name = _nameController.text.trim().isEmpty
        ? current.appName
        : _nameController.text.trim();
    final newConfig = BrandConfigModel(
      appName: name,
      logoBase64: _logoBase64,
      primaryColorHex: _primary.toARGB32(),
      accentColorHex: _accent.toARGB32(),
      backgroundColorHex: current.backgroundColorHex,
      surfaceColorHex: current.surfaceColorHex,
      sidebarColorHex: current.sidebarColorHex,
      dashReceivableColorHex: current.dashReceivableColorHex,
      dashIncomeColorHex: current.dashIncomeColorHex,
      dashExpenseColorHex: current.dashExpenseColorHex,
      dashNeutralColorHex: current.dashNeutralColorHex,
      dashNegativeColorHex: current.dashNegativeColorHex,
      updatedAt: DateTime.now(),
    );
    await ref.read(brandRepositoryProvider).updateConfig(newConfig);

    // Nombre también en el perfil de negocio (tickets/PDF).
    ref.read(settingsProvider.notifier).updateBusinessInfo(name: name);

    // Marca el onboarding como completado -> el router sale del asistente.
    ref.read(settingsProvider.notifier).completeOnboarding();
  }

  // --- Helpers de UI ---

  Widget _stepTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _infoBox(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _colorPick(String label, Color color, ValueChanged<Color> onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Color temp = color;
              showDialog(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: Text('Color: $label'),
                  content: SingleChildScrollView(
                    child: ColorPicker(pickerColor: color, onColorChanged: (c) => temp = c),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
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
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
