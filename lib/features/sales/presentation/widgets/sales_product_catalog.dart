import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/domain/entities/product.dart';
import '../../../inventory/presentation/providers/product_providers.dart';
import '../providers/best_sellers_provider.dart';
import '../providers/cart_provider.dart';
import 'quantity_dialog.dart';

/// Catálogo de productos (columna izquierda de la pantalla de ventas):
/// buscador + filtro por categorías + sección de "Más vendidos" + grid.
class ProductCatalog extends ConsumerStatefulWidget {
  const ProductCatalog({super.key});

  @override
  ConsumerState<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends ConsumerState<ProductCatalog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory; // null = todas las categorías

  static const int _maxBestSellers = 8;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showQuantityDialog(ProductEntity product) async {
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) => QuantitySelectionDialog(product: product),
    );

    if (quantity != null && quantity > 0) {
      ref.read(cartProvider.notifier).addItem(product, quantity: quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListStreamProvider);
    final bestSellerIds = ref.watch(bestSellerProductIdsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Catálogo de Productos', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o categoría...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
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
          const SizedBox(height: 16),
          Expanded(
            child: productsAsync.when(
              data: (products) => _buildContent(products, bestSellerIds),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<ProductEntity> products, List<String> bestSellerIds) {
    // Categorías presentes en los productos.
    final categories = products
        .map((p) => p.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Filtro por búsqueda + categoría.
    final filtered = products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          p.category.toLowerCase().contains(_searchQuery);
      final matchesCategory =
          _selectedCategory == null || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Más vendidos: solo cuando no hay búsqueda ni categoría filtrada.
    final showBestSellers = _searchQuery.isEmpty && _selectedCategory == null;
    final bestSellers = showBestSellers
        ? _resolveBestSellers(products, bestSellerIds)
        : const <ProductEntity>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.isNotEmpty) ...[
          _buildCategoryChips(categories),
          const SizedBox(height: 16),
        ],
        if (bestSellers.isNotEmpty) ...[
          _sectionLabel('⭐ Más vendidos'),
          const SizedBox(height: 8),
          SizedBox(height: 180, child: _buildBestSellerStrip(bestSellers)),
          const SizedBox(height: 16),
          _sectionLabel('Todos los productos'),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty && _selectedCategory == null
                        ? 'No hay productos disponibles'
                        : 'No se encontraron productos',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _ProductItemCard(
                      product: product,
                      onTap: () => _showQuantityDialog(product),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Convierte los IDs más vendidos en productos actuales (respetando el orden
  /// de ventas y descartando los que ya no existen).
  List<ProductEntity> _resolveBestSellers(
      List<ProductEntity> products, List<String> bestSellerIds) {
    final byId = {for (final p in products) p.id: p};
    final result = <ProductEntity>[];
    for (final id in bestSellerIds) {
      final p = byId[id];
      if (p != null) {
        result.add(p);
        if (result.length >= _maxBestSellers) break;
      }
    }
    return result;
  }

  Widget _buildCategoryChips(List<String> categories) {
    final labels = ['Todos', ...categories];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isAll = i == 0;
          final label = labels[i];
          final selected =
              isAll ? _selectedCategory == null : _selectedCategory == label;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(
                () => _selectedCategory = isAll ? null : label),
          );
        },
      ),
    );
  }

  Widget _buildBestSellerStrip(List<ProductEntity> items) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) => SizedBox(
        width: 150,
        child: _ProductItemCard(
          product: items[i],
          onTap: () => _showQuantityDialog(items[i]),
          highlight: true,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }
}

class _ProductItemCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  final bool highlight; // resalta los más vendidos

  const _ProductItemCard({
    required this.product,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: highlight ? Border.all(color: primary.withValues(alpha: 0.5), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shopping_bag_outlined, color: Theme.of(context).colorScheme.secondary, size: 40),
                  ),
                  if (highlight)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.star, color: Colors.amber[600], size: 20),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Notes field (if exists)
            if (product.notes != null && product.notes!.isNotEmpty) ...[
              Text(
                product.notes!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            // Price display: Base price in red + extra cost in gray
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${product.basePrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (product.extraCost > 0) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '+ \$${product.extraCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
