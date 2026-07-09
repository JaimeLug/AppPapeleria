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
    // Ya con sesión iniciada, subimos en silencio cualquier dato local
    // pendiente. El guard de sesión en syncPendingData evita los intentos sin
    // autenticar (que fallaban por RLS y dejaban datos "colgados"), y así ya
    // no aparece el diálogo recurrente de "datos no sincronizados".
    unawaited(ref.read(syncManagerProvider).syncPendingData());
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}
