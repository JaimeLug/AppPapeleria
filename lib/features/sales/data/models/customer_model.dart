import 'package:hive/hive.dart';
import '../../domain/entities/customer.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 3)
class CustomerModel extends CustomerEntity {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final String phone;
  @HiveField(3)
  final bool isSynced;
  @HiveField(4)
  final DateTime updatedAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.isSynced = false,
    required this.updatedAt,
  }) : super(
          id: id,
          name: name,
          phone: phone,
        );

  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      isSynced: true,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'isSynced': isSynced,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
