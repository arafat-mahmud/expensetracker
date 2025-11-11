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
  // Existing categories (kept for backward compatibility)
  static const String electricity = 'Electricity';
  static const String internet = 'Internet';
  static const String grocery = 'Grocery';
  static const String transport = 'Transport';
  static const String other = 'Other';

  // 🏠 Basic Household Expenses
  static const String water = 'Water';
  static const String gas = 'Gas';
  static const String rent = 'Rent / House';
  static const String maintenance = 'Maintenance / Repair';

  // 🍽️ Daily Living
  static const String food = 'Food / Restaurant';
  static const String snacks = 'Snacks';
  static const String laundry = 'Laundry / Cleaning';

  // 🚗 Transportation
  static const String fuel = 'Fuel';
  static const String publicTransport = 'Public Transport';
  static const String parking = 'Parking';
  static const String vehicleMaintenance = 'Vehicle Maintenance';

  // 🏥 Health & Wellness
  static const String medicine = 'Medicine';
  static const String doctor = 'Doctor / Hospital';
  static const String fitness = 'Fitness / Gym';

  // 🎓 Education
  static const String tuition = 'Tuition Fees';
  static const String stationery = 'Stationery';
  static const String onlineCourses = 'Online Courses';

  // 💼 Work & Business
  static const String officeSupplies = 'Office Supplies';
  static const String businessTravel = 'Business Travel';
  static const String clientEntertainment = 'Client Entertainment';

  // 🎉 Entertainment & Lifestyle
  static const String movies = 'Movies / OTT';
  static const String games = 'Games';
  static const String shopping = 'Shopping';
  static const String travel = 'Travel / Vacation';

  // 💳 Financial
  static const String loan = 'Loan / EMI';
  static const String creditCard = 'Credit Card Payment';
  static const String savings = 'Savings / Investment';
  static const String insurance = 'Insurance';

  // 💞 Personal / Family
  static const String gifts = 'Gifts';
  static const String charity = 'Charity';
  static const String petCare = 'Pet Care';
  static const String childExpenses = 'Child Expenses';

  static List<String> get all => [
        // 🏠 Basic Household Expenses
        electricity,
        water,
        internet,
        gas,
        rent,
        maintenance,

        // 🍽️ Daily Living
        grocery,
        food,
        snacks,
        laundry,

        // 🚗 Transportation
        fuel,
        publicTransport,
        parking,
        vehicleMaintenance,
        transport, // Keep original for backward compatibility

        // 🏥 Health & Wellness
        medicine,
        doctor,
        fitness,

        // 🎓 Education
        tuition,
        stationery,
        onlineCourses,

        // 💼 Work & Business
        officeSupplies,
        businessTravel,
        clientEntertainment,

        // 🎉 Entertainment & Lifestyle
        movies,
        games,
        shopping,
        travel,

        // 💳 Financial
        loan,
        creditCard,
        savings,
        insurance,

        // 💞 Personal / Family
        gifts,
        charity,
        petCare,
        childExpenses,

        // Other
        other,
      ];

  static String getIcon(String category) {
    switch (category) {
      // 🏠 Basic Household Expenses
      case electricity:
        return '⚡';
      case water:
        return '💧';
      case internet:
        return '🌐';
      case gas:
        return '🔥';
      case rent:
        return '🏡';
      case maintenance:
        return '🧰';

      // 🍽️ Daily Living
      case grocery:
        return '🛒';
      case food:
        return '🍔';
      case snacks:
        return '☕';
      case laundry:
        return '🧺';

      // 🚗 Transportation
      case fuel:
        return '⛽';
      case publicTransport:
        return '🚌';
      case parking:
        return '🚙';
      case vehicleMaintenance:
        return '🧴';
      case transport:
        return '🚗';

      // 🏥 Health & Wellness
      case medicine:
        return '💊';
      case doctor:
        return '🏥';
      case fitness:
        return '🏋️';

      // 🎓 Education
      case tuition:
        return '📚';
      case stationery:
        return '✏️';
      case onlineCourses:
        return '💻';

      // 💼 Work & Business
      case officeSupplies:
        return '🗂️';
      case businessTravel:
        return '✈️';
      case clientEntertainment:
        return '🤝';

      // 🎉 Entertainment & Lifestyle
      case movies:
        return '📺';
      case games:
        return '🎮';
      case shopping:
        return '👗';
      case travel:
        return '🌴';

      // 💳 Financial
      case loan:
        return '💰';
      case creditCard:
        return '💳';
      case savings:
        return '💵';
      case insurance:
        return '🧾';

      // 💞 Personal / Family
      case gifts:
        return '🎁';
      case charity:
        return '❤️';
      case petCare:
        return '🐶';
      case childExpenses:
        return '👶';

      case other:
        return '💰';
      default:
        return '💰';
    }
  }

  static Map<String, int> getCategoryColor(String category) {
    switch (category) {
      // 🏠 Basic Household Expenses
      case electricity:
        return {'color': 0xFFFFD54F}; // Yellow
      case water:
        return {'color': 0xFF42A5F5}; // Blue
      case internet:
        return {'color': 0xFF64B5F6}; // Light Blue
      case gas:
        return {'color': 0xFFFF7043}; // Deep Orange
      case rent:
        return {'color': 0xFF8D6E63}; // Brown
      case maintenance:
        return {'color': 0xFF78909C}; // Blue Grey

      // 🍽️ Daily Living
      case grocery:
        return {'color': 0xFF81C784}; // Green
      case food:
        return {'color': 0xFFFF8A65}; // Orange
      case snacks:
        return {'color': 0xFFD4E157}; // Lime
      case laundry:
        return {'color': 0xFF9FA8DA}; // Indigo

      // 🚗 Transportation
      case fuel:
        return {'color': 0xFFFF5722}; // Red Orange
      case publicTransport:
        return {'color': 0xFF4CAF50}; // Green
      case parking:
        return {'color': 0xFF607D8B}; // Blue Grey
      case vehicleMaintenance:
        return {'color': 0xFF795548}; // Brown
      case transport:
        return {'color': 0xFFFF8A65}; // Orange (original)

      // 🏥 Health & Wellness
      case medicine:
        return {'color': 0xFFE57373}; // Red
      case doctor:
        return {'color': 0xFF26A69A}; // Teal
      case fitness:
        return {'color': 0xFFAB47BC}; // Purple

      // 🎓 Education
      case tuition:
        return {'color': 0xFF5C6BC0}; // Indigo
      case stationery:
        return {'color': 0xFFFFB74D}; // Orange
      case onlineCourses:
        return {'color': 0xFF42A5F5}; // Blue

      // 💼 Work & Business
      case officeSupplies:
        return {'color': 0xFF66BB6A}; // Green
      case businessTravel:
        return {'color': 0xFFEC407A}; // Pink
      case clientEntertainment:
        return {'color': 0xFF29B6F6}; // Light Blue

      // 🎉 Entertainment & Lifestyle
      case movies:
        return {'color': 0xFF9C27B0}; // Purple
      case games:
        return {'color': 0xFFFF9800}; // Orange
      case shopping:
        return {'color': 0xFFE91E63}; // Pink
      case travel:
        return {'color': 0xFF00BCD4}; // Cyan

      // 💳 Financial
      case loan:
        return {'color': 0xFFF44336}; // Red
      case creditCard:
        return {'color': 0xFF673AB7}; // Deep Purple
      case savings:
        return {'color': 0xFF4CAF50}; // Green
      case insurance:
        return {'color': 0xFF3F51B5}; // Indigo

      // 💞 Personal / Family
      case gifts:
        return {'color': 0xFFE91E63}; // Pink
      case charity:
        return {'color': 0xFFEF5350}; // Red
      case petCare:
        return {'color': 0xFF8BC34A}; // Light Green
      case childExpenses:
        return {'color': 0xFFFFCA28}; // Amber

      case other:
        return {'color': 0xFFBA68C8}; // Purple
      default:
        return {'color': 0xFF90CAF9}; // Light Blue
    }
  }

  // Grouped categories for better organization
  static Map<String, List<String>> get groupedCategories => {
        '🏠 Basic Household Expenses': [
          electricity,
          water,
          internet,
          gas,
          rent,
          maintenance,
        ],
        '🍽️ Daily Living': [
          grocery,
          food,
          snacks,
          laundry,
        ],
        '🚗 Transportation': [
          fuel,
          publicTransport,
          parking,
          vehicleMaintenance,
          transport, // Keep original for backward compatibility
        ],
        '🏥 Health & Wellness': [
          medicine,
          doctor,
          fitness,
        ],
        '🎓 Education': [
          tuition,
          stationery,
          onlineCourses,
        ],
        '💼 Work & Business': [
          officeSupplies,
          businessTravel,
          clientEntertainment,
        ],
        '🎉 Entertainment & Lifestyle': [
          movies,
          games,
          shopping,
          travel,
        ],
        '💳 Financial': [
          loan,
          creditCard,
          savings,
          insurance,
        ],
        '💞 Personal / Family': [
          gifts,
          charity,
          petCare,
          childExpenses,
        ],
        '💰 Other': [
          other,
        ],
      };

  // Get all group headers
  static List<String> get groupHeaders => groupedCategories.keys.toList();

  // Get categories for a specific group
  static List<String> getCategoriesForGroup(String groupHeader) {
    return groupedCategories[groupHeader] ?? [];
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
