import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';

class SupabaseFinanceRepository {
  final SupabaseClient _supabase;

  SupabaseFinanceRepository(this._supabase);

  // --- Expenses ---

  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('is_deleted', false)
          .order('date', ascending: false);
      
      return response.map((json) => ExpenseModel(
        id: json['id'],
        description: json['description'],
        amount: (json['amount'] ?? 0.0).toDouble(),
        date: DateTime.parse(json['date']),
        category: json['category'] ?? 'Otros',
        isSynced: true,
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at']) 
            : DateTime.parse(json['date']),
      )).toList();
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al obtener gastos: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al obtener gastos: $e');
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _supabase.from('expenses').upsert({
        'id': expense.id,
        'description': expense.description,
        'amount': expense.amount,
        'date': expense.date.toUtc().toIso8601String(),
        'category': expense.category,
        'is_deleted': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al guardar gasto: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al guardar gasto: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _supabase.from('expenses').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al eliminar gasto: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar gasto: $e');
    }
  }

  // --- Incomes ---

  Future<List<IncomeModel>> getIncomes() async {
    try {
      final response = await _supabase
          .from('incomes')
          .select()
          .eq('is_deleted', false)
          .order('date', ascending: false);
      
      return response.map((json) => IncomeModel(
        id: json['id'],
        description: json['description'],
        amount: (json['amount'] ?? 0.0).toDouble(),
        date: DateTime.parse(json['date']),
        category: json['category'] ?? 'General',
        isSynced: true,
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at']) 
            : DateTime.parse(json['date']),
      )).toList();
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al obtener ingresos: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al obtener ingresos: $e');
    }
  }

  Future<void> addIncome(IncomeModel income) async {
    try {
      await _supabase.from('incomes').upsert({
        'id': income.id,
        'description': income.description,
        'amount': income.amount,
        'date': income.date.toUtc().toIso8601String(),
        'category': income.category,
        'is_deleted': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al guardar ingreso: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al guardar ingreso: $e');
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await _supabase.from('incomes').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al eliminar ingreso: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar ingreso: $e');
    }
  }
}
