import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ultra-lightweight, 60/120 FPS 3D Parallax Tilt Card for modern EdTech UI.
/// Creates a cutting-edge 3D depth and specular glare effect without external
/// dependencies or heavy GPU strain.
class ThreeDimensionalParallaxCard extends StatefulWidget {
  final Widget child;
  final double maxTiltAngle;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? glowColor;
  final bool enableGlare;

  const ThreeDimensionalParallaxCard({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.12, // approx 7 degrees
    this.borderRadius,
    this.onTap,
    this.glowColor,
    this.enableGlare = true,
  });

  @override
  State<ThreeDimensionalParallaxCard> createState() =>
      _ThreeDimensionalParallaxCardState();
}

class _ThreeDimensionalParallaxCardState
    extends State<ThreeDimensionalParallaxCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _resetController;
  late Animation<Offset> _tiltAnimation;

  Offset _tilt = Offset.zero;
  Offset _touchPosition = Offset.zero;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _tiltAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
        );

    _resetController.addListener(() {
      setState(() => _tilt = _tiltAnimation.value);
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final local = details.localPosition;
    final normalizedX = (local.dx / size.width) * 2 - 1;
    final normalizedY = (local.dy / size.height) * 2 - 1;

    setState(() {
      _isInteracting = true;
      _touchPosition = local;
      _tilt = Offset(
        normalizedX.clamp(-1.0, 1.0) * widget.maxTiltAngle,
        normalizedY.clamp(-1.0, 1.0) * widget.maxTiltAngle,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _tiltAnimation = Tween<Offset>(begin: _tilt, end: Offset.zero).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetController.forward(from: 0);
    setState(() => _isInteracting = false);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(24);
    final glow = widget.glowColor ?? Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Transform matrix with 3D perspective projection (m32 = 0.0012)
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(_tilt.dx)
          ..rotateX(-_tilt.dy);

        return GestureDetector(
          onTap: widget.onTap,
          onPanUpdate: (d) => _onPanUpdate(d, cardSize),
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(DragEndDetails()),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: transform,
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: _isInteracting ? 0.35 : 0.15),
                  blurRadius: _isInteracting ? 24 : 14,
                  offset: Offset(_tilt.dx * 20, _tilt.dy * 20 + 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  widget.child,

                  // Dynamic 3D Glare sheen gliding over surface
                  if (widget.enableGlare && _isInteracting)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CardGlarePainter(
                            touchPos: _touchPosition,
                            cardSize: cardSize,
                            radius: radius,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardGlarePainter extends CustomPainter {
  final Offset touchPos;
  final Size cardSize;
  final BorderRadius radius;

  _CardGlarePainter({
    required this.touchPos,
    required this.cardSize,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glareRadius = math.max(size.width, size.height) * 0.75;
    final glarePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (touchPos.dx / size.width) * 2 - 1,
          (touchPos.dy / size.height) * 2 - 1,
        ),
        radius: glareRadius / math.max(size.width, size.height),
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      radius.toRRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      glarePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CardGlarePainter oldDelegate) {
    return oldDelegate.touchPos != touchPos;
  }
}
