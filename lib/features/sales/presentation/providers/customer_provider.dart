import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/customer_model.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/repositories/offline_first_customer_repository.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/providers/remote_repositories_providers.dart';
import '../../domain/entities/customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final box = Hive.box<CustomerModel>('customers');
  final remoteRepo = ref.watch(remoteCustomerRepositoryProvider);
  final syncManager = ref.watch(syncManagerProvider);
  
  return OfflineFirstCustomerRepository(remoteRepo, box, syncManager);
});

// Stream Provider for reactive UI updates
final customerListStreamProvider = StreamProvider<List<CustomerEntity>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchCustomers();
});

// Legacy FutureProvider
final customerListProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  final customers = await repository.getAllCustomers();
  return customers.map((e) => CustomerModel.fromEntity(e)).toList();
});
