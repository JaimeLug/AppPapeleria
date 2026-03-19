import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../inventory/domain/entities/product.dart';

class QuantitySelectionDialog extends StatefulWidget {
  final ProductEntity product;
  final int initialQuantity;
  final VoidCallback? onDelete;

  const QuantitySelectionDialog({
    super.key,
    required this.product,
    this.initialQuantity = 1,
    this.onDelete,
  });

  @override
  State<QuantitySelectionDialog> createState() => _QuantitySelectionDialogState();
}

class _QuantitySelectionDialogState extends State<QuantitySelectionDialog> {
  late int _quantity;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _controller.text = _quantity.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity < 0) return;
    setState(() {
      _quantity = newQuantity;
      _controller.text = _quantity.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double unitPrice = widget.product.basePrice + widget.product.extraCost;
    final double totalPrice = unitPrice * _quantity;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${unitPrice.toStringAsFixed(2)} / unidad',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuantityButton(
                icon: Icons.remove,
                onPressed: () => _updateQuantity(_quantity - 1),
                color: Colors.redAccent,
              ),
              Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) {
                    final val = int.tryParse(value);
                    if (val != null) {
                      setState(() {
                        _quantity = val;
                      });
                    }
                  },
                ),
              ),
              _QuantityButton(
                icon: Icons.add,
                onPressed: () => _updateQuantity(_quantity + 1),
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Total: \$${totalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton.icon(
            onPressed: () {
              widget.onDelete!();
              Navigator.of(context).pop(0); // Return 0 to indicate removal
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_quantity);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(widget.initialQuantity == 0 ? 'Agregar' : 'Actualizar'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        iconSize: 32,
        splashRadius: 28,
      ),
    );
  }
}