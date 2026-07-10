import 'package:flutter/material.dart';
import '../../domain/entities/order.dart';

/// Diálogo para registrar un abono a la deuda de un pedido.
class OrderPaymentDialog extends StatefulWidget {
  final OrderEntity order;
  final void Function(double)? onAddPayment;

  const OrderPaymentDialog({
    super.key,
    required this.order,
    this.onAddPayment,
  });

  @override
  State<OrderPaymentDialog> createState() => _OrderPaymentDialogState();
}

class _OrderPaymentDialogState extends State<OrderPaymentDialog> {
  late final TextEditingController amountController;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Registrar Abono',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cliente: ${widget.order.customerName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deuda Actual:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${widget.order.pendingBalance.toStringAsFixed(2)}',
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Cantidad a Abonar',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: TextButton(
                onPressed: () {
                  amountController.text = widget.order.pendingBalance.toStringAsFixed(2);
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
            if (amount > widget.order.pendingBalance) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('El abono no puede ser mayor a la deuda (\$${widget.order.pendingBalance.toStringAsFixed(2)})'),
                ),
              );
              return;
            }
            Navigator.pop(context);
            if (widget.onAddPayment != null) {
              widget.onAddPayment!(amount);
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
    );
  }
}
