import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/sync_manager.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';

/// Se muestra justo después de iniciar sesión. Si hay datos locales sin
/// sincronizar, ofrece subirlos a la nube o descartarlos antes de entrar.
/// Si no hay nada pendiente, dispara una sincronización silenciosa y pasa
/// directo al [DashboardPage].
class SessionGate extends ConsumerStatefulWidget {
  const SessionGate({super.key});

  @override
  ConsumerState<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<SessionGate> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reconcile());
  }

  Future<void> _reconcile() async {
    if (_handled) return;
    _handled = true;

    final sync = ref.read(syncManagerProvider);
    final pending = sync.countPendingLocalData();

    // Sin datos locales pendientes: subimos por si algo quedó en cola y entramos.
    if (pending == 0) {
      unawaited(sync.syncPendingData());
      return;
    }

    if (!mounted) return;

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Datos locales sin sincronizar'),
        content: Text(
          'Se encontraron $pending registro(s) guardados en este dispositivo '
          'que aún no están en la nube.\n\n'
          '¿Quieres subirlos a la nube o descartarlos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('upload'),
            child: const Text('Subir a la nube'),
          ),
        ],
      ),
    );

    if (choice == 'upload') {
      await sync.syncPendingData();
      _snack('Datos locales subidos a la nube.');
    } else if (choice == 'discard') {
      await sync.discardPendingLocalData();
      _snack('Datos locales descartados.');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}
