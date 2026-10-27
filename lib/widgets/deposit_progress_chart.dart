import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_format.dart';
import '../theme/app_theme.dart';

class DepositProgressChart extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final bool isCompleted;
  final bool isOverdue;
  final bool isOnTrack;

  const DepositProgressChart({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 12,
    this.isCompleted = false,
    this.isOverdue = false,
    this.isOnTrack = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final color = isCompleted
        ? palette.income
        : isOverdue
            ? palette.expense
            : (isOnTrack ? scheme.primary : palette.warning);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircleProgressPainter(
              progress: 1.0,
              color: scheme.surfaceContainerHighest,
              strokeWidth: strokeWidth,
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _CircleProgressPainter(
              progress: progress.clamp(0.0, 1.0),
              color: color,
              strokeWidth: strokeWidth,
            ),
          ),
          if (isCompleted)
            Icon(Icons.check_rounded, color: color, size: size * 0.4)
          else
            Text(
              '${AppFormat.number(context, (progress * 100).round())}%',
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
