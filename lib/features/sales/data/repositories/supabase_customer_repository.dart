import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../../../core/error/exceptions.dart';
import '../models/customer_model.dart';

class SupabaseCustomerRepository implements CustomerRepository {
  final SupabaseClient _supabase;

  SupabaseCustomerRepository(this._supabase);

  @override
  Future<List<CustomerEntity>> getAllCustomers() async {
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('is_deleted', false);
      
      return response.map((json) => CustomerModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al obtener clientes: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al obtener clientes: $e');
    }
  }

  @override
  Stream<List<CustomerEntity>> watchCustomers() {
    return _supabase
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('is_deleted', false)
        .map((data) => data.map((json) => CustomerModel.fromJson(json)).toList());
  }

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('is_deleted', false)
          .ilike('name', '%$query%');
      
      return response.map((json) => CustomerModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al buscar clientes: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al buscar clientes: $e');
    }
  }

  @override
  Future<void> saveCustomer(CustomerEntity customer) async {
    try {
      final data = {
        'id': customer.id,
        'name': customer.name,
        'phone': customer.phone,
        'is_deleted': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      
      await _supabase.from('customers').upsert(data);
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al guardar cliente: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al guardar cliente: $e');
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      await _supabase.from('customers').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException('Error de BD al eliminar cliente: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar cliente: $e');
    }
  }
}
