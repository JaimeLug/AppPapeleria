import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sales/presentation/providers/customer_provider.dart';
import '../../../sales/domain/entities/customer.dart';
import '../../../sales/data/models/customer_model.dart';
import '../providers/settings_provider.dart';
import '../../../../core/services/google_cloud_service.dart';
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
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final isEditing = customer != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();

              if (newName.isNotEmpty) {
                 Navigator.pop(context);
                 
                 final updatedCustomer = CustomerEntity(
                   id: customer?.id ?? const Uuid().v4(),
                   name: newName,
                   phone: newPhone,
                 );

                 await ref.read(customerRepositoryProvider).saveCustomer(updatedCustomer);
                 print('LOG: Cliente guardado - ID: ${updatedCustomer.id}, Nombre: ${updatedCustomer.name}');
                 
                 // Use invalidate instead of refresh to properly update the UI
                 ref.invalidate(customerListProvider);

                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(isEditing ? 'Cliente actualizado' : 'Cliente guardado'))
                   );
                 }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
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
               Navigator.pop(context);
               
               await ref.read(customerRepositoryProvider).deleteCustomer(customer.id);
               print('LOG: Cliente eliminado - ID: ${customer.id}');
               
               ref.invalidate(customerListProvider);

               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente eliminado')));
               }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
