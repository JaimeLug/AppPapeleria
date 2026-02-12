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

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
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
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
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
