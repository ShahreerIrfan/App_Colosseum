import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated indoor user location puck with a center beacon, orientation heading, and pulsing radar halo.
class UserLocationPuck extends StatefulWidget {
  final double? headingDegrees;
  final double accuracyMeters;

  const UserLocationPuck({
    super.key,
    this.headingDegrees,
    this.accuracyMeters = 3.0,
  });

  @override
  State<UserLocationPuck> createState() => _UserLocationPuckState();
}

class _UserLocationPuckState extends State<UserLocationPuck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const puckColor = Color(0xFF1976D2); // High-contrast navigation blue

    return Semantics(
      label: 'Current location',
      child: SizedBox(
        width: 60.0,
        height: 60.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Radar Pulse Ring
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = 0.5 + (_pulseAnimation.value * 0.5);
                final opacity = (1.0 - _pulseAnimation.value).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 54.0,
                    height: 54.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: puckColor.withValues(alpha: opacity * 0.28),
                      border: Border.all(
                        color: puckColor.withValues(alpha: opacity * 0.5),
                        width: 1.2,
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. Heading Orientation Cone (if heading is provided)
            if (widget.headingDegrees != null)
              Transform.rotate(
                angle: (widget.headingDegrees! * math.pi) / 180.0,
                child: CustomPaint(
                  size: const Size(48.0, 48.0),
                  painter: _HeadingConePainter(color: puckColor),
                ),
              ),

            // 3. Center Location Dot
            Container(
              width: 16.0,
              height: 16.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: puckColor,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadingConePainter extends CustomPainter {
  final Color color;

  _HeadingConePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - 12.0, center.dy - 22.0)
      ..arcToPoint(
        Offset(center.dx + 12.0, center.dy - 22.0),
        radius: const Radius.circular(16.0),
      )
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withValues(alpha: 0.4),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeadingConePainter oldDelegate) =>
      oldDelegate.color != color;
}
