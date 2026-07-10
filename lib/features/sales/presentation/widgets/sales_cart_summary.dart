import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../inventory/domain/entities/product.dart';
import '../../data/models/customer_model.dart';
import '../../domain/entities/customer.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import 'quantity_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';
import 'package:app_papeleria/features/settings/presentation/providers/theme_provider.dart';

/// Resumen de venta (columna derecha de la pantalla de ventas): cliente,
/// fechas, renglones del carrito, extras, anticipo y confirmación de venta.
class CartSummary extends ConsumerStatefulWidget {
  const CartSummary({super.key});

  @override
  ConsumerState<CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends ConsumerState<CartSummary> {
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
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
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.print_outlined),
                    label: Text(cartState.isLoading ? 'Procesando...' : 'Confirmar & Imprimir'),
                    onPressed: cartState.isLoading
                        ? null
                        : () async {
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
