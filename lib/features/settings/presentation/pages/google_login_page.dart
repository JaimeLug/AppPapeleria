import 'package:flutter/material.dart';
import 'package:app_papeleria/config/theme/app_theme.dart';
import 'package:app_papeleria/core/services/google_cloud_service.dart';
import 'package:app_papeleria/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';

class GoogleLoginPage extends ConsumerStatefulWidget {
  const GoogleLoginPage({super.key});

  @override
  ConsumerState<GoogleLoginPage> createState() => _GoogleLoginPageState();
}

class _GoogleLoginPageState extends ConsumerState<GoogleLoginPage> {
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final googleService = GoogleCloudService();
      final success = await googleService.authenticate();
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Error al conectar con Google. Revisa tus credenciales o conexión.')),
           );
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Ocurrió un error inesperado al iniciar sesión: $e')),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _workOffline() {
    // Disable sync locally to allow the user to continue using the app
    final notifier = ref.read(settingsProvider.notifier);
    notifier.updateGoogleConfig(syncSheets: false, syncCalendar: false);
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_sync, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              Text(
                'Sesión Caducada',
                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                 ),
                 textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu sesión de Google ha expirado o no se ha iniciado. Como la sincronización de Nube (Sheets/Calendar) está activa, necesitas iniciar sesión para continuar o elegir "Trabajar Sin Conexión" para desactivar la sincronización.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                 const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _login,
                    icon: const Icon(Icons.login),
                    label: const Text('Iniciar Sesión con Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _workOffline,
                  child: const Text('Trabajar Sin Conexión (Desactiva el Sync Temporamente)', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
