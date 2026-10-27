import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Money and date formatting in the app's language: grouped amounts with
/// the taka sign, and Bengali digits and month names when Bengali is chosen
class AppFormat {
  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  /// ৳12,345.50 (or ৳১২,৩৪৫.৫০). [signed] adds + for positive amounts.
  static String money(BuildContext context, double amount,
      {int decimals = 2, bool signed = false}) {
    final number = NumberFormat.decimalPatternDigits(
      locale: _locale(context),
      decimalDigits: decimals,
    ).format(amount.abs());
    final sign = amount < 0 ? '-' : (signed && amount > 0 ? '+' : '');
    return '$sign৳$number';
  }

  /// Whole-number amount without the taka sign, e.g. for chart axes
  static String number(BuildContext context, num value) =>
      NumberFormat.decimalPatternDigits(
        locale: _locale(context),
        decimalDigits: 0,
      ).format(value);

  /// 12 Oct 2026
  static String date(BuildContext context, DateTime date) =>
      DateFormat('d MMM yyyy', _locale(context)).format(date);

  /// Thursday, 12 October
  static String longDate(BuildContext context, DateTime date) =>
      DateFormat('EEEE, d MMMM', _locale(context)).format(date);

  /// October 2026
  static String monthYear(BuildContext context, DateTime date) =>
      DateFormat('MMMM yyyy', _locale(context)).format(date);

  /// Day of month for chart labels
  static String day(BuildContext context, DateTime date) =>
      DateFormat('d', _locale(context)).format(date);

  /// Parses an amount typed with Latin or Bengali digits ("১২৫০.৫০") and
  /// optional thousands separators; null if it is not a number
  static double? parseAmount(String input) {
    const bengali = '০১২৩৪৫৬৭৮৯';
    final normalized = input
        .trim()
        .split('')
        .map((c) {
          final digit = bengali.indexOf(c);
          return digit >= 0 ? '$digit' : c;
        })
        .join()
        .replaceAll(',', '');
    return double.tryParse(normalized);
  }

  /// "ACCOUNT SUMMARY" -> "Account summary" for strings that are all caps
  /// in the PDF but shown on screen (no effect on Bengali)
  static String sentence(String text) => text.isEmpty
      ? text
      : text[0].toUpperCase() + text.substring(1).toLowerCase();

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
