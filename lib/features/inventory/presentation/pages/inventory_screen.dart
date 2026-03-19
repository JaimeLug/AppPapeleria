import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_item_dialog.dart';
import '../widgets/stock_adjustment_modal.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredItems = ref.watch(filteredInventoryItemsProvider);
    final currentFilter = ref.watch(inventoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario y Materia Prima'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const InventoryItemDialog(),
              );
            },
            tooltip: 'Nuevo Ítem',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context, ref, currentFilter),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'No hay ítems en esta categoría',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildInventoryCard(context, ref, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, String currentFilter) {
    final filters = ['Todos', 'Materia Prima', 'Producto Terminado', 'Insumo/Empaque', '⚠️ Bajo Stock'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == currentFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(inventoryFilterProvider.notifier).state = filter;
                }
              },
              backgroundColor: Colors.white,
              selectedColor: filter == '⚠️ Bajo Stock' ? Colors.redAccent : Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: filter == '⚠️ Bajo Stock' ? Colors.redAccent : Theme.of(context).primaryColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, WidgetRef ref, item) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2, locale: 'es_MX');
    final bool isLowStock = item.currentStock <= item.minimumStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isLowStock ? Colors.redAccent.withValues(alpha: 0.5) : Colors.transparent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.redAccent.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLowStock ? 'Bajo Stock' : 'Stock OK',
                    style: TextStyle(
                      color: isLowStock ? Colors.red : Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tipo: ${item.itemType}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (item.sku != null && item.sku!.isNotEmpty)
                  Text(
                    'SKU: ${item.sku}',
                    style: TextStyle(color: Colors.grey[600]),
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
                    Text('Stock Actual', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(
                      '${item.currentStock} ${item.unitOfMeasure}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isLowStock ? Colors.red : null,
                      ),
                    ),
                    Text('Mínimo: ${item.minimumStock}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Costo Unitario', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(
                      formatter.format(item.unitCost),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => InventoryItemDialog(item: item),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLowStock ? Colors.orange : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.sync_alt, size: 18),
                    label: const Text('Ajustar'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => StockAdjustmentModal(item: item),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Delete button at bottom right (small)
             Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Eliminar', style: TextStyle(color: Colors.red, fontSize: 12)),
                    onPressed: () => _confirmDelete(context, ref, item),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar "${item.name}"? Esta acción se reflejará en el inventario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(inventoryItemsProvider.notifier).deleteItem(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ítem eliminado')));
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}