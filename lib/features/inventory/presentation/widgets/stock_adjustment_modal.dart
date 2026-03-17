import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../data/models/inventory_item_model.dart';
import '../providers/inventory_provider.dart';

class StockAdjustmentModal extends ConsumerStatefulWidget {
  final InventoryItemModel item;

  const StockAdjustmentModal({super.key, required this.item});

  @override
  ConsumerState<StockAdjustmentModal> createState() => _StockAdjustmentModalState();
}

class _StockAdjustmentModalState extends ConsumerState<StockAdjustmentModal> {
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedMovementType = 'Salida'; // Default to Salida as it's common
  final List<String> _movementTypes = ['Entrada', 'Salida', 'Mermas/Dañado'];

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    
    try {
      await ref.read(inventoryItemsProvider.notifier).adjustStock(
        widget.item.id,
        quantity,
        _selectedMovementType,
        _reasonController.text.isEmpty ? 'Ajuste manual' : _reasonController.text,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock actualizado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOutput = _selectedMovementType != 'Entrada';
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ajustar Stock: ${widget.item.name}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Type Selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Entrada', label: Text('Entrada'), icon: Icon(Icons.add_circle_outline)),
                ButtonSegment(value: 'Salida', label: Text('Salida'), icon: Icon(Icons.remove_circle_outline)),
                ButtonSegment(value: 'Mermas/Dañado', label: Text('Merma'), icon: Icon(Icons.warning_amber)),
              ],
              selected: {_selectedMovementType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedMovementType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final num = double.tryParse(value);
                if (num == null || num <= 0) return 'Cantidad inválida';
                
                if (isOutput && num > widget.item.currentStock) {
                   // Warning, not necessarily block, but it makes stock negative.
                   // Assuming we allow negative stock for flexibility, but let's warn.
                   // actually let's block it from making stock negative to avoid confusion.
                   return 'Stock insuficiente (Actual: ${widget.item.currentStock})';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Motivo (Requerido para Salida/Merma)',
                prefixIcon: const Icon(Icons.notes),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (isOutput && (value == null || value.trim().isEmpty)) {
                  return 'Debe proporcionar un motivo para la salida/merma';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isOutput ? Colors.redAccent : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Confirmar ${_selectedMovementType.toUpperCase()}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
