import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/brand_config_model.dart';
import '../../data/repositories/offline_first_brand_repository.dart';

final brandBoxProvider = Provider<Box<BrandConfigModel>>((ref) {
  return Hive.box<BrandConfigModel>('brandConfigBox');
});

final brandRepositoryProvider = Provider<OfflineFirstBrandRepository>((ref) {
  return OfflineFirstBrandRepository(
    ref.read(brandBoxProvider),
    Supabase.instance.client,
  );
});

final themeNotifierProvider = StreamProvider<BrandConfigModel>((ref) {
  final repo = ref.watch(brandRepositoryProvider);
  return repo.watchConfig();
});

final currentBrandConfigProvider = Provider<BrandConfigModel>((ref) {
  final configResult = ref.watch(themeNotifierProvider);
  return configResult.value ?? ref.read(brandRepositoryProvider).getConfig;
});
