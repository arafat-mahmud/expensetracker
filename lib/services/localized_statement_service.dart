import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/expense_model.dart';
import '../l10n/app_localizations.dart';
import '../utils/pdf_shaped_text.dart';
import 'pdf_file_saver.dart';

class LocalizedStatementService {
  static const double _pageMargin = 40;
  static final double _contentWidth = PdfPageFormat.a4.width - 2 * _pageMargin;

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
    final pdfBytes = await buildLocalizedPdf(
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: balance,
      localizations: localizations,
      languageCode: languageCode,
    );

    // Save PDF
    final filename =
        'statement_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.pdf';

    // Saved even if the user has left the page; only the message needs it
    final savedTo = await PdfFileSaver.saveAndOpen(pdfBytes, filename);
    if (savedTo != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.fileSaved} $savedTo'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Builds the statement PDF without saving it (also used by tests)
  static Future<Uint8List> buildLocalizedPdf({
    required DateTime startDate,
    required DateTime endDate,
    required List<Expense> transactions,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required AppLocalizations localizations,
    required String languageCode,
  }) async {
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
        // pw.Font.ttf only parses the file while the PDF is being saved, where
        // a broken font crashes ("Null check operator used on a null value").
        // Parsing here lets a bad file fall back instead.
        TtfParser(fontData);
        TtfParser(fontDataBold);
        banglaFont = pw.Font.ttf(fontData);
        banglaFontBold = pw.Font.ttf(fontDataBold);
      } catch (e) {
        print('Error loading Bangla fonts: $e');
        // If font loading fails, proceed without custom font
      }
    }

    // Bengali letters need shaping the pdf package cannot do; see PdfShapedText
    final shaped = PdfShapedText(shapeDigits: banglaFont == null);

    // Sort transactions by date
    transactions.sort((a, b) => a.date.compareTo(b.date));

    double openingBalance = 0;

    List<pw.Widget> buildContent() {
      return [
        // Header
        _buildLocalizedHeader(
            startDate, endDate, localizations, languageCode, shaped),

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
          shaped,
        ),

        pw.SizedBox(height: 25),

        // Transaction Details Header
        shaped.text(
          localizations.transactionDetails,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 12),

        _buildLocalizedTransactionTable(
            transactions, openingBalance, localizations, languageCode, shaped),

        pw.SizedBox(height: 20),

        // Footer
        _buildLocalizedFooter(localizations, languageCode, shaped),
      ];
    }

    // First pass only collects the Bengali text, which is drawn next
    buildContent();
    await shaped.renderPending();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_pageMargin),
        theme: banglaFont != null && banglaFontBold != null
            ? pw.ThemeData.withFont(
                base: banglaFont,
                bold: banglaFontBold,
                // The Bengali font has no Latin letters or punctuation (/ . -)
                fontFallback: [pw.Font.helvetica()],
              )
            : pw.ThemeData.base(),
        build: (pw.Context context) => buildContent(),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildLocalizedHeader(
      DateTime startDate,
      DateTime endDate,
      AppLocalizations localizations,
      String languageCode,
      PdfShapedText shaped) {
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
              shaped.text(
                localizations.appName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 4),
              shaped.text(
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
              shaped.text(
                localizations.accountStatement,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 8),
              shaped.text(
                localizations.statementPeriod,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              shaped.text(
                _formatDateRange(startDate, endDate, languageCode),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              shaped.text(
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
    PdfShapedText shaped,
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
              shaped.text(
                localizations.accountSummary,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              shaped.text(
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
                  openingBalance, PdfColors.blue800, languageCode, shaped),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildLocalizedSummaryColumn(localizations.credit, totalIncome,
                  PdfColors.green700, languageCode, shaped),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildLocalizedSummaryColumn(localizations.debit, totalExpense,
                  PdfColors.red700, languageCode, shaped),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildLocalizedSummaryColumn(
                localizations.closingBalance,
                closingBalance,
                closingBalance >= 0 ? PdfColors.green700 : PdfColors.red700,
                languageCode,
                shaped,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLocalizedSummaryColumn(String label, double amount,
      PdfColor color, String languageCode, PdfShapedText shaped) {
    // A quarter of the summary box, less its padding and dividers
    final labelWidth = (_contentWidth - 40) / 4;
    return pw.Expanded(
      child: pw.Column(
        children: [
          shaped.text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
            maxWidth: labelWidth,
          ),
          pw.SizedBox(height: 6),
          shaped.text(
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
      String languageCode,
      PdfShapedText shaped) {
    double runningBalance = openingBalance;

    const columnFlex = [1.5, 3.0, 2.0, 2.0, 2.0];
    final totalFlex = columnFlex.reduce((a, b) => a + b);
    // Room for text in each column: its share of the page, less cell padding
    // and borders
    final textWidths = [
      for (final flex in columnFlex) _contentWidth * flex / totalFlex - 14,
    ];
    pw.Widget cell(int column, String text,
            {bool isHeader = false, bool isBold = false}) =>
        _buildTableCell(text, shaped,
            maxWidth: textWidths[column], isHeader: isHeader, isBold: isBold);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: {
        for (var i = 0; i < columnFlex.length; i++)
          i: pw.FlexColumnWidth(columnFlex[i]),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            cell(0, localizations.date, isHeader: true),
            cell(1, localizations.description, isHeader: true),
            cell(2, localizations.debit, isHeader: true),
            cell(3, localizations.credit, isHeader: true),
            cell(4, localizations.balance, isHeader: true),
          ],
        ),
        // Opening Balance Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            cell(0, ''),
            cell(1, localizations.openingBalance, isBold: true),
            cell(2, ''),
            cell(3, ''),
            cell(4, _formatCurrency(runningBalance, languageCode),
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
              cell(0, _formatDate(expense.date, languageCode)),
              cell(1, categoryLabel),
              cell(
                  2,
                  expense.isCredit
                      ? ''
                      : _formatCurrency(expense.amount, languageCode)),
              cell(
                  3,
                  expense.isCredit
                      ? _formatCurrency(expense.amount, languageCode)
                      : ''),
              cell(4, _formatCurrency(runningBalance, languageCode)),
            ],
          );
        }),
        // Closing Balance Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          children: [
            cell(0, ''),
            cell(1, localizations.closingBalance, isBold: true),
            cell(2, ''),
            cell(3, ''),
            cell(4, _formatCurrency(runningBalance, languageCode),
                isBold: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, PdfShapedText shaped,
      {double? maxWidth, bool isHeader = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: shaped.text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight:
              (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
        maxWidth: maxWidth,
      ),
    );
  }

  static pw.Widget _buildLocalizedFooter(AppLocalizations localizations,
      String languageCode, PdfShapedText shaped) {
    // Footer box width less its padding
    final textWidth = _contentWidth - 24;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          shaped.text(
            localizations.statementFooter,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
            ),
            maxWidth: textWidth,
          ),
          pw.SizedBox(height: 4),
          shaped.text(
            localizations.thisStatementIsGenerated,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
            ),
            maxWidth: textWidth,
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
