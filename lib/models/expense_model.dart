import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String category;

  @HiveField(3)
  double amount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String note;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      note: json['note'],
    );
  }
}

// Expense Categories
class ExpenseCategory {
  static const String electricity = 'Electricity';
  static const String internet = 'Internet';
  static const String grocery = 'Grocery';
  static const String transport = 'Transport';
  static const String other = 'Other';

  static List<String> get all => [
        electricity,
        internet,
        grocery,
        transport,
        other,
      ];

  static String getIcon(String category) {
    switch (category) {
      case electricity:
        return '⚡';
      case internet:
        return '🌐';
      case grocery:
        return '🛒';
      case transport:
        return '🚗';
      case other:
        return '💰';
      default:
        return '💰';
    }
  }

  static Map<String, int> getCategoryColor(String category) {
    switch (category) {
      case electricity:
        return {'color': 0xFFFFD54F}; // Yellow
      case internet:
        return {'color': 0xFF64B5F6}; // Blue
      case grocery:
        return {'color': 0xFF81C784}; // Green
      case transport:
        return {'color': 0xFFFF8A65}; // Orange
      case other:
        return {'color': 0xFFBA68C8}; // Purple
      default:
        return {'color': 0xFF90CAF9}; // Light Blue
    }
  }
}
