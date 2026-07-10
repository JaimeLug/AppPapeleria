import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';
import '../../features/sales/data/repositories/supabase_customer_repository.dart';
import '../../features/inventory/data/repositories/supabase_product_repository.dart';
import '../../features/inventory/domain/repositories/remote_product_repository.dart';
import '../../features/sales/data/repositories/supabase_order_repository.dart';
import '../../features/inventory/data/repositories/supabase_inventory_repository.dart';
import '../../features/finance/data/repositories/supabase_finance_repository.dart';

final remoteCustomerRepositoryProvider = Provider<SupabaseCustomerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseCustomerRepository(client);
});

final remoteProductRepositoryProvider = Provider<RemoteProductRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProductRepository(client);
});

final remoteOrderRepositoryProvider = Provider<SupabaseOrderRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseOrderRepository(client);
});

final remoteInventoryRepositoryProvider = Provider<SupabaseInventoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseInventoryRepository(client);
});

final remoteFinanceRepositoryProvider = Provider<SupabaseFinanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseFinanceRepository(client);
});
