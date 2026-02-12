import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../providers/finance_provider.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Materiales';

  final List<String> _categories = ['Materiales', 'Servicios', 'Renta', 'Sueldos', 'Otros'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final description = _descriptionController.text;
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      final expense = ExpenseModel.create(
        description: description,
        amount: amount,
        category: _category,
      );

      ref.read(expenseRepositoryProvider).addExpense(expense);
      
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Gasto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej. Compra de vinil',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
