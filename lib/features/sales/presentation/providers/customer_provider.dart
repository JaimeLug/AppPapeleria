import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final box = Hive.box<CustomerModel>('customers');
  return CustomerRepositoryImpl(box);
});

final customerListProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  final customers = await repository.getAllCustomers();
  return customers.map((e) => CustomerModel.fromEntity(e)).toList();
});
