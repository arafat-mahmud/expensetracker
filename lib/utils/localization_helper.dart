import '../l10n/app_localizations.dart';

class LocalizationHelper {
  /// Convert numbers to localized format (e.g., English digits to Bangla digits)
  static String formatNumber(num number, String languageCode) {
    final numberStr = number.toString();
    return _convertToLocalDigits(numberStr, languageCode);
  }

  /// Format currency with localized digits
  static String formatCurrency(double amount, String languageCode,
      {bool showSymbol = true}) {
    final formatted = amount.toStringAsFixed(2);
    final localizedNumber = _convertToLocalDigits(formatted, languageCode);
    return showSymbol ? '৳ $localizedNumber' : localizedNumber;
  }

  /// Convert date to localized format
  static String formatDate(DateTime date, String languageCode) {
    if (languageCode == 'bn') {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return _convertToLocalDigits('$day/$month/$year', languageCode);
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  /// Get localized category name
  static String getCategoryName(
      String category, AppLocalizations localizations) {
    switch (category.toLowerCase()) {
      case 'food':
        return localizations.food;
      case 'transport':
        return localizations.transport;
      case 'shopping':
        return localizations.shopping;
      case 'entertainment':
        return localizations.entertainment;
      case 'health':
        return localizations.health;
      case 'education':
        return localizations.education;
      case 'bills':
        return localizations.bills;
      case 'salary':
        return localizations.salary;
      case 'freelance':
        return localizations.freelance;
      case 'investment':
        return localizations.investment;
      case 'gift':
        return localizations.gift;
      case 'other':
      default:
        return localizations.other;
    }
  }

  /// Get localized month name
  static String getMonthName(int month, AppLocalizations localizations) {
    switch (month) {
      case 1:
        return localizations.january;
      case 2:
        return localizations.february;
      case 3:
        return localizations.march;
      case 4:
        return localizations.april;
      case 5:
        return localizations.may;
      case 6:
        return localizations.june;
      case 7:
        return localizations.july;
      case 8:
        return localizations.august;
      case 9:
        return localizations.september;
      case 10:
        return localizations.october;
      case 11:
        return localizations.november;
      case 12:
        return localizations.december;
      default:
        return '';
    }
  }

  /// Get localized day name
  static String getDayName(int weekday, AppLocalizations localizations) {
    switch (weekday) {
      case DateTime.monday:
        return localizations.monday;
      case DateTime.tuesday:
        return localizations.tuesday;
      case DateTime.wednesday:
        return localizations.wednesday;
      case DateTime.thursday:
        return localizations.thursday;
      case DateTime.friday:
        return localizations.friday;
      case DateTime.saturday:
        return localizations.saturday;
      case DateTime.sunday:
        return localizations.sunday;
      default:
        return '';
    }
  }

  /// Convert English digits to localized digits (Bangla, etc.)
  static String _convertToLocalDigits(String input, String languageCode) {
    if (languageCode == 'bn') {
      const banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      String result = input;
      for (int i = 0; i < 10; i++) {
        result = result.replaceAll(i.toString(), banglaDigits[i]);
      }
      return result;
    }
    return input;
  }
}
