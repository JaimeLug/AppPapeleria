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

  BrandConfigModel({
    required this.appName,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.updatedAt,
  });

  factory BrandConfigModel.fromJson(Map<String, dynamic> json) {
    return BrandConfigModel(
      appName: json['app_name'] as String,
      primaryColorHex: json['primary_color_hex'] as int,
      accentColorHex: json['accent_color_hex'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'primary_color_hex': primaryColorHex,
      'accent_color_hex': accentColorHex,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
