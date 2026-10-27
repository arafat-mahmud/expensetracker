import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:expensetracker/models/expense_model.dart';
import 'package:expensetracker/services/localized_statement_service.dart';

/// Set STATEMENT_PDF_OUT=/some/dir to keep the generated PDFs for a visual check
void main() {
  setUpAll(() async {
    // Tests do not load pubspec fonts automatically; the app does
    final loader = FontLoader('NotoSansBengali')
      ..addFont(rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf'));
    await loader.load();

    // Stand-in for the phone's system font, which supplies Latin punctuation
    // (: / -) in Bengali text. Tests have no system fonts.
    final roboto = File('${Platform.environment['FLUTTER_ROOT']}'
        '/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
    if (roboto.existsSync()) {
      final bytes = roboto.readAsBytesSync();
      await (FontLoader('Roboto')
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });

  test('bundled Bengali fonts are real TrueType files', () async {
    for (final weight in ['Regular', 'Bold']) {
      final data =
          await rootBundle.load('assets/fonts/NotoSansBengali-$weight.ttf');
      // Throws on anything that is not a font (e.g. a saved HTML page)
      final font = TtfParser(data);
      expect(font.charToGlyphIndexMap.containsKey('ক'.codeUnitAt(0)), isTrue);
      expect(font.charToGlyphIndexMap.containsKey('০'.codeUnitAt(0)), isTrue);
    }
  });

  final transactions = [
    Expense(
      id: '1',
      title: 'বেতন',
      category: 'Salary',
      amount: 50000,
      date: DateTime(2026, 10, 1),
      note: '',
      type: 'credit',
    ),
    Expense(
      id: '2',
      title: 'বাজার',
      category: 'Grocery',
      amount: 1250.5,
      date: DateTime(2026, 10, 5),
      note: '',
    ),
    Expense(
      id: '3',
      title: 'রেস্টুরেন্ট',
      category: 'Food / Restaurant',
      amount: 780,
      date: DateTime(2026, 10, 12),
      note: '',
    ),
    Expense(
      id: '4',
      title: 'Custom',
      category: 'নিজস্ব ক্ষেত্র', // non-standard category typed in Bengali
      amount: 99.99,
      date: DateTime(2026, 10, 20),
      note: '',
    ),
  ];

  for (final languageCode in ['bn', 'en']) {
    testWidgets('statement PDF builds in "$languageCode"', (tester) async {
      final bytes = await tester.runAsync(
        () => LocalizedStatementService.buildLocalizedPdf(
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 31),
          transactions: List.of(transactions),
          totalIncome: 50000,
          totalExpense: 2130.49,
          balance: 47869.51,
          localizations: languageCode == 'bn'
              ? BanglaLocalizations()
              : EnglishLocalizations(),
          languageCode: languageCode,
        ),
      );

      expect(bytes, isNotNull);
      expect(String.fromCharCodes(bytes!.sublist(0, 5)), '%PDF-');
      expect(String.fromCharCodes(bytes.sublist(bytes.length - 6)).trim(),
          '%%EOF');

      final outDir = Platform.environment['STATEMENT_PDF_OUT'];
      if (outDir != null) {
        File('$outDir/statement_$languageCode.pdf').writeAsBytesSync(bytes);
      }
    });
  }

  testWidgets('long Bengali statement spans several pages', (tester) async {
    final many = [
      for (var i = 0; i < 300; i++)
        Expense(
          id: '$i',
          title: 'খরচ $i',
          category: i.isEven ? 'Grocery' : 'Transport',
          amount: 100.0 + i,
          date: DateTime(2026, 10, 1 + i % 28),
          note: '',
        ),
    ];
    final bytes = await tester.runAsync(
      () => LocalizedStatementService.buildLocalizedPdf(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
        transactions: many,
        totalIncome: 0,
        totalExpense: 74850,
        balance: -74850,
        localizations: BanglaLocalizations(),
        languageCode: 'bn',
      ),
    );

    final pdf = String.fromCharCodes(bytes!);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(pdf).length, greaterThan(3));
  });
}
