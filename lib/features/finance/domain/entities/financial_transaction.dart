class FinancialTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String type; // 'income', 'expense', 'sale'
  final String category;

  FinancialTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });
}
