import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'income_model.g.dart';

@HiveType(typeId: 5)
class IncomeModel {
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

  IncomeModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
  });

  factory IncomeModel.create({
    required String description,
    required double amount,
    required String category,
    DateTime? date,
  }) {
    return IncomeModel(
      id: const Uuid().v4(),
      description: description,
      amount: amount,
      date: date ?? DateTime.now(),
      category: category,
    );
  }

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['id'],
      description: json['description'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      category: json['category'] ?? 'Sin Categoría',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
    };
  }
}
