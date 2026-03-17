import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/presentation/providers/product_providers.dart';
import '../../../inventory/domain/entities/product.dart';
import '../providers/settings_provider.dart';
import 'package:hive/hive.dart';
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
    showDialog(
      context: context,
      builder: (context) => _RenameCategoryDialogBody(
        currentName: currentName,
        allProducts: allProducts,
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

                // Delete from Cloud
                await ref.read(settingsProvider.notifier).deleteCategory(categoryName);
                
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

class _RenameCategoryDialogBody extends StatefulWidget {
  final String currentName;
  final List<ProductEntity> allProducts;

  const _RenameCategoryDialogBody({
    required this.currentName,
    required this.allProducts,
  });

  @override
  State<_RenameCategoryDialogBody> createState() => _RenameCategoryDialogBodyState();
}

class _RenameCategoryDialogBodyState extends State<_RenameCategoryDialogBody> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renombrar Categoría'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Nuevo Nombre',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            if (controller.text.isNotEmpty && controller.text != widget.currentName) {
              final newName = controller.text;
              
              // Evitar duplicados
              final settings = Hive.box('settings').get('appSettings') as Map<dynamic, dynamic>?;
              final currentCategories = (settings?['productCategories'] as List<dynamic>?)?.cast<String>() ?? [];
              
              if (currentCategories.contains(newName)) {
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Esta categoría ya existe')));
                return;
              }
              
              Navigator.pop(context, newName); // Return new name to caller
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
