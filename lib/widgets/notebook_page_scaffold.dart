import 'package:flutter/material.dart';

/// Simple blank page used on the left side of the notebook spread.
class NotebookPlainPage extends StatelessWidget {
  const NotebookPlainPage({
    super.key,
    required this.backgroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Lined notebook page used for writing on the right side of the spread.
class NotebookLinedPage extends StatelessWidget {
  const NotebookLinedPage({
    super.key,
    required this.backgroundColor,
    required this.lineColor,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.lineSpacing = 28,
    this.lineCount,
  });

  final Color backgroundColor;
  final Color lineColor;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double lineSpacing;
  final int? lineCount;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding.resolve(Directionality.of(context));
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: _NotebookLinesPainter(
            lineColor: lineColor,
            lineSpacing: lineSpacing,
            topInset: resolvedPadding.top,
            bottomInset: resolvedPadding.bottom,
            lineCount: lineCount,
          ),
          child: SizedBox.expand(
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotebookLinesPainter extends CustomPainter {
  _NotebookLinesPainter({
    required this.lineColor,
    required this.lineSpacing,
    required this.topInset,
    required this.bottomInset,
    required this.lineCount,
  });

  final Color lineColor;
  final double lineSpacing;
  final double topInset;
  final double bottomInset;
  final int? lineCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final spacing = lineSpacing <= 0 ? 28.0 : lineSpacing;
    final double start = topInset.clamp(0, size.height.toDouble()).toDouble();
    final double effectiveBottom =
        size.height - bottomInset.clamp(0, size.height.toDouble());
    final double drawableHeight =
        (effectiveBottom - start).clamp(0, size.height);

    if (lineCount != null && lineCount! > 0 && drawableHeight > 0) {
      final int clampedCount =
          lineCount! < 1 ? 1 : (lineCount! > 200 ? 200 : lineCount!);
      if (clampedCount == 1) {
        final dy = start;
        canvas.drawLine(
          Offset(0, dy),
          Offset(size.width, dy),
          paint,
        );
        return;
      }
      final int effectiveCount = clampedCount;
      final double calculatedSpacing = drawableHeight / (effectiveCount - 1);
      for (var i = 0; i < effectiveCount; i++) {
        final double dy = start + (calculatedSpacing * i);
        if (dy > effectiveBottom + 0.5) continue;
        canvas.drawLine(
          Offset(0, dy),
          Offset(size.width, dy),
          paint,
        );
      }
      return;
    }

    for (var y = start; y <= effectiveBottom + 0.5; y += spacing) {
      final double dy = y;
      canvas.drawLine(
        Offset(0, dy),
        Offset(size.width, dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookLinesPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.lineSpacing != lineSpacing ||
        oldDelegate.topInset != topInset ||
        oldDelegate.bottomInset != bottomInset ||
        oldDelegate.lineCount != lineCount;
  }
}
