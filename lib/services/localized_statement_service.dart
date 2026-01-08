import 'dart:io' show File, Directory, Platform;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart' show OpenFile, ResultType;
import '../models/expense_model.dart';
import '../l10n/app_localizations.dart';

class LocalizedStatementService {
  static Future<Directory> _getStorageDirectory() async {
    if (Platform.isAndroid) {
      try {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception(
                'Storage permission is required to save the statement');
          }
        }

        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final testFile = File('${directory.path}/test.txt');
        await testFile.writeAsString('test');
        await testFile.delete();

        return directory;
      } catch (e) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          return directory;
        }
      }
    }

    final directory = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    return directory;
  }

  /// Generate localized PDF Statement
  static Future<void> generateLocalizedPdfStatement({
    required DateTime startDate,
    required DateTime endDate,
    required List<Expense> transactions,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required BuildContext context,
    required String languageCode,
  }) async {
    final localizations = AppLocalizations.of(context);
    final pdf = pw.Document();

    // Load Bangla font if needed
    pw.Font? banglaFont;
    pw.Font? banglaFontBold;
    if (languageCode == 'bn') {
      try {
        final fontData =
            await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
        final fontDataBold =
            await rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf');
        banglaFont = pw.Font.ttf(fontData);
        banglaFontBold = pw.Font.ttf(fontDataBold);
      } catch (e) {
        print('Error loading Bangla fonts: $e');
        // If font loading fails, proceed without custom font
      }
    }

    // Sort transactions by date
    transactions.sort((a, b) => a.date.compareTo(b.date));

    double openingBalance = 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: banglaFont != null && banglaFontBold != null
            ? pw.ThemeData.withFont(
                base: banglaFont,
                bold: banglaFontBold,
              )
            : pw.ThemeData.base(),
        build: (pw.Context context) {
          return [
            // Header
            _buildLocalizedHeader(
                startDate, endDate, localizations, languageCode),

            pw.SizedBox(height: 30),

            // Account Summary
            _buildLocalizedAccountSummary(
              startDate,
              endDate,
              openingBalance,
              totalIncome,
              totalExpense,
              balance,
              transactions.length,
              localizations,
              languageCode,
            ),

            pw.SizedBox(height: 25),

            // Transaction Details Header
            pw.Text(
              localizations.transactionDetails,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 12),

            _buildLocalizedTransactionTable(
                transactions, openingBalance, localizations, languageCode),

            pw.SizedBox(height: 20),

            // Footer
            _buildLocalizedFooter(localizations, languageCode),
          ];
        },
      ),
    );

    // Save PDF
    final pdfBytes = await pdf.save();
    final filename =
        'statement_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.pdf';

    final directory = await _getStorageDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);

    // Open the file
    try {
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.fileSaved} ${directory.path}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.fileSaved} ${directory.path}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static pw.Widget _buildLocalizedHeader(DateTime startDate, DateTime endDate,
      AppLocalizations localizations, String languageCode) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColors.blue900),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                localizations.appName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                localizations.personalFinanceManagement,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                localizations.accountStatement,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                localizations.statementPeriod,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                _formatDateRange(startDate, endDate, languageCode),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                _formatGeneratedDate(DateTime.now(), languageCode),
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLocalizedAccountSummary(
    DateTime startDate,
    DateTime endDate,
    double openingBalance,
    double totalIncome,
    double totalExpense,
    double closingBalance,
    int transactionCount,
    AppLocalizations localizations,
    String languageCode,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                localizations.accountSummary,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              pw.Text(
                '${_convertToLocalDigits(transactionCount.toString(), languageCode)} ${localizations.transactions}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildLocalizedSummaryColumn(localizations.openingBalance,
                  openingBalance, PdfColors.blue800, languageCode),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildLocalizedSummaryColumn(localizations.credit, totalIncome,
                  PdfColors.green700, languageCode),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildLocalizedSummaryColumn(localizations.debit, totalExpense,
                  PdfColors.red700, languageCode),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildLocalizedSummaryColumn(
                localizations.closingBalance,
                closingBalance,
                closingBalance >= 0 ? PdfColors.green700 : PdfColors.red700,
                languageCode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLocalizedSummaryColumn(
      String label, double amount, PdfColor color, String languageCode) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            _formatCurrency(amount, languageCode),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLocalizedTransactionTable(
      List<Expense> transactions,
      double openingBalance,
      AppLocalizations localizations,
      String languageCode) {
    double runningBalance = openingBalance;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell(localizations.date, isHeader: true),
            _buildTableCell(localizations.description, isHeader: true),
            _buildTableCell(localizations.debit, isHeader: true),
            _buildTableCell(localizations.credit, isHeader: true),
            _buildTableCell(localizations.balance, isHeader: true),
          ],
        ),
        // Opening Balance Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildTableCell(''),
            _buildTableCell(localizations.openingBalance, isBold: true),
            _buildTableCell(''),
            _buildTableCell(''),
            _buildTableCell(_formatCurrency(runningBalance, languageCode),
                isBold: true),
          ],
        ),
        // Transaction Rows
        ...transactions.map((expense) {
          if (expense.isCredit) {
            runningBalance += expense.amount;
          } else {
            runningBalance -= expense.amount;
          }

          final categoryLabel =
              _getCategoryLabel(expense.category, localizations);

          return pw.TableRow(
            children: [
              _buildTableCell(_formatDate(expense.date, languageCode)),
              _buildTableCell(categoryLabel),
              _buildTableCell(expense.isCredit
                  ? ''
                  : _formatCurrency(expense.amount, languageCode)),
              _buildTableCell(expense.isCredit
                  ? _formatCurrency(expense.amount, languageCode)
                  : ''),
              _buildTableCell(_formatCurrency(runningBalance, languageCode)),
            ],
          );
        }),
        // Closing Balance Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          children: [
            _buildTableCell(''),
            _buildTableCell(localizations.closingBalance, isBold: true),
            _buildTableCell(''),
            _buildTableCell(''),
            _buildTableCell(_formatCurrency(runningBalance, languageCode),
                isBold: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight:
              (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildLocalizedFooter(
      AppLocalizations localizations, String languageCode) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            localizations.statementFooter,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            localizations.thisStatementIsGenerated,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static String _getCategoryLabel(
      String category, AppLocalizations localizations) {
    return localizations.getCategoryName(category);
  }

  static String _formatCurrency(double amount, String languageCode) {
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(2);
    return _convertToLocalDigits(formatted, languageCode);
  }

  static String _formatDate(DateTime date, String languageCode) {
    if (languageCode == 'bn') {
      // Format: ০১/০১/২০২৪
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return _convertToLocalDigits('$day/$month/$year', languageCode);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  static String _formatDateRange(
      DateTime startDate, DateTime endDate, String languageCode) {
    if (languageCode == 'bn') {
      return '${_formatDate(startDate, languageCode)} - ${_formatDate(endDate, languageCode)}';
    } else {
      return '${DateFormat('dd MMM yyyy').format(startDate).toUpperCase()} - ${DateFormat('dd MMM yyyy').format(endDate).toUpperCase()}';
    }
  }

  static String _formatGeneratedDate(DateTime date, String languageCode) {
    if (languageCode == 'bn') {
      return 'তৈরি: ${_formatDate(date, languageCode)}';
    } else {
      return 'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(date)}';
    }
  }

  static String _convertToLocalDigits(String input, String languageCode) {
    if (languageCode == 'bn') {
      // Convert English digits to Bangla digits
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
