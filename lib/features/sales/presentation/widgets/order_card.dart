import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/orders_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diseño':
        return Colors.blue;
      case 'Impresión':
        return Colors.orange;
      case 'Armado':
        return Colors.purple;
      case 'Listo para entrega':
        return Colors.teal;
      case 'Terminado':
      case 'Entregado':
        return Colors.green;
      default:
        return AppTheme.secondaryColor;
    }
  }

  void _showOrderDetails(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detalle del Pedido',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Cliente', value: order.customerName),
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Fecha de Entrega',
                value: '${DateFormat('dd/MM/yyyy').format(order.deliveryDate)} a las ${DateFormat('HH:mm').format(order.deliveryDate)}',
              ),
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Total',
                value: '\$${order.totalPrice.toStringAsFixed(2)}',
              ),
              const Divider(height: 24),
              const Text(
                'Productos:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              item.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              final settings = ref.read(settingsProvider);
              PdfService().generateAndPrintReceipt(order, settings);
            },
            icon: const Icon(Icons.print),
            label: const Text('Reimprimir Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showDebtSettlementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.payment, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Liquidar Deuda'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Deseas liquidar el saldo restante de este pedido?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saldo Pendiente:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${order.pendingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (onLiquidateDebt != null) {
                onLiquidateDebt!();
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Confirmar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Registrar Abono',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente: ${order.customerName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Deuda Actual:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${order.pendingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad a Abonar',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: TextButton(
                  onPressed: () {
                    amountController.text = order.pendingBalance.toStringAsFixed(2);
                  },
                  child: const Text(
                    'Liquidar\nTodo',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa una cantidad válida')),
                );
                return;
              }
              if (amount > order.pendingBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('El abono no puede ser mayor a la deuda (\$${order.pendingBalance.toStringAsFixed(2)})'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              if (onAddPayment != null) {
                onAddPayment!(amount);
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Abonar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
        border: Border.all(color: color.withOpacity(0.3)),
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
    final statusColor = _getStatusColor(order.status);

    String statusChipText;
    Color statusChipColor;
    Color statusChipBgColor;
    
    if (isDelivered && !hasDebt) {
      statusChipText = 'TERMINADO';
      statusChipColor = Colors.green;
      statusChipBgColor = Colors.green.withOpacity(0.1);
    } else if (isDelivered && hasDebt) {
      statusChipText = 'PAGO PENDIENTE';
      statusChipColor = Colors.orange;
      statusChipBgColor = Colors.orange.withOpacity(0.1);
    } else {
      statusChipText = 'PENDIENTE DE ENTREGA';
      statusChipColor = Colors.yellow[800]!;
      statusChipBgColor = Colors.yellow[100]!;
    }

    return InkWell(
      onTap: () => _showOrderDetails(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
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
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            'Pendiente',
                            'En Proceso',
                            'Listo para entrega',
                            'Entregado',
                          ].map((status) => ListTile(
                            title: Text(status),
                            onTap: () {
                              onStatusChange(status);
                              Navigator.pop(context);
                            },
                          )).toList(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: statusColor,
                      side: BorderSide(color: statusColor),
                    ),
                    child: Text('Estado: ${order.status}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
