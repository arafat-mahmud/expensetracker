import 'package:hive/hive.dart';

part 'deposit_model.g.dart';

// Transaction Types for Deposit
enum DepositTransactionType {
  deposit, // Adding money to savings
  withdraw, // Withdrawing from savings
}

@HiveType(typeId: 1)
class DepositProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  DateTime deadline;

  @HiveField(4)
  DateTime createdDate;

  @HiveField(5)
  String note;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime? completedDate;

  DepositProfile({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.deadline,
    required this.createdDate,
    this.note = '',
    this.isCompleted = false,
    this.completedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'deadline': deadline.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
      'note': note,
      'isCompleted': isCompleted,
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory DepositProfile.fromJson(Map<String, dynamic> json) {
    return DepositProfile(
      id: json['id'],
      name: json['name'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      deadline: DateTime.parse(json['deadline']),
      createdDate: DateTime.parse(json['createdDate']),
      note: json['note'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'])
          : null,
    );
  }

  // Copy with method for updates
  DepositProfile copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? deadline,
    DateTime? createdDate,
    String? note,
    bool? isCompleted,
    DateTime? completedDate,
  }) {
    return DepositProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      deadline: deadline ?? this.deadline,
      createdDate: createdDate ?? this.createdDate,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
    );
  }
}

@HiveType(typeId: 2)
class DepositTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String profileId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String type; // 'deposit' or 'withdraw'

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String note;

  DepositTransaction({
    required this.id,
    required this.profileId,
    required this.amount,
    required this.type,
    required this.date,
    this.note = '',
  });

  bool get isDeposit => type == 'deposit';
  bool get isWithdraw => type == 'withdraw';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory DepositTransaction.fromJson(Map<String, dynamic> json) {
    return DepositTransaction(
      id: json['id'],
      profileId: json['profileId'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] ?? 'deposit',
      date: DateTime.parse(json['date']),
      note: json['note'] ?? '',
    );
  }

  // Icon and color helpers
  static String getIcon(String type) {
    return type == 'deposit' ? '💰' : '💸';
  }

  static int getColor(String type) {
    return type == 'deposit' ? 0xFF4CAF50 : 0xFFF44336; // Green or Red
  }
}
