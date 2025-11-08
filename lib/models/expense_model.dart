import 'package:hive/hive.dart';

part 'expense_model.g.dart';

// Transaction Types
enum TransactionType {
  debit, // Expense
  credit, // Income
}

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

  @HiveField(6)
  String? type; // 'debit' or 'credit'

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    String? type,
  }) : type = type ??
            'debit'; // Default to debit (expense) for backward compatibility

  bool get isDebit => (type ?? 'debit') == 'debit';
  bool get isCredit => (type ?? 'debit') == 'credit';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'type': type,
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
      type: json['type'] ??
          'debit', // Default to debit for backward compatibility
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

// Income Categories
class IncomeCategory {
  static const String salary = 'Salary';
  static const String business = 'Business';
  static const String freelance = 'Freelance';
  static const String investment = 'Investment';
  static const String gift = 'Gift';
  static const String other = 'Other';

  static List<String> get all => [
        salary,
        business,
        freelance,
        investment,
        gift,
        other,
      ];

  static String getIcon(String category) {
    switch (category) {
      case salary:
        return '💼';
      case business:
        return '🏢';
      case freelance:
        return '💻';
      case investment:
        return '📈';
      case gift:
        return '🎁';
      case other:
        return '💵';
      default:
        return '💵';
    }
  }

  static Map<String, int> getCategoryColor(String category) {
    switch (category) {
      case salary:
        return {'color': 0xFF66BB6A}; // Green
      case business:
        return {'color': 0xFF42A5F5}; // Blue
      case freelance:
        return {'color': 0xFFAB47BC}; // Purple
      case investment:
        return {'color': 0xFFFFCA28}; // Amber
      case gift:
        return {'color': 0xFFEC407A}; // Pink
      case other:
        return {'color': 0xFF26A69A}; // Teal
      default:
        return {'color': 0xFF26A69A}; // Teal
    }
  }
}
