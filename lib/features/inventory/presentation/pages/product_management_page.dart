import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:app_papeleria/config/theme/app_theme.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';

class ProductManagementPage extends ConsumerStatefulWidget {
  const ProductManagementPage({super.key});

  @override
  ConsumerState<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends ConsumerState<ProductManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productListAsync = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o categoría...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: FloatingActionButton.small(
              heroTag: 'addProduct',
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showProductFormDialog(context, ref),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: productListAsync.when(
          data: (products) {
            final filteredProducts = products.where((product) {
              final name = product.name.toLowerCase();
              final category = product.category.toLowerCase();
              return name.contains(_searchQuery) || category.contains(_searchQuery);
            }).toList();

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64, color: AppTheme.primaryColor.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no hay productos.\n¡Empieza a crear magia!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.bodyColor,
                          ),
                    ),
                  ],
                ),
              );
            }
            
            if (filteredProducts.isEmpty) {
               return Center(child: Text('No se encontraron productos con "$_searchQuery"'));
            }

            return _buildProductGrid(filteredProducts, ref);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductEntity> products, WidgetRef ref) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: 0.85,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          ref: ref,
          onEdit: () => _showProductFormDialog(context, ref, productToEdit: product),
        );
      },
    );
  }

  void _showProductFormDialog(BuildContext context, WidgetRef ref, {ProductEntity? productToEdit}) {
    final isEditing = productToEdit != null;
    final nameController = TextEditingController(text: productToEdit?.name);
    final priceController = TextEditingController(text: productToEdit?.basePrice.toString());
    final extraController = TextEditingController(text: productToEdit?.extraCost.toString());
    final notesController = TextEditingController(text: productToEdit?.notes);
    
    // For Autocomplete
    String selectedCategory = productToEdit?.category ?? '';
    final TextEditingController categoryTextController = TextEditingController(text: selectedCategory);

    // Fetch existing categories from the provider state if possible, or extract from current list
    // A simple way is to read the current list and extract unique categories
    final productList = ref.read(productListProvider).value ?? [];
    final existingCategories = productList.map((p) => p.category).toSet().toList();
    if (existingCategories.isEmpty) existingCategories.add('General');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto', style: Theme.of(context).textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _CustomTextField(controller: nameController, label: 'Nombre'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CustomTextField(
                      controller: priceController,
                      label: 'Precio Base',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CustomTextField(
                      controller: extraController,
                      label: 'Costo Extra',
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Autocomplete for Category
               SizedBox(
                height: 80, // Fixed height to prevent "no size" layout errors
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: selectedCategory),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return existingCategories.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    selectedCategory = selection;
                    categoryTextController.text = selection;
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    textEditingController.text = selectedCategory;
                    textEditingController.addListener(() {
                         selectedCategory = textEditingController.text;
                    });
                    
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: SizedBox(
                          width: 250, // Fixed width for the dropdown
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
               ),
              const SizedBox(height: 16),
               _CustomTextField(
                controller: notesController, 
                label: 'Notas (Opcional)',
                maxLines: 2,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppTheme.bodyColor)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return; // Basic validation
              
              final price = double.tryParse(priceController.text) ?? 0.0;
              final extra = double.tryParse(extraController.text) ?? 0.0;
              final category = selectedCategory.isEmpty ? 'General' : selectedCategory;
              final notes = notesController.text.trim();

              final newProduct = ProductEntity(
                id: isEditing ? productToEdit.id : const Uuid().v4(),
                name: name,
                basePrice: price,
                extraCost: extra,
                category: category,
                notes: notes.isNotEmpty ? notes : null,
              );
              
              if (isEditing) {
                ref.read(productListProvider.notifier).updateProduct(newProduct, ref);
              } else {
                ref.read(productListProvider.notifier).addProduct(newProduct, ref);
              }
              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumber;
  final int maxLines;

  const _CustomTextField({
    required this.controller,
    required this.label,
    this.isNumber = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  final WidgetRef ref;
  final VoidCallback onEdit;

  const _ProductCard({
    required this.product,
    required this.ref,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.notes != null && product.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  product.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              constSpacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${product.basePrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                  ),
                  if (product.extraCost > 0) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '+ \$${product.extraCost.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.primaryColor, size: 20),
                  onPressed: () => ref.read(productListProvider.notifier).deleteProduct(product.id),
                  tooltip: 'Eliminar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class constSpacer extends StatelessWidget {
  const constSpacer({super.key});
  @override
  Widget build(BuildContext context) => const Spacer();
}

