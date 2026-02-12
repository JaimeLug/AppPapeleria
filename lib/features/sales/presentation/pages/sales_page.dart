import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../inventory/domain/entities/product.dart';
import '../../../inventory/presentation/providers/product_providers.dart';
import '../../data/models/customer_model.dart';
import '../../domain/entities/customer.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);

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
                      onTap: () => ref.read(cartProvider.notifier).addItem(product),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.secondaryColor, size: 40),
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
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
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

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                       // Sync controller
                       if (_customerController.text != textEditingController.text && textEditingController.text.isNotEmpty) {
                          // This avoids loop if we manage it carefully, or just use one controller.
                          // Ideally use textEditingController as the main one for this field.
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
                            _customerController.text = value; // Keep sync for other logic if needed
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
          const SizedBox(height: 16),
          // Sale Date Picker (Retroactive)
          InkWell(
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
                labelText: 'Fecha de Venta',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              child: Text(
                cartState.saleDate != null
                    ? DateFormat('dd/MM/yyyy').format(cartState.saleDate!)
                    : DateFormat('dd/MM/yyyy').format(DateTime.now()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Delivery Date and Time Pickers
          Row(
            children: [
              Expanded(
                flex: 3,
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
                      labelText: 'Fecha de Entrega',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    child: Text(
                      cartState.deliveryDate != null
                          ? DateFormat('dd/MM/yyyy').format(cartState.deliveryDate!)
                          : 'Seleccionar Fecha',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InkWell(
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
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      cartState.deliveryDate != null
                          ? DateFormat('HH:mm').format(cartState.deliveryDate!)
                          : '12:00',
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Display full delivery info
          if (cartState.deliveryDate != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                'Entrega: ${DateFormat('dd/MM/yyyy').format(cartState.deliveryDate!)} a las ${DateFormat('HH:mm').format(cartState.deliveryDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: cartState.items.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final item = cartState.items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
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
                );
              },
            ),
          ),
          const Divider(),
          _buildTotalRow('Subtotal', cartState.subtotal),
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
            activeColor: AppTheme.primaryColor,
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
                  await ref.read(cartProvider.notifier).confirmSale(settings);
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
                    // Reset status is important to ready next sale
                     ref.read(cartProvider.notifier).clearCart(); 
                     // clearCart in notifier now does state = const CartState(), resetting flags.
                     // But we manually set isSuccess=true in confirmSale at the end.
                     // So invoking clearCart *again* here might be redundant but safe to ensure clean slate.
                     // If confirmSale already cleared cart items, here we just clean UI controllers.
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 18 : 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? AppTheme.primaryColor : AppTheme.bodyColor,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isHighlighted ? 20 : 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? AppTheme.primaryColor : AppTheme.titleColor,
          ),
        ),
      ],
    );
  }
}
