import 'dart:io' show File, Directory, Platform;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart' show OpenFile, ResultType;
import '../models/expense_model.dart';
import '../l10n/app_localizations.dart';

class StatementService {
  static Future<Directory> _getStorageDirectory() async {
    if (Platform.isAndroid) {
      try {
        // First try with regular storage permission
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          // If regular storage fails, try manage external storage
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception(
                'Storage permission is required to save the statement');
          }
        }

        // Try to use the Downloads folder directly
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // Test if we can actually write to the directory
        final testFile = File('${directory.path}/test.txt');
        await testFile.writeAsString('test');
        await testFile.delete();

        return directory;
      } catch (e) {
        // If Downloads directory fails, try application-specific directory
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          return directory;
        }
      }
    }

    // For iOS or fallback
    final directory = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    return directory;
  }

  /// Generate PDF Statement with preview and Google Drive upload option
  static Future<void> generatePdfStatement({
    required DateTime startDate,
    required DateTime endDate,
    required List<Expense> transactions,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    BuildContext? context,
    AppLocalizations? localizations,
  }) async {
    final pdf = pw.Document();

    // Sort transactions by date
    transactions.sort((a, b) => a.date.compareTo(b.date));

    // For statement period, opening balance is 0 (starting fresh for the period)
    // Closing balance will be totalIncome - totalExpense
    double openingBalance = 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context pdfContext) {
          return [
            // Professional Bank Header
            _buildProfessionalHeader(startDate, endDate),

            pw.SizedBox(height: 30),

            // Account Summary Box
            _buildAccountSummary(
              startDate,
              endDate,
              openingBalance,
              totalIncome,
              totalExpense,
              balance,
              transactions.length,
            ),

            pw.SizedBox(height: 25),

            // Transaction Ledger
            pw.Text(
              'TRANSACTION DETAILS',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 12),

            _buildProfessionalTransactionTable(
                transactions, openingBalance, localizations),

            pw.SizedBox(height: 20),

            // Footer
            _buildStatementFooter(),
          ];
        },
      ),
    );

    // Get PDF bytes
    final pdfBytes = await pdf.save();
    final filename =
        'statement_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.pdf';

    // Skip preview and save directly

    // Get storage directory with proper permissions
    final directory = await _getStorageDirectory(); // Ensure directory exists
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);

    // Open the file with the default PDF viewer
    try {
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done &&
          context != null &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'File saved to ${directory.path}. Please open it manually.'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'File saved to ${directory.path}. Please open it manually.'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static pw.Widget _buildProfessionalHeader(
      DateTime startDate, DateTime endDate) {
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
                'Expense Tracker',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Personal Finance Management',
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
                'ACCOUNT STATEMENT',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Statement Period',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                '${DateFormat('dd MMM yyyy').format(startDate).toUpperCase()} - ${DateFormat('dd MMM yyyy').format(endDate).toUpperCase()}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
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

  static pw.Widget _buildAccountSummary(
    DateTime startDate,
    DateTime endDate,
    double openingBalance,
    double totalIncome,
    double totalExpense,
    double closingBalance,
    int transactionCount,
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
                'ACCOUNT SUMMARY',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              pw.Text(
                '$transactionCount Transactions',
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
              _buildSummaryColumn(
                  'Opening Balance', openingBalance, PdfColors.blue800),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildSummaryColumn(
                  'Total Credits', totalIncome, PdfColors.green700),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildSummaryColumn(
                  'Total Debits', totalExpense, PdfColors.red700),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildSummaryColumn(
                'Closing Balance',
                closingBalance,
                closingBalance >= 0 ? PdfColors.green700 : PdfColors.red700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryColumn(
      String label, double amount, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${amount.toStringAsFixed(2)}',
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

  static pw.Widget _buildProfessionalTransactionTable(
    List<Expense> transactions,
    double openingBalance,
    AppLocalizations? localizations,
  ) {
    double runningBalance = openingBalance;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(70), // Date
        1: const pw.FlexColumnWidth(2.5), // Description
        2: const pw.FlexColumnWidth(1.5), // Category
        3: const pw.FixedColumnWidth(65), // Debit
        4: const pw.FixedColumnWidth(65), // Credit
        5: const pw.FixedColumnWidth(75), // Balance
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            _buildProfessionalTableHeader('DATE'),
            _buildProfessionalTableHeader('DESCRIPTION'),
            _buildProfessionalTableHeader('CATEGORY'),
            _buildProfessionalTableHeader('DEBIT',
                alignment: pw.Alignment.centerRight),
            _buildProfessionalTableHeader('CREDIT',
                alignment: pw.Alignment.centerRight),
            _buildProfessionalTableHeader('BALANCE',
                alignment: pw.Alignment.centerRight),
          ],
        ),
        // Opening Balance Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildProfessionalTableCell('', isBold: true),
            _buildProfessionalTableCell('Opening Balance', isBold: true),
            _buildProfessionalTableCell('', isBold: true),
            _buildProfessionalTableCell('',
                isBold: true, alignment: pw.Alignment.centerRight),
            _buildProfessionalTableCell('',
                isBold: true, alignment: pw.Alignment.centerRight),
            _buildProfessionalTableCell(
              '${runningBalance.toStringAsFixed(2)}',
              isBold: true,
              alignment: pw.Alignment.centerRight,
            ),
          ],
        ),
        // Transaction Rows
        ...transactions.map((transaction) {
          // Update running balance AFTER getting the transaction details
          // For credits (income), add to balance
          // For debits (expense), subtract from balance
          if (transaction.isCredit) {
            runningBalance += transaction.amount;
          } else {
            runningBalance -= transaction.amount;
          }

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: transactions.indexOf(transaction) % 2 == 0
                  ? PdfColors.white
                  : PdfColors.grey50,
            ),
            children: [
              _buildProfessionalTableCell(
                DateFormat('dd/MM/yyyy').format(transaction.date),
              ),
              _buildProfessionalTableCell(transaction.title),
              _buildProfessionalTableCell(
                localizations?.getCategoryName(transaction.category) ??
                    transaction.category,
              ),
              _buildProfessionalTableCell(
                transaction.isCredit
                    ? '-'
                    : '${transaction.amount.toStringAsFixed(2)}',
                alignment: pw.Alignment.centerRight,
                color: transaction.isCredit ? null : PdfColors.red700,
              ),
              _buildProfessionalTableCell(
                transaction.isCredit
                    ? '${transaction.amount.toStringAsFixed(2)}'
                    : '-',
                alignment: pw.Alignment.centerRight,
                color: transaction.isCredit ? PdfColors.green700 : null,
              ),
              _buildProfessionalTableCell(
                '${runningBalance.toStringAsFixed(2)}',
                alignment: pw.Alignment.centerRight,
                isBold: true,
              ),
            ],
          );
        }),
        // Closing Balance Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildProfessionalTableCell('', isBold: true),
            _buildProfessionalTableCell('Closing Balance', isBold: true),
            _buildProfessionalTableCell('', isBold: true),
            _buildProfessionalTableCell('',
                isBold: true, alignment: pw.Alignment.centerRight),
            _buildProfessionalTableCell('',
                isBold: true, alignment: pw.Alignment.centerRight),
            _buildProfessionalTableCell(
              '${runningBalance.toStringAsFixed(2)}',
              isBold: true,
              alignment: pw.Alignment.centerRight,
              color:
                  runningBalance >= 0 ? PdfColors.green700 : PdfColors.red700,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalTableHeader(
    String text, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildProfessionalTableCell(
    String text, {
    bool isBold = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
        ),
      ),
    );
  }

  static pw.Widget _buildBulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 15),
          pw.Container(
            width: 3,
            height: 3,
            margin: const pw.EdgeInsets.only(top: 3, right: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey700,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey800,
                lineSpacing: 1.5,
                font: pw.Font.helvetica(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatementFooter() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 3,
                height: 14,
                margin: const pw.EdgeInsets.only(right: 6),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'IMPORTANT NOTES',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _buildBulletPoint(
              'This is a computer-generated statement and does not require a signature.'),
          _buildBulletPoint(
              'Please verify all transactions and report any discrepancies immediately.'),
          _buildBulletPoint(
              'Debit represents money spent, Credit represents money received.'),
          _buildBulletPoint(
              'Balance column shows your running account balance after each transaction.'),
        ],
      ),
    );
  }

  // CSV functionality has been removed
}
