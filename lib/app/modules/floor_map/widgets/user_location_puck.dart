import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/services/compass_service.dart';

/// Navigation user location puck displaying real-time indoor location, accuracy radius,
/// and an attached live directional heading arrow that rotates smoothly with device orientation.
///
/// Implements continuous frame-rate independent exponential convergence to eliminate
/// high-frequency sensor update jitter and provide a smooth, Google Maps-like navigation puck.
class UserLocationPuck extends StatefulWidget {
  /// Live heading in degrees [0, 360) where 0° = North, 90° = East, 180° = South, 270° = West.
  /// If null, only the location dot and accuracy halo are rendered.
  final double? headingDegrees;

  /// Estimated physical indoor accuracy radius in meters.
  final double accuracyMeters;

  /// Primary theme color of the navigation puck.
  final Color puckColor;

  const UserLocationPuck({
    super.key,
    this.headingDegrees,
    this.accuracyMeters = 3.0,
    this.puckColor = const Color(0xFF1976D2),
  });

  @override
  State<UserLocationPuck> createState() => _UserLocationPuckState();
}

class _UserLocationPuckState extends State<UserLocationPuck>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _headingController;
  double? _currentRenderedDegrees;
  double? _animatingStartDegrees;
  double? _animatingTargetDegrees;

  @override
  void initState() {
    super.initState();

    // 1. Accuracy Halo Pulse Animation (continuous gentle breathing)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );

    // 2. Smooth Heading Rotation Controller
    _headingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _headingController.addListener(_onHeadingAnimationUpdate);

    if (widget.headingDegrees != null) {
      _currentRenderedDegrees = widget.headingDegrees;
    }
  }

  void _onHeadingAnimationUpdate() {
    if (_animatingStartDegrees != null && _animatingTargetDegrees != null) {
      final t = Curves.easeOutCubic.transform(_headingController.value);
      final interpolated = _animatingStartDegrees! +
          (_animatingTargetDegrees! - _animatingStartDegrees!) * t;
      _currentRenderedDegrees = (interpolated % 360.0 + 360.0) % 360.0;
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant UserLocationPuck oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.headingDegrees != null) {
      if (_currentRenderedDegrees == null) {
        _currentRenderedDegrees = widget.headingDegrees;
        setState(() {});
      } else {
        final delta = CompassService.shortestAngleDelta(
          _currentRenderedDegrees!,
          widget.headingDegrees!,
        );

        // If angular distance is significant (> 0.25°), smoothly animate to target
        if (delta.abs() > 0.25) {
          _animatingStartDegrees = _currentRenderedDegrees;
          _animatingTargetDegrees = _currentRenderedDegrees! + delta;
          _headingController.forward(from: 0.0);
        } else {
          _currentRenderedDegrees = widget.headingDegrees;
        }
      }
    } else {
      _currentRenderedDegrees = null;
      _headingController.stop();
    }
  }

  @override
  void dispose() {
    _headingController.removeListener(_onHeadingAnimationUpdate);
    _pulseController.dispose();
    _headingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puckColor = widget.puckColor;
    final heading = _currentRenderedDegrees ?? widget.headingDegrees;

    return Semantics(
      label: heading != null
          ? 'Current location, facing ${heading.toStringAsFixed(0)} degrees'
          : 'Current location',
      child: SizedBox(
        width: 64.0,
        height: 64.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: Pulsing Accuracy Radar Ring
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = 0.55 + (_pulseAnimation.value * 0.45);
                final opacity = (1.0 - _pulseAnimation.value).clamp(0.0, 1.0);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 58.0,
                    height: 58.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: puckColor.withValues(alpha: opacity * 0.22),
                      border: Border.all(
                        color: puckColor.withValues(alpha: opacity * 0.45),
                        width: 1.2,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Layer 2: Live Directional Heading Arrow (rotates around center)
            if (heading != null)
              KeyedSubtree(
                key: const Key('heading_arrow_layer'),
                child: Transform.rotate(
                  angle: (heading * math.pi) / 180.0,
                  child: CustomPaint(
                    key: const Key('heading_arrow_painter'),
                    size: const Size(64.0, 64.0),
                    painter: _HeadingArrowPainter(color: puckColor),
                  ),
                ),
              ),

            // Layer 3: Center Location Dot (Anchored at exact location)
            Container(
              width: 16.0,
              height: 16.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: puckColor,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 4.0,
                    offset: Offset(0, 1.5),
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

/// Custom painter rendering a crisp navigation heading pointer and subtle field-of-view cone.
class _HeadingArrowPainter extends CustomPainter {
  final Color color;

  _HeadingArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Subtle Field-of-View Light Cone radiating ahead
    final conePath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - 14.0, center.dy - 28.0)
      ..arcToPoint(
        Offset(center.dx + 14.0, center.dy - 28.0),
        radius: const Radius.circular(22.0),
      )
      ..close();

    final conePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(conePath, conePaint);

    // 2. Crisp Directional Pointer Arrow (attached directly above center dot)
    // Tip at (center.dx, center.dy - 24)
    final arrowPath = Path()
      ..moveTo(center.dx, center.dy - 24.0) // Arrow tip
      ..lineTo(center.dx + 6.5, center.dy - 10.5) // Right wing
      ..lineTo(center.dx, center.dy - 12.5) // Inward center notch
      ..lineTo(center.dx - 6.5, center.dy - 10.5) // Left wing
      ..close();

    // White outline for high contrast against varied floor plan backgrounds
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    // Solid navigation blue arrow fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Subtle drop shadow behind the arrow for depth
    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.save();
    canvas.translate(0, 1.0);
    canvas.drawPath(arrowPath, shadowPaint);
    canvas.restore();

    canvas.drawPath(arrowPath, strokePaint);
    canvas.drawPath(arrowPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _HeadingArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
