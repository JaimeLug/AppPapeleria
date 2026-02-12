import 'package:hive/hive.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final Box<CustomerModel> _box;

  CustomerRepositoryImpl(this._box);

  @override
  Future<List<CustomerEntity>> getAllCustomers() async {
    return _box.values.toList();
  }

  @override
  Future<void> saveCustomer(CustomerEntity customer) async {
    final model = CustomerModel.fromEntity(customer);
    await _box.put(customer.id, model);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _box.delete(id);
  }

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    final lowerQuery = query.toLowerCase();
    return _box.values
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
