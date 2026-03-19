import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sales/presentation/providers/customer_provider.dart';
import '../../../sales/domain/entities/customer.dart';
import '../../../sales/data/models/customer_model.dart';
import 'package:uuid/uuid.dart';

class CustomerManagerDialog extends ConsumerStatefulWidget {
  const CustomerManagerDialog({super.key});

  @override
  ConsumerState<CustomerManagerDialog> createState() => _CustomerManagerDialogState();
}

class _CustomerManagerDialogState extends ConsumerState<CustomerManagerDialog> {
  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Administrar Clientes'),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
            onPressed: () => _showEditDialog(context, null),
            tooltip: 'Nuevo Cliente',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: customersAsync.when(
          data: (customers) {
            if (customers.isEmpty) {
              return const Center(child: Text('No hay clientes registrados.'));
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: customers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  title: Text(customer.name),
                  subtitle: Text(customer.phone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(context, customer),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(context, customer),
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

  void _showEditDialog(BuildContext context, CustomerModel? customer) {
    showDialog(
      context: context,
      builder: (context) => _EditCustomerDialogBody(customer: customer),
    );
  }

  void _showDeleteDialog(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text('¿Estás seguro de eliminar a ${customer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
               try {
                 await ref.read(customerRepositoryProvider).deleteCustomer(customer.id);
                 // debugPrint('LOG: Cliente eliminado - ID: ${customer.id}');
                 
                 ref.invalidate(customerListProvider);

                 if (!context.mounted) return;
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente eliminado')));
               } catch (e) {
                 ref.invalidate(customerListProvider);
                 if (!context.mounted) return;
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                   content: Text(e.toString().replaceAll('Exception: ', '')),
                   backgroundColor: Colors.orange,
                   duration: const Duration(seconds: 4),
                 ));
               }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _EditCustomerDialogBody extends ConsumerStatefulWidget {
  final CustomerModel? customer;

  const _EditCustomerDialogBody({this.customer});

  @override
  ConsumerState<_EditCustomerDialogBody> createState() => _EditCustomerDialogBodyState();
}

class _EditCustomerDialogBodyState extends ConsumerState<_EditCustomerDialogBody> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.customer?.name);
    phoneController = TextEditingController(text: widget.customer?.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nombre Completo'),
          ),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: 'Teléfono (Opcional)'),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              final newCustomer = CustomerEntity(
                id: widget.customer?.id ?? const Uuid().v4(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
              );

              try {
                await ref.read(customerRepositoryProvider).saveCustomer(CustomerModel.fromEntity(newCustomer));
                if (context.mounted) {
                   Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 4),
                  ));
                }
              }
            }
          },
          child: Text(isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
