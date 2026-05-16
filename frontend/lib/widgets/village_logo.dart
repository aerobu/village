import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Village.ai brand yellow - warm, golden, consistent with warm palette
const Color kVillageYellow = Color(0xFFEDB92E);

/// Village.ai logo widget
/// Displays the app branding with a stylized home icon + connected hands
/// Size can be controlled via `size` parameter
class VillageLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const VillageLogo({
    Key? key,
    this.size = 48,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(height: AppTheme.spacing_sm),
          Text(
            'Village',
            style: AppTheme.displayMedium.copyWith(
              fontSize: size / 2,
              color: kVillageYellow,
            ),
          ),
          Text(
            'AI',
            style: AppTheme.labelSmall.copyWith(
              fontSize: size / 4,
              color: kVillageYellow,
              letterSpacing: 1.5,
            ),
          ),
        ],
      );
    } else {
      return _buildIcon();
    }
  }

  Widget _buildIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VillageLogoPainter(size: size),
      ),
    );
  }
}

class _VillageLogoPainter extends CustomPainter {
  final double size;

  _VillageLogoPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = kVillageYellow
      ..strokeWidth = size / 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentPaint = Paint()
      ..color = kVillageYellow
      ..strokeWidth = size / 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size / 2, size / 2);
    final radius = size / 3;

    // Draw stylized home shape (roof)
    final roofPath = Path();
    roofPath.moveTo(center.dx - radius, center.dy - radius / 2);
    roofPath.lineTo(center.dx, center.dy - radius - radius / 4);
    roofPath.lineTo(center.dx + radius, center.dy - radius / 2);

    canvas.drawPath(roofPath, paint);

    // Draw home base (square)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius / 4),
        width: radius * 1.8,
        height: radius * 1.5,
      ),
      paint,
    );

    // Draw door window (circle in center)
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius / 2),
      radius / 4,
      paint,
    );

    // Draw connecting hands (left side)
    final leftHandStart = Offset(center.dx - radius * 0.9, center.dy);
    final leftHandEnd = Offset(center.dx - radius / 3, center.dy + radius / 3);

    canvas.drawLine(leftHandStart, leftHandEnd, paint);

    // Small circle for left hand
    canvas.drawCircle(leftHandStart, radius / 6, paint);

    // Draw connecting hands (right side) - in accent color
    final rightHandStart = Offset(center.dx + radius * 0.9, center.dy);
    final rightHandEnd = Offset(center.dx + radius / 3, center.dy + radius / 3);

    canvas.drawLine(rightHandStart, rightHandEnd, accentPaint);

    // Small circle for right hand
    canvas.drawCircle(rightHandStart, radius / 6, accentPaint);

    // Draw connection point (heart) where hands meet
    final connectionPoint = Offset(center.dx, center.dy + radius / 2 + radius / 4);
    _drawHeart(canvas, connectionPoint, radius / 5, accentPaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();

    // Left bump
    path.cubicTo(
      center.dx - size * 0.6,
      center.dy - size * 0.6,
      center.dx - size,
      center.dy - size * 0.3,
      center.dx - size * 0.5,
      center.dy + size * 0.3,
    );

    // Right bump
    path.cubicTo(
      center.dx + size * 0.5,
      center.dy + size * 0.3,
      center.dx + size,
      center.dy - size * 0.3,
      center.dx + size * 0.6,
      center.dy - size * 0.6,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_VillageLogoPainter oldDelegate) => false;
}

/// Compact logo for AppBars and headers
class VillageLogoCompact extends StatelessWidget {
  final double size;

  const VillageLogoCompact({
    Key? key,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _VillageLogoPainter(size: size),
          ),
        ),
        const SizedBox(width: AppTheme.spacing_md),
        Text(
          'Village.ai',
          style: AppTheme.displayMedium.copyWith(
            fontSize: size / 1.5,
            color: kVillageYellow,
          ),
        ),
      ],
    );
  }
}
