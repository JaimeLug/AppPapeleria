import '../../../../features/settings/presentation/providers/settings_provider.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  
  // Backups
  Future<void> exportBackup(AppSettings currentSettings);
  Future<void> importBackup();
  
  // Factory Reset
  Future<void> factoryReset(String pin);
  
  // Stats
  Future<Map<String, int>> getDatabaseStats();

  // Advanced Sync
  Future<void> performAdvancedSync(String mode, AppSettings settings);
}
