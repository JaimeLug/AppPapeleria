import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<List<CustomerEntity>> searchCustomers(String query);
  Stream<List<CustomerEntity>> watchCustomers();
  Future<void> saveCustomer(CustomerEntity customer);
  Future<void> deleteCustomer(String id);
  Future<List<CustomerEntity>> getAllCustomers();
}
