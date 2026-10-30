import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lingo_sync/features/ai_mentor/data/models/mentor_state.dart';

/// Ultra-modern, lightweight 3D Reactive Holographic Orb for Live Voice HUD.
/// Uses mathematical spherical projections and wave harmonics on Canvas
/// for locked 60/120 FPS performance with zero memory overhead on budget devices.
class ThreeDimensionalOrb extends StatefulWidget {
  final MentorPhase phase;
  final double amplitude;
  final VoidCallback onTap;
  final double size;

  const ThreeDimensionalOrb({
    super.key,
    required this.phase,
    required this.amplitude,
    required this.onTap,
    this.size = 170.0,
  });

  @override
  State<ThreeDimensionalOrb> createState() => _ThreeDimensionalOrbState();
}

class _ThreeDimensionalOrbState extends State<ThreeDimensionalOrb>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _Holographic3DOrbPainter(
              phase: widget.phase,
              amplitude: widget.amplitude,
              rotation: _rotationController.value * 2 * math.pi,
              pulse: _pulseController.value,
            ),
          );
        },
      ),
    );
  }
}

class _Holographic3DOrbPainter extends CustomPainter {
  final MentorPhase phase;
  final double amplitude;
  final double rotation;
  final double pulse;

  _Holographic3DOrbPainter({
    required this.phase,
    required this.amplitude,
    required this.rotation,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 2) * 0.72;

    // Determine state palette
    final OrbPalette palette = _getPalette(phase);

    // 1. Draw Outer Atmospheric Glow
    final glowRadius =
        baseRadius * (1.25 + (amplitude * 0.35) + (pulse * 0.08));
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.primary.withValues(alpha: 0.45),
          palette.secondary.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // 2. Draw 3D Orbital Rings (Gyroscopic Rings tilted in 3D perspective)
    _draw3DRings(canvas, center, baseRadius, palette);

    // 3. Draw Core 3D Sphere with Specular Ray Shading
    final dynamicRadius = baseRadius * (1.0 + (amplitude * 0.18));
    final sphereRect = Rect.fromCircle(center: center, radius: dynamicRadius);

    // Deep base ambient sphere
    final baseSpherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.95,
        colors: [
          palette.highlight,
          palette.primary,
          palette.secondary,
          palette.darkVoid,
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, dynamicRadius, baseSpherePaint);

    // 4. Draw Reactive Wave Harmonics across the surface
    _drawSurfacePlasmaWaves(canvas, center, dynamicRadius, palette);

    // 5. Draw 3D Specular Highlight (Simulating physical glossy glass light reflection)
    final specularCenter = Offset(
      center.dx - (dynamicRadius * 0.35),
      center.dy - (dynamicRadius * 0.35),
    );
    final specularPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.25),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: specularCenter,
              radius: dynamicRadius * 0.45,
            ),
          );
    canvas.drawCircle(specularCenter, dynamicRadius * 0.35, specularPaint);

    // 6. Draw Center State Icon
    _drawStateIcon(canvas, center, dynamicRadius);
  }

  void _draw3DRings(
    Canvas canvas,
    Offset center,
    double radius,
    OrbPalette palette,
  ) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final numRings = (phase == MentorPhase.receivingAudio || amplitude > 0.05)
        ? 4
        : 2;

    for (int i = 0; i < numRings; i++) {
      final ringAngle = rotation + (i * math.pi / numRings);
      final ringRadius = radius * (1.12 + (i * 0.1) + (amplitude * 0.2));
      final ringColor = (i % 2 == 0 ? palette.primary : palette.secondary)
          .withValues(alpha: 0.35 + (0.35 * amplitude));

      ringPaint.color = ringColor;

      // Draw ellipse representing tilted 3D orbit
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(ringAngle);

      final ovalRect = Rect.fromCenter(
        center: Offset.zero,
        width: ringRadius * 2,
        height: ringRadius * 0.65,
      );
      canvas.drawOval(ovalRect, ringPaint);

      // Orbital energy node
      final nodeX = ringRadius * math.cos(rotation * 2 + i);
      final nodeY = (ringRadius * 0.325) * math.sin(rotation * 2 + i);
      final nodePaint = Paint()
        ..color = palette.highlight
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nodeX, nodeY), 3.0, nodePaint);

      canvas.restore();
    }
  }

  void _drawSurfacePlasmaWaves(
    Canvas canvas,
    Offset center,
    double radius,
    OrbPalette palette,
  ) {
    if (amplitude < 0.02 && phase != MentorPhase.settingUp) return;

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = palette.highlight.withValues(alpha: 0.45 + (amplitude * 0.5));

    final path = Path();
    const segments = 36;
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final waveOffset =
          math.sin((angle * 5) + (rotation * 4)) *
          (radius * 0.12 * (amplitude + 0.1));
      final r = (radius * 0.88) + waveOffset;
      final x = center.dx + (r * math.cos(angle));
      final y = center.dy + (r * math.sin(angle));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, wavePaint);
  }

  void _drawStateIcon(Canvas canvas, Offset center, double radius) {
    IconData icon;
    if (phase == MentorPhase.aiDisconnected ||
        phase == MentorPhase.disconnected) {
      icon = Icons.refresh_rounded;
    } else if (phase == MentorPhase.receivingAudio) {
      icon = Icons.volume_up_rounded;
    } else if (phase == MentorPhase.connecting ||
        phase == MentorPhase.settingUp) {
      icon = Icons.hourglass_top_rounded;
    } else {
      icon = Icons.mic_rounded;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: radius * 0.46,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white.withValues(alpha: 0.95),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );
  }

  OrbPalette _getPalette(MentorPhase phase) {
    switch (phase) {
      case MentorPhase.receivingAudio:
        // Mentor Speaking: Radiant Gold / Sunset Coral
        return OrbPalette(
          highlight: const Color(0xFFFFF275),
          primary: const Color(0xFFFF8C42),
          secondary: const Color(0xFFFF3C38),
          darkVoid: const Color(0xFF4A0E17),
        );
      case MentorPhase.ready:
        // User Listening / Mic Active: Vibrant Emerald / Neon Mint
        return OrbPalette(
          highlight: const Color(0xFF70FFD4),
          primary: const Color(0xFF00E676),
          secondary: const Color(0xFF00897B),
          darkVoid: const Color(0xFF002920),
        );
      case MentorPhase.connecting:
      case MentorPhase.settingUp:
        // Thinking / Connecting: Electric Violet / Neon Magenta
        return OrbPalette(
          highlight: const Color(0xFFF384FF),
          primary: const Color(0xFF9D4EDD),
          secondary: const Color(0xFF5A189A),
          darkVoid: const Color(0xFF10002B),
        );
      case MentorPhase.aiDisconnected:
      case MentorPhase.disconnected:
        // Disconnected: Crimson / Amber Warning
        return OrbPalette(
          highlight: const Color(0xFFFFD166),
          primary: const Color(0xFFEF476F),
          secondary: const Color(0xFFB7094C),
          darkVoid: const Color(0xFF260410),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _Holographic3DOrbPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude ||
        oldDelegate.rotation != rotation ||
        oldDelegate.phase != phase ||
        oldDelegate.pulse != pulse;
  }
}

class OrbPalette {
  final Color highlight;
  final Color primary;
  final Color secondary;
  final Color darkVoid;

  OrbPalette({
    required this.highlight,
    required this.primary,
    required this.secondary,
    required this.darkVoid,
  });
}
