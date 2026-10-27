// Temporary: checks the swipeable quick-select row. Not committed.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:expensetracker/models/expense_model.dart';
import 'package:expensetracker/providers/expense_provider.dart';
import 'package:expensetracker/screens/statement_page.dart';
import 'package:expensetracker/theme/app_theme.dart';

class FakeExpense extends ChangeNotifier implements ExpenseProvider {
  @override
  List<Expense> filterByDateRange(DateTime s, DateTime e) => [
        Expense(id: '1', title: 'Grocery', category: 'Grocery', amount: 500, date: DateTime.now(), note: ''),
      ];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(p.startsWith('assets/')
        ? rootBundle.load(p)
        : Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  final out = Platform.environment['UI_PREVIEW_OUT']!;
  final sdk = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';

  setUpAll(() async {
    await _loadFont('Roboto', ['$sdk/Roboto-Regular.ttf', '$sdk/Roboto-Medium.ttf', '$sdk/Roboto-Bold.ttf']);
    await _loadFont('MaterialIcons', ['$sdk/MaterialIcons-Regular.otf']);
    await _loadFont('NotoSansBengali', ['assets/fonts/NotoSansBengali-Regular.ttf', 'assets/fonts/NotoSansBengali-Bold.ttf']);
  });

  for (final lang in ['en', 'bn']) {
    testWidgets('quick select row swipes sideways ($lang)', (tester) async {
      tester.view.physicalSize = const Size(412 * 2, 915 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      ThemeData theme(ThemeData t) => t.copyWith(
          textTheme: t.textTheme.apply(fontFamilyFallback: const ['Roboto', 'NotoSansBengali']));

      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: ChangeNotifierProvider<ExpenseProvider>.value(
          value: FakeExpense(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: Locale(lang),
            supportedLocales: const [Locale('en'), Locale('bn')],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: theme(AppTheme.light(lang)),
            home: const StatementPage(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // All six chips sit in one row: same vertical position
      final chips = find.byType(ChoiceChip);
      final firstY = tester.getCenter(chips.first).dy;
      final rowList = find.ancestor(of: chips.first, matching: find.byType(Scrollable)).first;
      final row = tester.state<ScrollableState>(rowList).position;
      final page = tester.state<ScrollableState>(
          find.byType(Scrollable).first).position;
      expect(row.axis, Axis.horizontal);
      expect(row.maxScrollExtent, greaterThan(0), reason: 'chips overflow the screen, so the row scrolls');

      final shot = await _capture(tester, key);
      File('$out/statement_chips_${lang}_start.png').writeAsBytesSync(shot);

      // Swipe left: the row scrolls, the page does not
      await tester.drag(rowList, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(row.pixels, greaterThan(0));
      expect(page.pixels, 0);

      // Back to start, then tap the chip that is cut off at the right edge
      row.jumpTo(0);
      await tester.pumpAndSettle();
      final halfHidden = find.byType(ChoiceChip).evaluate().map((e) => e.widget as ChoiceChip).firstWhere((chip) {
        final rect = tester.getRect(find.byWidget(chip));
        return rect.left < 412 && rect.right > 412;
      });
      final label = (halfHidden.label as Text).data!;
      final target = find.widgetWithText(ChoiceChip, label);
      final before = tester.getRect(target);
      // ignore: avoid_print
      print('half-hidden "$label" ($lang) spans x ${before.left.toStringAsFixed(0)}..${before.right.toStringAsFixed(0)}');
      await tester.tapAt(Offset((before.left + 412) / 2, before.center.dy));
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(target).selected, isTrue);
      expect(row.pixels, greaterThan(0), reason: 'tapped chip scrolled into view');
      expect(page.pixels, 0, reason: 'page did not jump');
      final chipRect = tester.getRect(target);
      expect(chipRect.right, lessThanOrEqualTo(412), reason: 'chip now fully visible');
      expect(tester.getCenter(chips.first).dy, firstY);
      // ignore: avoid_print
      print('tapped "$label" ($lang): row scrolled to ${row.pixels.toStringAsFixed(0)}px, page at ${page.pixels}');

      File('$out/statement_chips_${lang}_after_tap.png')
          .writeAsBytesSync(await _capture(tester, key));
    });
  }
}

Future<List<int>> _capture(WidgetTester tester, GlobalKey key) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  return bytes!;
}
