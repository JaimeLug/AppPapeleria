import 'package:hive/hive.dart';

part 'brand_config_model.g.dart';

@HiveType(typeId: 8)
class BrandConfigModel extends HiveObject {
  @HiveField(0)
  String appName;

  @HiveField(1)
  int primaryColorHex;

  @HiveField(2)
  int accentColorHex;

  @HiveField(3)
  DateTime updatedAt;

  /// Logo del negocio en base64 (sin prefijo data:). Null = usar el logo por
  /// defecto de la app. Se sincroniza junto con el resto de la marca.
  @HiveField(4)
  String? logoBase64;

  /// Color de fondo (scaffold) en modo claro. Null = usar el del tema.
  @HiveField(5)
  int? backgroundColorHex;

  /// Color de las tarjetas/superficies en modo claro. Null = usar el del tema.
  @HiveField(6)
  int? surfaceColorHex;

  /// Color del menú lateral. Null = café oscuro del tema.
  @HiveField(7)
  int? sidebarColorHex;

  // --- Colores de las tarjetas del dashboard (null = paleta por defecto) ---

  /// Tarjeta "Por Cobrar". Null = ocre.
  @HiveField(8)
  int? dashReceivableColorHex;

  /// Tarjetas de ingresos/utilidad positiva. Null = verde.
  @HiveField(9)
  int? dashIncomeColorHex;

  /// Tarjeta "Gastos del Mes". Null = naranja quemado.
  @HiveField(10)
  int? dashExpenseColorHex;

  /// Tarjetas neutras (entregas sin urgencia, utilidad en cero). Null = azul pizarra.
  @HiveField(11)
  int? dashNeutralColorHex;

  /// Estados negativos (pérdida, entregas urgentes). Null = rojo ladrillo.
  @HiveField(12)
  int? dashNegativeColorHex;

  BrandConfigModel({
    required this.appName,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.updatedAt,
    this.logoBase64,
    this.backgroundColorHex,
    this.surfaceColorHex,
    this.sidebarColorHex,
    this.dashReceivableColorHex,
    this.dashIncomeColorHex,
    this.dashExpenseColorHex,
    this.dashNeutralColorHex,
    this.dashNegativeColorHex,
  });

  factory BrandConfigModel.fromJson(Map<String, dynamic> json) {
    return BrandConfigModel(
      appName: json['app_name'] as String,
      primaryColorHex: json['primary_color_hex'] as int,
      accentColorHex: json['accent_color_hex'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      logoBase64: json['logo_base64'] as String?,
      backgroundColorHex: (json['background_color_hex'] as num?)?.toInt(),
      surfaceColorHex: (json['surface_color_hex'] as num?)?.toInt(),
      sidebarColorHex: (json['sidebar_color_hex'] as num?)?.toInt(),
      dashReceivableColorHex: (json['dash_receivable_color_hex'] as num?)?.toInt(),
      dashIncomeColorHex: (json['dash_income_color_hex'] as num?)?.toInt(),
      dashExpenseColorHex: (json['dash_expense_color_hex'] as num?)?.toInt(),
      dashNeutralColorHex: (json['dash_neutral_color_hex'] as num?)?.toInt(),
      dashNegativeColorHex: (json['dash_negative_color_hex'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'primary_color_hex': primaryColorHex,
      'accent_color_hex': accentColorHex,
      'updated_at': updatedAt.toIso8601String(),
      'logo_base64': logoBase64,
      'background_color_hex': backgroundColorHex,
      'surface_color_hex': surfaceColorHex,
      'sidebar_color_hex': sidebarColorHex,
      'dash_receivable_color_hex': dashReceivableColorHex,
      'dash_income_color_hex': dashIncomeColorHex,
      'dash_expense_color_hex': dashExpenseColorHex,
      'dash_neutral_color_hex': dashNeutralColorHex,
      'dash_negative_color_hex': dashNegativeColorHex,
    };
  }
}
