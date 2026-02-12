import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinanceSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final Color? textColor;
  final IconData icon;
  final bool isSelected;

  const FinanceSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.textColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: textColor ?? Colors.white, size: 24),
              Text(
                title,
                style: TextStyle(
                  color: (textColor ?? Colors.white).withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formattedAmount,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
