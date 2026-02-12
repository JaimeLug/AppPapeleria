import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/presentation/providers/product_providers.dart';
import '../../../inventory/domain/entities/product.dart';
import '../providers/settings_provider.dart';
import '../../../../core/services/google_cloud_service.dart';
import 'package:uuid/uuid.dart';

class CategoryEditorDialog extends ConsumerStatefulWidget {
  const CategoryEditorDialog({super.key});

  @override
  ConsumerState<CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends ConsumerState<CategoryEditorDialog> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Gestionar Categorías'),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
            onPressed: () => _showRenameDialog(context, '', []),
            tooltip: 'Nueva Categoría',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: productsAsync.when(
          data: (products) {
            final categories = products.map((p) => p.category).toSet().toList()..sort();
            if (categories.isEmpty) {
              return const Center(child: Text('No hay categorías registradas.'));
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showRenameDialog(context, category, products),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(context, category, products),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error: $err'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context, String currentName, List<ProductEntity> allProducts) {
    final controller = TextEditingController(text: currentName);
    final isEditing = currentName.isNotEmpty;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Renombrar Categoría' : 'Nueva Categoría'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nuevo Nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                // Bulk update logic
                final productsToUpdate = allProducts.where((p) => p.category == currentName).toList();
                
                // Show loading or just process (it might be fast enough)
                Navigator.pop(context); // Close rename dialog
                
                final notifier = ref.read(productListProvider.notifier);
                for (var product in productsToUpdate) {
                  final updatedProduct = ProductEntity(
                    id: product.id,
                    name: product.name,
                    basePrice: product.basePrice,
                    extraCost: product.extraCost,
                    category: newName, // Update category
                    notes: product.notes,
                  );
                  await notifier.updateProduct(updatedProduct, ref);
                }
                
                // If initializing a new category, we don't have products to update, 
                // but we might want to sync the "Category" itself if we had a dedicated sheet.
                // For now, products are the primary sync.

                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Categoría renombrada a "$newName"' : 'Categoría "$newName" creada')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String categoryName, List<ProductEntity> allProducts) {
    final affectedProducts = allProducts.where((p) => p.category == categoryName).length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('Esta categoría se usa en $affectedProducts productos.\n\n¿Deseas mover estos productos a "Sin Categoría"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
               Navigator.pop(context); // Close delete dialog
               
                final productsToUpdate = allProducts.where((p) => p.category == categoryName).toList();
                final notifier = ref.read(productListProvider.notifier);
                
                for (var product in productsToUpdate) {
                  final updatedProduct = ProductEntity(
                    id: product.id,
                    name: product.name,
                    basePrice: product.basePrice,
                    extraCost: product.extraCost,
                    category: 'Sin Categoría', // Move to Uncategorized
                    notes: product.notes,
                  );
                  await notifier.updateProduct(updatedProduct, ref);
                }
                
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría eliminada')));
                }
            },
            child: const Text('Eliminar y Mover'),
          ),
        ],
      ),
    );
  }
}
