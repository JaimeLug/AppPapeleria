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

  BrandConfigModel({
    required this.appName,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.updatedAt,
    this.logoBase64,
    this.backgroundColorHex,
    this.surfaceColorHex,
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
    };
  }
}
