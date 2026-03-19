import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 4)
class ExpenseModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final bool isSynced;

  @HiveField(6)
  final DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.isSynced = false,
    required this.updatedAt,
  });

  factory ExpenseModel.create({
    required String description,
    required double amount,
    required String category,
    DateTime? date,
  }) {
    return ExpenseModel(
      id: const Uuid().v4(),
      description: description,
      amount: amount,
      date: date ?? DateTime.now(),
      category: category,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      description: json['description'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] is String ? DateTime.parse(json['date']) : DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      category: json['category'] ?? 'Sin Categoría',
      isSynced: true,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : (json['date'] is String ? DateTime.parse(json['date']) : DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toUtc().toIso8601String(),
      'category': category,
      'is_synced': isSynced,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
