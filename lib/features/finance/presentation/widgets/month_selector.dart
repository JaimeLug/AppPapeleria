import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../providers/date_provider.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    final isCurrentMonth = selectedDate.year == now.year && selectedDate.month == now.month;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Helper to capitalize first letter
    String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

    final monthYear = DateFormat('MMMM yyyy', 'es_MX').format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              // Subtract one month safely
              final prevMonth = DateTime(selectedDate.year, selectedDate.month - 1);
              ref.read(selectedDateProvider.notifier).state = prevMonth;
            },
            tooltip: 'Mes anterior',
          ),
          const SizedBox(width: 12),
          Text(
            capitalize(monthYear),
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppTheme.titleColor,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.chevron_right, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: isCurrentMonth
                ? null // Disable if current month (future not allowed for now)
                : () {
                    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);
                    ref.read(selectedDateProvider.notifier).state = nextMonth;
                  },
            color: isCurrentMonth ? (isDarkMode ? Colors.grey[700] : Colors.grey[300]) : (isDarkMode ? Colors.white : Colors.black),
            tooltip: 'Mes siguiente',
          ),
        ],
      ),
    );
  }
}
