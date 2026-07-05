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

  BrandConfigModel({
    required this.appName,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.updatedAt,
    this.logoBase64,
  });

  factory BrandConfigModel.fromJson(Map<String, dynamic> json) {
    return BrandConfigModel(
      appName: json['app_name'] as String,
      primaryColorHex: json['primary_color_hex'] as int,
      accentColorHex: json['accent_color_hex'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      logoBase64: json['logo_base64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'primary_color_hex': primaryColorHex,
      'accent_color_hex': accentColorHex,
      'updated_at': updatedAt.toIso8601String(),
      'logo_base64': logoBase64,
    };
  }
}
