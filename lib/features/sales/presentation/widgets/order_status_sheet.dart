import 'package:flutter/material.dart';
import '../../domain/entities/order.dart';

/// Color asociado a cada estado de pedido.
Color orderStatusColor(String status) {
  switch (status) {
    case 'Pendiente':
      return Colors.redAccent;
    case 'Diseño':
      return Colors.purpleAccent;
    case 'Armando':
      return Colors.orangeAccent;
    case 'Entregado':
    case 'Terminado': // Legacy support
      return Colors.green;
    default:
      return Colors.grey;
  }
}

/// Muestra la hoja inferior para cambiar el estado del pedido.
///
/// Al elegir "Entregado" con saldo pendiente, pregunta si además se liquida
/// la deuda antes de marcar como entregado.
void showOrderStatusSheet(
  BuildContext context, {
  required OrderEntity order,
  required void Function(String) onStatusChange,
  VoidCallback? onMarkDelivered,
  VoidCallback? onLiquidateDebt,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        'Pendiente',
        'Diseño',
        'Armando',
        'Entregado',
      ].map((status) => ListTile(
            title: Text(status),
            leading: Icon(Icons.circle, color: orderStatusColor(status), size: 16),
            onTap: () {
              Navigator.pop(context);
              if (status == 'Entregado') {
                if (order.pendingBalance > 0.01) {
                  // Ask to pay debt
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Entrega con Saldo Pendiente'),
                      content: Text('El pedido tiene un saldo pendiente de \$${order.pendingBalance.toStringAsFixed(2)}.\n\n¿Deseas marcarlo como PAGADO y ENTREGADO?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Mark delivered only (keep debt)
                            if (onMarkDelivered != null) onMarkDelivered();
                          },
                          child: const Text('Solo Entregar (Mantiene Deuda)'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Liquidate debt AND mark delivered
                            if (onLiquidateDebt != null) onLiquidateDebt();
                            if (onMarkDelivered != null) onMarkDelivered();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('Pagado y Entregado'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // No debt, just deliver
                  if (onMarkDelivered != null) onMarkDelivered();
                }
              } else {
                onStatusChange(status);
              }
            },
          )).toList(),
    ),
  );
}
