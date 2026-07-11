import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_details_dialog.dart';
import 'order_payment_dialog.dart';
import 'order_status_sheet.dart';

class OrderCard extends ConsumerWidget {
  final OrderEntity order;
  final Function(String) onStatusChange;
  final VoidCallback? onMarkDelivered;
  final VoidCallback? onLiquidateDebt;
  final Function(double)? onAddPayment;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusChange,
    this.onMarkDelivered,
    this.onLiquidateDebt,
    this.onAddPayment,
  });

  void _showOrderDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(order: order),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => OrderPaymentDialog(
        order: order,
        onAddPayment: onAddPayment,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, OrderEntity order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pedido'),
        content: Text('¿Estás seguro de que deseas eliminar el pedido de ${order.customerName}?\n\nEsta acción es irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(ordersProvider.notifier).deleteOrder(order.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pedido eliminado')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDebt = order.pendingBalance > 0.01;
    final isUrgent = order.deliveryDate.difference(DateTime.now()).inDays <= 1 && order.deliveryStatus != 'delivered' && order.status != 'Entregado';
    final isDelivered = order.deliveryStatus == 'delivered' || order.status == 'Entregado';
    final statusColor = orderStatusColor(order.status);

    String statusChipText;
    Color statusChipColor;
    Color statusChipBgColor;

    if (isDelivered && !hasDebt) {
      statusChipText = 'TERMINADO';
      statusChipColor = Colors.green;
      statusChipBgColor = Colors.green.withValues(alpha: 0.1);
    } else if (isDelivered && hasDebt) {
      statusChipText = 'PAGO PENDIENTE';
      statusChipColor = Colors.orange;
      statusChipBgColor = Colors.orange.withValues(alpha: 0.1);
    } else {
      statusChipText = 'PENDIENTE DE ENTREGA';
      statusChipColor = const Color(0xFFB07507); // Ocre oscuro (paleta cálida)
      statusChipBgColor = const Color(0xFFF7E9C8);
    }

    return InkWell(
      onTap: () => _showOrderDetails(context),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'ID: ${order.id.substring(order.id.length > 8 ? order.id.length - 8 : 0)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(statusChipText, statusChipColor, statusChipBgColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: isUrgent ? Colors.red : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Entrega: ${DateFormat('dd/MM/yyyy HH:mm').format(order.deliveryDate)}',
                    style: TextStyle(
                      color: isUrgent ? Colors.red : Colors.grey[700],
                      fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: \$${order.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        'Pendiente: \$${order.pendingBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: hasDebt ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (hasDebt)
                        IconButton(
                          icon: const Icon(Icons.payment, color: Colors.amber),
                          onPressed: () => _showPaymentDialog(context),
                          tooltip: 'Registrar Abono',
                        ),
                      if (!isDelivered && onMarkDelivered != null)
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: onMarkDelivered,
                          tooltip: 'Marcar como Entregado',
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, ref, order),
                        tooltip: 'Eliminar Pedido',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!isDelivered)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => showOrderStatusSheet(
                      context,
                      order: order,
                      onStatusChange: onStatusChange,
                      onMarkDelivered: onMarkDelivered,
                      onLiquidateDebt: onLiquidateDebt,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: statusColor,
                      backgroundColor: statusColor.withValues(alpha: 0.06),
                      side: BorderSide(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: statusColor),
                        const SizedBox(width: 8),
                        Text('Estado: ${order.status}'),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
