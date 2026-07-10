import 'package:flutter/material.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';

/// Diálogo para establecer o cambiar el PIN de acceso a finanzas.
///
/// Cuando ya existe un PIN, [onRemove] permite lanzar el flujo de eliminación.
class PinDialog extends StatefulWidget {
  final SettingsNotifier notifier;
  final String? currentPin;
  final VoidCallback onRemove;

  const PinDialog({
    super.key,
    required this.notifier,
    this.currentPin,
    required this.onRemove,
  });

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  late final TextEditingController controller;
  late final TextEditingController currentController;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    currentController = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    currentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.currentPin != null && widget.currentPin!.isNotEmpty;

    return AlertDialog(
      title: Text(isEditing ? 'Gestionar PIN' : 'Establecer PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing) ...[
            const Text('Acciones disponibles:'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onRemove,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar PIN'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('O cambiar PIN:'),
            const SizedBox(height: 8),
            TextField(
              controller: currentController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN actual',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nuevo PIN (4 dígitos)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (controller.text.length != 4) return;
            // Al cambiar un PIN existente, hay que introducir el PIN actual.
            if (isEditing && currentController.text != widget.currentPin) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN actual incorrecto')),
              );
              return;
            }
            widget.notifier.setSecurityPin(controller.text);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Actualizado')));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Diálogo que pide el PIN actual para eliminarlo.
class RemovePinDialog extends StatefulWidget {
  final SettingsNotifier notifier;

  const RemovePinDialog({super.key, required this.notifier});

  @override
  State<RemovePinDialog> createState() => _RemovePinDialogState();
}

class _RemovePinDialogState extends State<RemovePinDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar PIN'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Ingresa el PIN actual',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            try {
              widget.notifier.removeSecurityPin(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Eliminado')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Incorrecto')));
            }
          },
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}

/// Diálogo de reset de fábrica: pide el PIN de desarrollador y borra todos los datos.
class ResetDialog extends StatefulWidget {
  final SettingsNotifier notifier;

  const ResetDialog({super.key, required this.notifier});

  @override
  State<ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<ResetDialog> {
  late final TextEditingController pinController;

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset de Fábrica', style: TextStyle(color: Colors.red)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Esta acción BORRARÁ TODOS LOS PEDIDOS, CLIENTES Y DATOS. No se puede deshacer.'),
          const SizedBox(height: 16),
          TextField(
            controller: pinController,
            decoration: const InputDecoration(
              labelText: 'PIN de Desarrollador',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            try {
              await widget.notifier.factoryReset(pinController.text);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sistema restablecido de fábrica')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Incorrecto. Acción cancelada.')));
              }
            }
          },
          child: const Text('BORRAR TODO', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
