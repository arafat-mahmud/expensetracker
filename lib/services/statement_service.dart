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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Account Statement',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Period: ${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                    style:
                        const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                      'Total Income', totalIncome, PdfColors.green),
                  _buildSummaryItem(
                      'Total Expense', totalExpense, PdfColors.red),
                  _buildSummaryItem(
                    'Balance',
                    balance,
                    balance >= 0 ? PdfColors.green : PdfColors.red,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Transactions Table
            pw.Text(
              'Transaction History',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),

            _buildTransactionTable(transactions),
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

  static pw.Widget _buildSummaryItem(
      String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '৳${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionTable(List<Expense> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Type', isHeader: true),
            _buildTableCell('Amount',
                isHeader: true, alignment: pw.Alignment.centerRight),
          ],
        ),
        // Data Rows
        ...transactions.map((transaction) {
          return pw.TableRow(
            children: [
              _buildTableCell(
                DateFormat('MMM dd, yyyy').format(transaction.date),
              ),
              _buildTableCell(transaction.title),
              _buildTableCell(transaction.category),
              _buildTableCell(
                transaction.isCredit ? 'Credit' : 'Debit',
                color: transaction.isCredit ? PdfColors.green : PdfColors.red,
              ),
              _buildTableCell(
                '৳${transaction.amount.toStringAsFixed(2)}',
                alignment: pw.Alignment.centerRight,
                color: transaction.isCredit ? PdfColors.green : PdfColors.red,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 10 : 9,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ),
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

    // Create CSV data
    List<List<dynamic>> rows = [
      // Header info
      ['Account Statement'],
      [
        'Period',
        '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}'
      ],
      ['Generated', DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())],
      [],
      // Summary
      ['Summary'],
      ['Total Income', '৳${totalIncome.toStringAsFixed(2)}'],
      ['Total Expense', '৳${totalExpense.toStringAsFixed(2)}'],
      ['Balance', '৳${balance.toStringAsFixed(2)}'],
      [],
      // Transaction header
      ['Date', 'Description', 'Category', 'Type', 'Amount'],
      // Transactions
      ...transactions.map((transaction) => [
            DateFormat('MMM dd, yyyy').format(transaction.date),
            transaction.title,
            transaction.category,
            transaction.isCredit ? 'Credit' : 'Debit',
            '৳${transaction.amount.toStringAsFixed(2)}',
          ]),
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
          'Statement from ${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}',
    );
  }
}
