import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../models/deposit_model.dart';

class DepositPdfService {
  static Future<void> generateAndDownloadPdf({
    required List<DepositProfile> profiles,
    required List<DepositTransaction> transactions,
    required double totalBalance,
    required double totalDeposited,
    required double totalWithdrawn,
  }) async {
    final pdf = pw.Document();

    // Load fonts for better text rendering
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Add pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(fontBold),
          pw.SizedBox(height: 20),

          // Summary Section
          _buildSummary(
            font,
            fontBold,
            totalBalance,
            totalDeposited,
            totalWithdrawn,
          ),
          pw.SizedBox(height: 30),

          // Profiles Section
          _buildProfilesSection(font, fontBold, profiles, transactions),
          pw.SizedBox(height: 30),

          // Transactions Section
          _buildTransactionsSection(font, fontBold, transactions, profiles),

          // Footer
          pw.SizedBox(height: 20),
          _buildFooter(font),
        ],
      ),
    );

    // Save and open PDF
    await _savePdf(pdf);
  }

  static pw.Widget _buildHeader(pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Savings Report',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 28,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary(
    pw.Font font,
    pw.Font fontBold,
    double totalBalance,
    double totalDeposited,
    double totalWithdrawn,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 2),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Financial Summary',
            style: pw.TextStyle(font: fontBold, fontSize: 20),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                font,
                fontBold,
                'Total Savings',
                '\$${totalBalance.toStringAsFixed(2)}',
                PdfColors.blue,
              ),
              _buildSummaryItem(
                font,
                fontBold,
                'Total Saved',
                '\$${totalDeposited.toStringAsFixed(2)}',
                PdfColors.green,
              ),
              _buildSummaryItem(
                font,
                fontBold,
                'Total Withdrawn',
                '\$${totalWithdrawn.toStringAsFixed(2)}',
                PdfColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
    pw.Font font,
    pw.Font fontBold,
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(font: fontBold, fontSize: 18, color: color),
        ),
      ],
    );
  }

  static pw.Widget _buildProfilesSection(
    pw.Font font,
    pw.Font fontBold,
    List<DepositProfile> profiles,
    List<DepositTransaction> transactions,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Savings Goals (${profiles.length})',
          style: pw.TextStyle(font: fontBold, fontSize: 20),
        ),
        pw.SizedBox(height: 15),
        ...profiles.map((profile) {
          final profileTransactions =
              transactions.where((t) => t.profileId == profile.id).toList();
          final balance = profileTransactions.fold<double>(
            0,
            (sum, t) => sum + (t.isDeposit ? t.amount : -t.amount),
          );
          final progress =
              profile.targetAmount > 0 ? balance / profile.targetAmount : 0;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      profile.name,
                      style: pw.TextStyle(font: fontBold, fontSize: 16),
                    ),
                    if (profile.isCompleted)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'COMPLETED',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Balance: \$${balance.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                    pw.Text(
                      'Target: \$${profile.targetAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Text(
                      'Progress: ${(progress * 100).toStringAsFixed(1)}%',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'Deadline: ${DateFormat('MMM dd, yyyy').format(profile.deadline)}',
                      style: pw.TextStyle(
                          font: font, fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
                if (profile.note.isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Note: ${profile.note}',
                    style: pw.TextStyle(
                        font: font, fontSize: 11, color: PdfColors.grey600),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTransactionsSection(
    pw.Font font,
    pw.Font fontBold,
    List<DepositTransaction> transactions,
    List<DepositProfile> profiles,
  ) {
    // Sort transactions by date (newest first)
    final sortedTransactions = List<DepositTransaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Transactions (${transactions.length})',
          style: pw.TextStyle(font: fontBold, fontSize: 20),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', fontBold, isHeader: true),
                _buildTableCell('Profile', fontBold, isHeader: true),
                _buildTableCell('Type', fontBold, isHeader: true),
                _buildTableCell('Amount', fontBold, isHeader: true),
              ],
            ),
            // Transactions
            ...sortedTransactions.take(20).map((transaction) {
              final profile =
                  profiles.firstWhere((p) => p.id == transaction.profileId);
              return pw.TableRow(
                children: [
                  _buildTableCell(
                      DateFormat('MMM dd, yyyy').format(transaction.date),
                      font),
                  _buildTableCell(profile.name, font),
                  _buildTableCell(
                    transaction.isDeposit ? 'Saved' : 'Withdraw',
                    font,
                    color:
                        transaction.isDeposit ? PdfColors.green : PdfColors.red,
                  ),
                  _buildTableCell(
                    '\$${transaction.amount.toStringAsFixed(2)}',
                    font,
                    color: transaction.isDeposit
                        ? PdfColors.green700
                        : PdfColors.red700,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
        if (sortedTransactions.length > 20) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Showing 20 of ${sortedTransactions.length} transactions',
            style:
                pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 12 : 10,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Center(
        child: pw.Text(
          'Expense Tracker - Savings Report',
          style:
              pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
        ),
      ),
    );
  }

  static Future<void> _savePdf(pw.Document pdf) async {
    try {
      // Generate PDF bytes
      final bytes = await pdf.save();

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access download directory');
      }

      // Create unique filename
      final fileName =
          'Savings_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      // Save file
      await file.writeAsBytes(bytes);

      print('PDF saved to: ${file.path}');

      // Open the file
      await OpenFile.open(file.path);
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  // Alternative method: Share PDF instead of downloading
  static Future<void> sharePdf({
    required List<DepositProfile> profiles,
    required List<DepositTransaction> transactions,
    required double totalBalance,
    required double totalDeposited,
    required double totalWithdrawn,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(fontBold),
          pw.SizedBox(height: 20),
          _buildSummary(
            font,
            fontBold,
            totalBalance,
            totalDeposited,
            totalWithdrawn,
          ),
          pw.SizedBox(height: 30),
          _buildProfilesSection(font, fontBold, profiles, transactions),
          pw.SizedBox(height: 30),
          _buildTransactionsSection(font, fontBold, transactions, profiles),
          pw.SizedBox(height: 20),
          _buildFooter(font),
        ],
      ),
    );

    // Share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'Savings_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }
}
