import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/sync_manager.dart';
import 'providers/auth_providers.dart';

/// Pide confirmación, guarda TODO lo local en la nube (guardado completo)
/// y luego cierra sesión. Reutilizable desde cualquier pantalla.
Future<void> confirmSaveAndSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar Sesión'),
      content: const Text(
        'Antes de salir guardaremos todo tu trabajo en la nube. '
        'Tendrás que ingresar tus credenciales nuevamente para acceder.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('CERRAR SESIÓN'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  // Indicador de progreso no descartable mientras se sube todo.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('Guardando tu trabajo en la nube...')),
        ],
      ),
    ),
  );

  try {
    await ref.read(syncManagerProvider).forceSyncAll();
  } catch (_) {
    // Aun si algo falla, permitimos cerrar sesión; lo local queda intacto.
  }

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop(); // cierra el progreso
  await ref.read(loginControllerProvider.notifier).signOut();
}
