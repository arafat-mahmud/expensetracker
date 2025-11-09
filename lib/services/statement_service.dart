import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_model.dart';

class StatementService {
  /// Generate PDF Statement
  static Future<void> generatePdfStatement({
    required DateTime startDate,
    required DateTime endDate,
    required List<Expense> transactions,
    required double totalIncome,
    required double totalExpense,
    required double balance,
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
        build: (pw.Context context) {
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

            _buildProfessionalTransactionTable(transactions, openingBalance),

            pw.SizedBox(height: 20),

            // Footer
            _buildStatementFooter(),
          ];
        },
      ),
    );

    // Share or print PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'statement_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.pdf',
    );
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
                'SMART BUDGET',
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
              _buildProfessionalTableCell(transaction.category),
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

  static pw.Widget _buildStatementFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Text(
          'IMPORTANT NOTES:',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '• This is a computer-generated statement and does not require a signature.\n• Please verify all transactions and report any discrepancies immediately.\n• Debit represents money spent, Credit represents money received.\n• Balance column shows your running account balance after each transaction.',
          style: const pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey700,
            lineSpacing: 2,
          ),
        ),
      ],
    );
  }

  /// Generate CSV Statement
  static Future<void> generateCsvStatement({
    required DateTime startDate,
    required DateTime endDate,
    required List<Expense> transactions,
    required double totalIncome,
    required double totalExpense,
    required double balance,
  }) async {
    // Sort transactions by date
    transactions.sort((a, b) => a.date.compareTo(b.date));

    // Opening balance is 0 for the statement period
    double openingBalance = 0.0;
    double runningBalance = openingBalance;

    // Create CSV data with professional banking format
    List<List<dynamic>> rows = [
      // Header
      ['SMART BUDGET - ACCOUNT STATEMENT'],
      [],
      [
        'Statement Period:',
        '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}'
      ],
      ['Generated:', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())],
      ['Total Transactions:', transactions.length.toString()],
      [],
      // Summary Section
      ['ACCOUNT SUMMARY'],
      ['Opening Balance', '${openingBalance.toStringAsFixed(2)}'],
      ['Total Credits (+)', '${totalIncome.toStringAsFixed(2)}'],
      ['Total Debits (-)', '${totalExpense.toStringAsFixed(2)}'],
      ['Closing Balance', '${balance.toStringAsFixed(2)}'],
      [],
      // Transaction Details Header
      ['TRANSACTION DETAILS'],
      ['Date', 'Description', 'Category', 'Debit', 'Credit', 'Balance'],
      // Opening Balance Row
      [
        '',
        'Opening Balance',
        '',
        '',
        '',
        '${runningBalance.toStringAsFixed(2)}'
      ],
      // Transaction Rows with running balance
      ...transactions.map((transaction) {
        String debit = '-';
        String credit = '-';

        if (transaction.isCredit) {
          credit = '${transaction.amount.toStringAsFixed(2)}';
          runningBalance += transaction.amount;
        } else {
          debit = '${transaction.amount.toStringAsFixed(2)}';
          runningBalance -= transaction.amount;
        }

        return [
          DateFormat('dd/MM/yyyy').format(transaction.date),
          transaction.title,
          transaction.category,
          debit,
          credit,
          '${runningBalance.toStringAsFixed(2)}',
        ];
      }),
      // Closing Balance Row
      [
        '',
        'Closing Balance',
        '',
        '',
        '',
        '${runningBalance.toStringAsFixed(2)}'
      ],
      [],
      // Footer Notes
      ['NOTES:'],
      ['• This is a computer-generated statement'],
      ['• Debit represents money spent, Credit represents money received'],
      ['• Balance column shows running account balance after each transaction'],
    ];

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(rows);

    // Save to temporary file
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/statement_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    // Share the file
    await Share.shareXFiles(
      [XFile(path)],
      subject: 'Account Statement',
      text:
          'Statement from ${DateFormat('dd MMM yyyy').format(startDate)} to ${DateFormat('dd MMM yyyy').format(endDate)}',
    );
  }
}
