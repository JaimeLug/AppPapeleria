import 'package:flutter/material.dart';
import '../../../../core/services/supabase_credentials_store.dart';

/// Pantalla mínima que aparece cuando NO hay credenciales de Supabase (ni
/// guardadas ni en el .env). Solo pide la conexión y guarda; el resto del
/// asistente (login, marca) corre tras reiniciar, ya con Supabase inicializado.
///
/// No usa providers que dependan de Supabase (aún no está inicializado).
class DatabaseSetupScreen extends StatefulWidget {
  const DatabaseSetupScreen({super.key});

  @override
  State<DatabaseSetupScreen> createState() => _DatabaseSetupScreenState();
}

class _DatabaseSetupScreenState extends State<DatabaseSetupScreen> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la URL y la llave anon')),
      );
      return;
    }
    await SupabaseCredentialsStore.save(url, key);
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.storage_outlined, size: 56, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                Text('Conecta tu base de datos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  'Ingresa los datos de tu proyecto de Supabase para empezar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Project URL',
                    hintText: 'https://xxxxx.supabase.co',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'anon key',
                    hintText: 'eyJhbGciOi...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_saved)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conexión guardada. Cierra y vuelve a abrir la app para continuar.',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar y continuar'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
