import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KisanLoader extends StatefulWidget {
  final double size;
  final bool isSpinning; // False for static brand logo, True for active loader!
  final String? message;

  const KisanLoader({
    super.key,
    this.size = 140,
    this.isSpinning = false,
    this.message,
  });

  @override
  State<KisanLoader> createState() => _KisanLoaderState();
}

class _KisanLoaderState extends State<KisanLoader> with TickerProviderStateMixin {
  late AnimationController _gearController;
  late AnimationController _radarController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // 1. Outer gear clockwise spin
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // 2. Inner radar counter-clockwise spin
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 3. Leaf pulse glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    if (widget.isSpinning) {
      _gearController.repeat();
      _radarController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant KisanLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _gearController.repeat();
        _radarController.repeat();
      } else {
        _gearController.stop();
        _radarController.stop();
      }
    }
  }

  @override
  void dispose() {
    _gearController.dispose();
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Rotating Gear (Clockwise - Only if isSpinning)
              AnimatedBuilder(
                animation: _gearController,
                builder: (_, __) {
                  return Transform.rotate(
                    angle: widget.isSpinning ? _gearController.value * 2 * math.pi : 0,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _GearPainter(),
                    ),
                  );
                },
              ),

              // Inner Radar Telematics Ring (Counter-Clockwise - Only if isSpinning)
              AnimatedBuilder(
                animation: _radarController,
                builder: (_, __) {
                  return Transform.rotate(
                    angle: widget.isSpinning ? -_radarController.value * 2 * math.pi : 0,
                    child: CustomPaint(
                      size: Size(widget.size * 0.75, widget.size * 0.75),
                      painter: _RadarRingPainter(),
                    ),
                  );
                },
              ),

              // Center Leaf & Sprout Pulse
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final scale = 1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size * 0.38,
                      height: widget.size * 0.38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: CustomPaint(
                        painter: _LeafSproutPainter(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // KisanDrive Typography
        RichText(
          text: const TextSpan(
            style: TextStyle(fontFamily: 'sans-serif', fontSize: 22, fontWeight: FontWeight.w900),
            children: [
              TextSpan(text: 'Kisan', style: TextStyle(color: Color(0xFF22C55E))),
              TextSpan(text: 'Drive', style: TextStyle(color: Color(0xFFFACC15))),
            ],
          ),
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.message!,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tealPrimary),
          ),
        ],
      ],
    );
  }
}

class _GearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final paintGreen = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;

    final paintDark = Paint()
      ..color = const Color(0xFF0B130E)
      ..style = PaintingStyle.fill;

    // Draw 8 Heavy Lug Teeth
    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final toothPath = Path()
        ..moveTo(-8, -radius - 8)
        ..lineTo(8, -radius - 8)
        ..lineTo(6, -radius + 4)
        ..lineTo(-6, -radius + 4)
        ..close();
      canvas.drawPath(toothPath, paintGreen);
      canvas.restore();
    }

    // Outer Tread Rim Ring
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF22C55E)..style = PaintingStyle.stroke..strokeWidth = 4);
    // Inner Rim Gap
    canvas.drawCircle(center, radius - 4, paintDark);
    // Main Dynamic Wheel Rim
    canvas.drawCircle(center, radius - 12, paintGreen);
    canvas.drawCircle(center, radius - 18, paintDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintStroke = Paint()
      ..color = const Color(0xFF4ADE80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Dashed Ring
    double dashWidth = 8, dashSpace = 6, startAngle = 0;
    while (startAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashWidth / radius,
        false,
        paintStroke,
      );
      startAngle += (dashWidth + dashSpace) / radius;
    }

    // Accent beads
    final paintGold = Paint()..color = const Color(0xFFFACC15);
    canvas.drawCircle(Offset(center.dx, center.dy - radius), 3, paintGold);
    canvas.drawCircle(Offset(center.dx, center.dy + radius), 3, paintGold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LeafSproutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Left Half Gold Leaf
    final pathGold = Path()
      ..moveTo(center.dx, center.dy - r)
      ..cubicTo(center.dx - r * 0.8, center.dy - r * 0.4, center.dx - r * 0.9, center.dy + r * 0.3, center.dx, center.dy + r * 0.8)
      ..close();
    canvas.drawPath(pathGold, Paint()..color = const Color(0xFFFACC15));

    // Right Half Green Leaf
    final pathGreen = Path()
      ..moveTo(center.dx, center.dy - r)
      ..cubicTo(center.dx + r * 0.8, center.dy - r * 0.4, center.dx + r * 0.9, center.dy + r * 0.3, center.dx, center.dy + r * 0.8)
      ..close();
    canvas.drawPath(pathGreen, Paint()..color = const Color(0xFF65A30D));

    // Center Spine Line
    canvas.drawLine(
      Offset(center.dx, center.dy - r),
      Offset(center.dx, center.dy + r),
      Paint()..color = const Color(0xFF0B130E)..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
