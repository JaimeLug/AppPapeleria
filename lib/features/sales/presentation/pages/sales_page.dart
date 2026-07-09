import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../inventory/domain/entities/product.dart';
import '../../../inventory/presentation/providers/product_providers.dart';
import '../../data/models/customer_model.dart';
import '../../domain/entities/customer.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../widgets/quantity_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';
import 'package:app_papeleria/features/settings/presentation/providers/theme_provider.dart';

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(

      body: Row(
        children: [
          // Left: Product Catalog (60%)
          Expanded(
            flex: 6,
            child: _ProductCatalog(ref: ref),
          ),
          // Right: Cart Summary (40%)
          Expanded(
            flex: 4,
            child: const _CartSummary(),
          ),
        ],
      ),
    );
  }
}

class _ProductCatalog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _ProductCatalog({required this.ref});

  @override
  ConsumerState<_ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends ConsumerState<_ProductCatalog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
          const SizedBox(height: 24),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                // Filter products by search query
                final filteredProducts = products.where((product) {
                  final name = product.name.toLowerCase();
                  final category = product.category.toLowerCase();
                  return name.contains(_searchQuery) || category.contains(_searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty 
                        ? 'No hay productos disponibles' 
                        : 'No se encontraron productos con "$_searchQuery"',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _ProductItemCard(
                      product: product,
                      onTap: () => _showQuantityDialog(product),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductItemCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;

  const _ProductItemCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
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
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_bag_outlined, color: Theme.of(context).colorScheme.secondary, size: 40),
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
                  '\$${product.basePrice.toStringAsFixed(0)}',
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
                      '+ \$${product.extraCost.toStringAsFixed(0)}',
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

class _CartSummary extends ConsumerStatefulWidget {
  const _CartSummary();

  @override
  ConsumerState<_CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends ConsumerState<_CartSummary> {
  final _customerController = TextEditingController();
  final _advanceController = TextEditingController();
  final _extraConceptController = TextEditingController();
  final _extraAmountController = TextEditingController();
  final _generalNoteController = TextEditingController();

  @override
  void dispose() {
    _customerController.dispose();
    _advanceController.dispose();
    _extraConceptController.dispose();
    _extraAmountController.dispose();
    _generalNoteController.dispose();
    super.dispose();
  }

  void _editCartItem(BuildContext context, var item) async {
    // Reconstruct a temporary ProductEntity for display purposes
    // Note: We might be missing original basePrice/extraCost separation here if not stored in item.
    // Assuming price in item is final unit price.
    final tempProduct = ProductEntity(
        id: item.productId,
        name: item.productName,
        basePrice: item.price, // Using total unit price as base for display
        extraCost: 0,
        category: '',
    );

    final newQuantity = await showDialog<int?>(
      context: context,
      builder: (context) => QuantitySelectionDialog(
        product: tempProduct, 
        initialQuantity: item.quantity,
        onDelete: () {
            // Already handled by existing Delete button, but Dialog also supports it
        },
      ),
    );

    if (newQuantity != null) {
      if (newQuantity == 0) {
        ref.read(cartProvider.notifier).removeItem(item.productId);
      } else {
        ref.read(cartProvider.notifier).updateQuantity(item.productId, newQuantity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Container(
      color: Theme.of(context).cardColor,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Resumen de Venta', style: Theme.of(context).textTheme.headlineSmall),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () {
                         ref.read(cartProvider.notifier).clearCart();
                         _customerController.clear();
                         _advanceController.clear();
                         _extraConceptController.clear();
                         _extraAmountController.clear();
                         _generalNoteController.clear();
                      },
                    ),
                  ],
                ),
                const Divider(height: 32),
                // Customer Autocomplete
                Consumer(
                  builder: (context, ref, child) {
                    final customersAsync = ref.watch(customerListProvider);
                    return customersAsync.when(
                      data: (customers) {
                         return Autocomplete<CustomerModel>(
                          displayStringForOption: (CustomerModel option) => option.name,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<CustomerModel>.empty();
                            }
                            return customers.where((CustomerModel option) {
                              return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (CustomerModel selection) {
                            ref.read(cartProvider.notifier).setCustomerName(selection.name);
                            _customerController.text = selection.name;
                          },
                          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                             if (_customerController.text != textEditingController.text && textEditingController.text.isNotEmpty) {
                                // Sync
                             }
                             
                             return TextField(
                               controller: textEditingController,
                               focusNode: focusNode,
                               decoration: const InputDecoration(
                                 labelText: 'Cliente',
                                 prefixIcon: Icon(Icons.person_outline),
                               ),
                               onChanged: (value) {
                                  ref.read(cartProvider.notifier).setCustomerName(value);
                                  _customerController.text = value; 
                               },
                             );
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) => Text('Error: $err'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Sale Date and Delivery Date Row
                Row(
                   children: [
                     Expanded(
                       child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: cartState.saleDate ?? DateTime.now(),
                            firstDate: DateTime(2025), // Allow past dates
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            ref.read(cartProvider.notifier).setSaleDate(date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha Venta',
                            prefixIcon: Icon(Icons.event_outlined),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            cartState.saleDate != null
                                ? DateFormat('dd/MM/yyyy').format(cartState.saleDate!)
                                : DateFormat('dd/MM/yyyy').format(DateTime.now()),
                          style: const TextStyle(fontSize: 14),
                          ),
                        ),
                                 ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: cartState.deliveryDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            ref.read(cartProvider.notifier).setDeliveryDate(date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha Entrega',
                            prefixIcon: Icon(Icons.local_shipping_outlined),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            cartState.deliveryDate != null
                                ? DateFormat('dd/MM/yyyy').format(cartState.deliveryDate!)
                                : 'Seleccionar',
                             style: const TextStyle(fontSize: 14),
                          ),
                        ),
                                 ),
                     ),
                   ],
                ),
                const SizedBox(height: 8),
                if (cartState.deliveryDate != null)
                   InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: cartState.deliveryDate != null
                                ? TimeOfDay.fromDateTime(cartState.deliveryDate!)
                                : const TimeOfDay(hour: 12, minute: 0),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            ref.read(cartProvider.notifier).setDeliveryTime(time.hour, time.minute);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Hora: ${DateFormat('HH:mm').format(cartState.deliveryDate!)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
          
          // Cart Items List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = cartState.items[index];
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _editCartItem(context, item),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.backgroundColor,
                          child: Text('${item.quantity}', style: const TextStyle(fontSize: 12, color: AppTheme.bodyColor)),
                        ),
                        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('\$${item.price.toStringAsFixed(2)} c/u'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => ref.read(cartProvider.notifier).removeItem(item.productId),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                },
                childCount: cartState.items.length,
              ),
            ),
          ),

          // Footer Section
          SliverPadding(
            padding: const EdgeInsets.all(32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // --- Extra Costs & Notes Section ---
                ExpansionTile(
                  title: const Text('Notas y Extras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  initiallyExpanded: false,
                  shape: const Border(), // Remove default border
                  collapsedShape: const Border(), // Remove default collapsed border
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4, right: 4),
                      child: TextField(
                        controller: _generalNoteController,
                        decoration: const InputDecoration(
                          labelText: 'Nota General del Pedido',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                        minLines: 1,
                        onChanged: (value) => ref.read(cartProvider.notifier).setGeneralNote(value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _extraConceptController,
                            decoration: const InputDecoration(
                              labelText: 'Concepto Extra',
                              hintText: 'Envío, Caja...',
                              isDense: true,
                            ),
                            onChanged: (value) => ref.read(cartProvider.notifier).setExtraConcept(value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _extraAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monto \$',
                              isDense: true,
                            ),
                             onChanged: (value) {
                                final amount = double.tryParse(value) ?? 0.0;
                                ref.read(cartProvider.notifier).setExtraAmount(amount);
                             },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                 const Divider(),

                _buildTotalRow('Subtotal', cartState.subtotal),
                if (cartState.extraAmount > 0)
                   _buildTotalRow('Extras', cartState.extraAmount, isSecondary: true),
                
                _buildTotalRow('Total', cartState.total, isHighlighted: true),

                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('¿Liquidado totalmente?', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: cartState.isFullyPaid,
                  onChanged: (value) {
                    ref.read(cartProvider.notifier).toggleFullPayment(value ?? false);
                    if (value == true) {
                      _advanceController.text = cartState.total.toStringAsFixed(2);
                    } else {
                      _advanceController.clear();
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Theme.of(context).primaryColor,
                ),
                TextField(
                  controller: _advanceController,
                  enabled: !cartState.isFullyPaid,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Anticipo',
                    prefixText: '\$ ',
                  ),
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0.0;
                    ref.read(cartProvider.notifier).setAdvancePayment(amount);
                  },
                ),
                const SizedBox(height: 16),
                _buildTotalRow('Pendiente', cartState.pendingBalance, isHighlighted: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: cartState.isLoading 
                          ? const SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            ) 
                          : const Icon(Icons.print_outlined),
                      label: Text(cartState.isLoading ? 'Procesando...' : 'Confirmar & Imprimir'),
                      onPressed: cartState.isLoading ? null : () async {
                        final customerName = _customerController.text.trim();
                        // Auto-save new customer logic... (kept same)
                        if (customerName.isNotEmpty) {
                           final repository = ref.read(customerRepositoryProvider);
                           final existing = await repository.searchCustomers(customerName);
                           final exactMatch = existing.any((c) => c.name.toLowerCase() == customerName.toLowerCase());
                           
                           if (!exactMatch) {
                             final newCustomer = CustomerEntity(
                               id: const Uuid().v4(),
                               name: customerName,
                               phone: '', 
                             );
                             await repository.saveCustomer(newCustomer);
                             ref.invalidate(customerListProvider);
                           }
                        }

                        // Check result
                        final settings = ref.read(settingsProvider);
                        final logo = ref.read(currentBrandConfigProvider).logoBase64;
                        await ref.read(cartProvider.notifier).confirmSale(settings, logoBase64: logo);
                        if (!context.mounted) return;
                        
                        final newState = ref.read(cartProvider);
                        if (newState.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(newState.errorMessage!), backgroundColor: Colors.red),
                          );
                        } else if (newState.isSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('¡Venta registrada con éxito!'), backgroundColor: Colors.green),
                          );
                          _customerController.clear();
                          _advanceController.clear();
                          _extraAmountController.clear();
                          _extraConceptController.clear();
                          _generalNoteController.clear();
                          // Reset status is important to ready next sale
                           ref.read(cartProvider.notifier).clearCart(); 
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isHighlighted = false, bool isSecondary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 18 : 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted 
                ? Theme.of(context).primaryColor 
                : (isSecondary ? Colors.grey[700] : Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isHighlighted ? 20 : 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted 
                ? Theme.of(context).primaryColor 
                : (isSecondary ? Colors.grey[700] : Theme.of(context).textTheme.titleLarge?.color),
          ),
        ),
      ],
    );
  }
}