import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/brand_config_model.dart';
import '../../../../core/services/sync_manager.dart';

class OfflineFirstBrandRepository {
  final Box<BrandConfigModel> _box;
  final SupabaseClient _supabase;
  final SyncManager? _syncManager;

  OfflineFirstBrandRepository(this._box, this._supabase, {SyncManager? syncManager}) 
    : _syncManager = syncManager;

  BrandConfigModel get getConfig {
    if (_box.isEmpty) {
      return BrandConfigModel(
        appName: 'Papelería Pro',
        primaryColorHex: 0xFFC4571F, // Terracota (rediseño 2026)
        accentColorHex: 0xFF1E7A4D, // Verde
        updatedAt: DateTime.now(),
      );
    }
    return _box.values.first;
  }

  Stream<BrandConfigModel> watchConfig() async* {
    _fetchRemoteAndSync();
    yield getConfig;
    await for (final _ in _box.watch()) {
      yield getConfig;
    }
  }

  Future<void> _fetchRemoteAndSync() async {
    try {
      final response = await _supabase
          .from('brand_settings')
          .select()
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final remoteConfig = BrandConfigModel.fromJson(response);
        final local = _box.isEmpty ? null : _box.values.first;

        if (local == null || remoteConfig.updatedAt.isAfter(local.updatedAt)) {
            if (_box.isEmpty) {
                await _box.add(remoteConfig);
            } else {
                await _box.putAt(0, remoteConfig);
            }
        }
      }
    } catch (e) {
      // Offline fallback
    }
  }

  Future<void> updateConfig(BrandConfigModel config) async {
    config.updatedAt = DateTime.now();
    if (_box.isEmpty) {
        await _box.add(config);
    } else {
        await _box.putAt(0, config);
    }

    try {
        await _supabase.from('brand_settings').upsert({
            'id': 1, // Single row for global settings
            ...config.toJson(),
        });
    } catch (e) {
        _syncManager?.syncPendingData();
    }
  }
}
