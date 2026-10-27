import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Draws text for PDFs built with the `pdf` package.
///
/// That package cannot shape Bengali: it would draw a vowel sign such as ি
/// after its consonant instead of before it, and break conjuncts like ক্ষ.
/// Text containing Bengali letters is therefore laid out by Flutter's own
/// text engine (the same one that renders the app) and embedded as a
/// high-resolution image. Everything else, including Bengali digits, stays
/// real PDF text.
///
/// Images are rendered asynchronously while PDF layout is synchronous, so
/// content is built twice: the first pass records which strings are needed,
/// [renderPending] draws them, and the second pass uses the results.
class PdfShapedText {
  PdfShapedText({this.shapeDigits = false});

  /// Also draw Bengali digits as images (for when no Bengali PDF font loaded)
  final bool shapeDigits;

  static const String _fontFamily = 'NotoSansBengali';

  // Print quality: 300 dpi, where one PDF point is 1/72 inch
  static const double _pixelRatio = 300 / 72;

  final Map<String, _ShapedImage?> _rendered = {};
  final Map<String, _Request> _pending = {};

  pw.Widget text(
    String text, {
    pw.TextStyle? style,
    pw.TextAlign textAlign = pw.TextAlign.left,
    double? maxWidth,
  }) {
    if (!_needsShaping(text)) {
      return pw.Text(text, style: style, textAlign: textAlign);
    }

    final request =
        _Request(text, style ?? const pw.TextStyle(), textAlign, maxWidth);
    if (!_rendered.containsKey(request.key)) {
      _pending[request.key] = request;
      return pw.SizedBox();
    }

    final shaped = _rendered[request.key];
    if (shaped == null) {
      // Rendering failed: unshaped text still beats a missing label
      return pw.Text(text, style: style, textAlign: textAlign);
    }
    final image =
        pw.Image(shaped.image, width: shaped.width, height: shaped.height);
    switch (textAlign) {
      case pw.TextAlign.center:
        return pw.Center(child: image);
      case pw.TextAlign.right:
        return pw.Align(alignment: pw.Alignment.centerRight, child: image);
      default:
        return image;
    }
  }

  Future<void> renderPending() async {
    final requests = _pending.values.toList();
    _pending.clear();
    for (final request in requests) {
      _rendered[request.key] = await _render(request);
    }
  }

  bool _needsShaping(String text) {
    for (final unit in text.codeUnits) {
      if (unit < 0x0980 || unit > 0x09FF) continue;
      // Digits and the taka sign are single glyphs that need no shaping
      final isDigit = unit >= 0x09E6 && unit <= 0x09EF;
      if ((isDigit || unit == 0x09F3) && !shapeDigits) continue;
      return true;
    }
    return false;
  }

  Future<_ShapedImage?> _render(_Request request) async {
    final painter = TextPainter(
      text: TextSpan(
        text: request.text,
        style: TextStyle(
          fontFamily: _fontFamily,
          // The Bengali font has no Latin letters or punctuation (: / -).
          // Roboto is Android's system font; elsewhere Flutter falls back to
          // the system font on its own.
          fontFamilyFallback: const ['Roboto'],
          fontSize: request.style.fontSize ?? 12,
          fontWeight: request.style.fontWeight == pw.FontWeight.bold
              ? FontWeight.bold
              : FontWeight.normal,
          color: _toColor(request.style.color ?? PdfColors.black),
        ),
      ),
      textAlign: _toTextAlign(request.textAlign),
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
    );

    try {
      painter.layout(maxWidth: request.maxWidth ?? double.infinity);
      final width = painter.width;
      final height = painter.height;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(_pixelRatio);
      painter.paint(canvas, Offset.zero);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (width * _pixelRatio).ceil().clamp(1, 1 << 14),
        (height * _pixelRatio).ceil().clamp(1, 1 << 14),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      image.dispose();

      if (bytes == null) return null;
      return _ShapedImage(
          pw.MemoryImage(bytes.buffer.asUint8List()), width, height);
    } catch (e) {
      print('⚠️ [PDF] Could not render "${request.text}": $e');
      return null;
    } finally {
      painter.dispose();
    }
  }

  static Color _toColor(PdfColor color) => Color.fromARGB(
        (color.alpha * 255).round(),
        (color.red * 255).round(),
        (color.green * 255).round(),
        (color.blue * 255).round(),
      );

  static TextAlign _toTextAlign(pw.TextAlign align) {
    switch (align) {
      case pw.TextAlign.center:
        return TextAlign.center;
      case pw.TextAlign.right:
        return TextAlign.right;
      case pw.TextAlign.justify:
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }
}

class _Request {
  _Request(this.text, this.style, this.textAlign, this.maxWidth);

  final String text;
  final pw.TextStyle style;
  final pw.TextAlign textAlign;
  final double? maxWidth;

  String get key => [
        text,
        style.fontSize,
        style.fontWeight,
        style.color?.toInt(),
        textAlign,
        maxWidth,
      ].join('|');
}

class _ShapedImage {
  _ShapedImage(this.image, this.width, this.height);

  final pw.ImageProvider image;
  final double width;
  final double height;
}
