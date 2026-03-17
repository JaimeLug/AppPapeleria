import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/inventory_item_model.dart';
import '../providers/inventory_provider.dart';

class InventoryItemDialog extends ConsumerStatefulWidget {
  final InventoryItemModel? item;

  const InventoryItemDialog({super.key, this.item});

  @override
  ConsumerState<InventoryItemDialog> createState() => _InventoryItemDialogState();
}

class _InventoryItemDialogState extends ConsumerState<InventoryItemDialog> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _minStockController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedType = 'Materia Prima';
  final List<String> _itemTypes = ['Materia Prima', 'Producto Terminado', 'Insumo/Empaque'];
  
  String _selectedUnit = 'Piezas';
  final List<String> _units = ['Piezas', 'Metros', 'Paquetes', 'Litros', 'Cajas'];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _skuController.text = widget.item!.sku ?? '';
      _minStockController.text = widget.item!.minimumStock.toString();
      _unitCostController.text = widget.item!.unitCost.toString();
      _selectedType = widget.item!.itemType;
      _selectedUnit = widget.item!.unitOfMeasure;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _minStockController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final item = InventoryItemModel(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      itemType: _selectedType,
      unitOfMeasure: _selectedUnit,
      currentStock: widget.item?.currentStock ?? 0.0,
      minimumStock: double.tryParse(_minStockController.text) ?? 0.0,
      unitCost: double.tryParse(_unitCostController.text) ?? 0.0,
    );

    try {
      if (widget.item == null) {
        await ref.read(inventoryItemsProvider.notifier).addItem(item);
      } else {
        await ref.read(inventoryItemsProvider.notifier).updateItem(item);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.item == null ? 'Ítem creado' : 'Ítem actualizado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.item == null ? 'Nuevo Ítem de Inventario' : 'Editar Ítem',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre (*)', border: OutlineInputBorder()),
                  validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Tipo (*)', border: OutlineInputBorder()),
                        items: _itemTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unidad Medida (*)', border: OutlineInputBorder()),
                        items: _units.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Stock Mínimo', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _unitCostController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Costo Unit. (\$)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU / Clave (Opcional)', border: OutlineInputBorder()),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                    const SizedBox(width: 16),
                    ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
