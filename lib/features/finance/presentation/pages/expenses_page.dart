import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/theme/app_theme.dart';
import '../providers/finance_provider.dart';
import '../widgets/finance_summary_card.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/month_selector.dart';
import '../widgets/transaction_list_tile.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch StreamProviders
    final transactionsAsync = ref.watch(unifiedTransactionsProvider);
    final balanceAsync = ref.watch(monthlyBalanceProvider);
    final activeFilter = ref.watch(financeFilterProvider);
    
    return Scaffold(

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'income_fab',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddIncomeDialog(),
              );
            },
            backgroundColor: Colors.green,
            icon: const Icon(Icons.arrow_upward, color: Colors.white),
            label: const Text('Ingreso', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'expense_fab',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddExpenseDialog(),
              );
            },
            backgroundColor: Colors.red,
            icon: const Icon(Icons.arrow_downward, color: Colors.white),
            label: const Text('Gasto', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Finanzas',
                  style: GoogleFonts.quicksand(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                const MonthSelector(),
              ],
            ),
            const SizedBox(height: 32),

            // Summary Cards
            balanceAsync.when(
              data: (balance) => Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        ref.read(financeFilterProvider.notifier).state = 
                          activeFilter == 'income' ? null : 'income';
                      },
                      child: FinanceSummaryCard(
                        title: 'Ingresos',
                        amount: balance['income']!,
                        color: Colors.green.shade600,
                        icon: Icons.trending_up,
                        isSelected: activeFilter == 'income',
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        ref.read(financeFilterProvider.notifier).state = 
                          activeFilter == 'expense' ? null : 'expense';
                      },
                      child: FinanceSummaryCard(
                        title: 'Egresos',
                        amount: balance['expenses']!,
                        color: Colors.red.shade600,
                        icon: Icons.trending_down,
                        isSelected: activeFilter == 'expense',
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: FinanceSummaryCard(
                      title: 'Utilidad',
                      amount: balance['profit']!,
                      color: Colors.blueGrey,
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),

            // Metrics / List Title
            Row(
              children: [
                Text(
                  'Movimientos del Mes',
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                if (activeFilter != null) ...[
                  const SizedBox(width: 12),
                  Chip(
                    label: Text(
                      activeFilter == 'income' ? 'Solo Ingresos' : 'Solo Egresos',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: activeFilter == 'income' ? Colors.green : Colors.red,
                    onDeleted: () {
                      ref.read(financeFilterProvider.notifier).state = null;
                    },
                    deleteIconColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Unified List
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) => transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay movimientos en este mes',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return TransactionListTile(transaction: transaction);
                      },
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error al cargar movimientos: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
