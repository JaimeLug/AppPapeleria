import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../dashboard/presentation/providers/dashboard_palette_provider.dart';
import '../../domain/entities/financial_transaction.dart';
import '../providers/finance_provider.dart';

class TransactionListTile extends ConsumerWidget {
  final FinancialTransaction transaction;

  const TransactionListTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == 'income';
    final palette = ref.watch(dashboardPaletteProvider);
    final color = isIncome ? palette.income : palette.expense;
    final bgColor = color.withValues(alpha: 0.12);
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    // Format amount absolute for display if we handle sign via color/prefix
    final amountAbs = transaction.amount.abs();
    final formattedAmount = NumberFormat.currency(locale: 'es_MX', symbol: '').format(amountAbs);
    final displaySign = transaction.amount < 0 ? '-' : '+';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          transaction.description,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('dd MMM yyyy').format(transaction.date)} • ${transaction.category}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$displaySign \$$formattedAmount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar movimiento'),
                    content: const Text('¿Estás seguro de que deseas eliminar este movimiento?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (transaction.type == 'income') {
                            ref.read(financeRepositoryProvider).deleteIncome(transaction.id);
                          } else {
                            ref.read(financeRepositoryProvider).deleteExpense(transaction.id);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
