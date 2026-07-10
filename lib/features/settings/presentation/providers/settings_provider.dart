import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../features/dashboard/domain/models/dashboard_widget_config.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../data/repositories/hive_settings_repository.dart';

// --- State Model ---
class AppSettings {
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessSocials;
  final String receiptFooterMessage;
  final bool isDarkMode;
  final int urgentOrderThresholdDays;
  final String? securityPin;
  
  // Dashboard Personalization
  final String dashboardWelcomeTitle;
  final String dashboardWelcomeSubtitle;
  
  final List<String> productCategories;
  
  // Phase 19.2: Changed from List<String> to List<DashboardWidgetConfig>
  final List<DashboardWidgetConfig>? dashboardLayout;
  
  final String quickNoteContent;

  const AppSettings({
    this.businessName = 'Papelería Pro',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessSocials = '',
    this.receiptFooterMessage = '¡Gracias por tu compra!',
    this.isDarkMode = false,
    this.urgentOrderThresholdDays = 3,
    this.securityPin,
    this.dashboardWelcomeTitle = '¡Hola, crea magia hoy! ✨',
    this.dashboardWelcomeSubtitle = 'Resumen de tu papelería creativa',
    this.productCategories = const [],
    this.dashboardLayout,
    this.quickNoteContent = '',
  });

  AppSettings copyWith({
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessSocials,
    String? receiptFooterMessage,
    bool? isDarkMode,
    int? urgentOrderThresholdDays,
    String? securityPin,
    String? dashboardWelcomeTitle,
    String? dashboardWelcomeSubtitle,
    List<String>? productCategories,
    List<DashboardWidgetConfig>? dashboardLayout,
    String? quickNoteContent,
  }) {
    return AppSettings(
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessSocials: businessSocials ?? this.businessSocials,
      receiptFooterMessage: receiptFooterMessage ?? this.receiptFooterMessage,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      urgentOrderThresholdDays: urgentOrderThresholdDays ?? this.urgentOrderThresholdDays,
      securityPin: securityPin ?? this.securityPin,
      dashboardWelcomeTitle: dashboardWelcomeTitle ?? this.dashboardWelcomeTitle,
      dashboardWelcomeSubtitle: dashboardWelcomeSubtitle ?? this.dashboardWelcomeSubtitle,
      productCategories: productCategories ?? this.productCategories,
      dashboardLayout: dashboardLayout ?? this.dashboardLayout,
      quickNoteContent: quickNoteContent ?? this.quickNoteContent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessSocials': businessSocials,
      'receiptFooterMessage': receiptFooterMessage,
      'isDarkMode': isDarkMode,
      'urgentOrderThresholdDays': urgentOrderThresholdDays,
      'securityPin': securityPin,
      'dashboardWelcomeTitle': dashboardWelcomeTitle,
      'dashboardWelcomeSubtitle': dashboardWelcomeSubtitle,
      'productCategories': productCategories,
      'dashboardLayout': dashboardLayout?.map((e) => e.toMap()).toList(),
      'quickNoteContent': quickNoteContent,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    // Migration Logic
    List<DashboardWidgetConfig>? layout;
    if (map['dashboardLayout'] != null) {
      final rawLayout = map['dashboardLayout'] as List;
      if (rawLayout.isNotEmpty) {
        if (rawLayout.first is String) {
          // Migration: Convert List<String> to List<DashboardWidgetConfig>
          layout = rawLayout.map((id) => DashboardWidgetConfig(id: id as String)).toList();
        } else {
          // Standard: List<Map>
          layout = rawLayout.map((e) => DashboardWidgetConfig.fromMap(Map<String, dynamic>.from(e))).toList();
        }
      } else {
        layout = [];
      }
    }

    return AppSettings(
      businessName: map['businessName'] ?? 'Papelería Pro',
      businessAddress: map['businessAddress'] ?? '',
      businessPhone: map['businessPhone'] ?? '',
      businessSocials: map['businessSocials'] ?? '',
      receiptFooterMessage: map['receiptFooterMessage'] ?? '¡Gracias por tu compra!',
      isDarkMode: map['isDarkMode'] ?? false,
      urgentOrderThresholdDays: map['urgentOrderThresholdDays'] ?? 3,
      securityPin: map['securityPin'],
      dashboardWelcomeTitle: map['dashboardWelcomeTitle'] ?? '¡Hola, crea magia hoy! ✨',
      dashboardWelcomeSubtitle: map['dashboardWelcomeSubtitle'] ?? 'Resumen de tu papelería creativa',
      productCategories: map['productCategories'] != null ? List<String>.from(map['productCategories']) : const [],
      dashboardLayout: layout,
      quickNoteContent: map['quickNoteContent'] ?? '',
    );
  }
}

// --- Notifier ---

// --- Notifier ---
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = await _repository.getSettings();
  }

  Future<void> _saveSettings() async {
    await _repository.saveSettings(state);
  }

  // Actions
  void updateBusinessInfo({
    String? name,
    String? address,
    String? phone,
    String? socials,
    String? footerMessage,
  }) {
    state = state.copyWith(
      businessName: name,
      businessAddress: address,
      businessPhone: phone,
      businessSocials: socials,
      receiptFooterMessage: footerMessage,
    );
    _saveSettings();
  }

  void toggleTheme(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
    _saveSettings();
  }

  void setUrgentThreshold(int days) {
    state = state.copyWith(urgentOrderThresholdDays: days);
    _saveSettings();
  }

  void setSecurityPin(String? pin) {
    state = state.copyWith(securityPin: pin);
    _saveSettings();
  }
  
  void removeSecurityPin(String currentPin) {
    if (state.securityPin == currentPin) {
      state = state.copyWith(securityPin: null);
      _saveSettings();
    } else {
      throw Exception('PIN incorrecto');
    }
  }

  void updateDashboardWelcome({String? title, String? subtitle}) {
    state = state.copyWith(
      dashboardWelcomeTitle: title,
      dashboardWelcomeSubtitle: subtitle,
    );
    _saveSettings();
  }

  void updateDashboardLayout(List<DashboardWidgetConfig> layout) {
    state = state.copyWith(dashboardLayout: layout);
    _saveSettings();
  }

  void updateQuickNote(String content) {
    state = state.copyWith(quickNoteContent: content);
    _saveSettings();
  }

  Future<void> deleteCategory(String categoryName) async {
    final updatedCategories = List<String>.from(state.productCategories)
      ..remove(categoryName);
    state = state.copyWith(productCategories: updatedCategories);
    await _saveSettings();
  }

  Future<void> exportBackup() async {
    await _repository.exportBackup(state);
  }
  
  Future<void> importBackup() async {
    await _repository.importBackup();
    await _loadSettings();
  }

  Future<void> factoryReset(String pin) async {
    await _repository.factoryReset(pin);
    state = const AppSettings();
  }
}

// --- Providers ---

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final box = Hive.box('settings');
  return HiveSettingsRepository(box);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});

final databaseStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getDatabaseStats();
});

