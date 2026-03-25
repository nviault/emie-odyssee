import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/ac_theme.dart';
import '../../core/rewards/reward_system.dart';

class IslandWidget extends StatefulWidget {
  final List<IslandObject> objects;
  final bool showRewardAnimation;
  final bool isLoutreActive;
  final VoidCallback onAnimationComplete;

  const IslandWidget({
    super.key,
    required this.objects,
    this.showRewardAnimation = false,
    this.isLoutreActive = true,
    required this.onAnimationComplete,
  });

  @override
  State<IslandWidget> createState() => _IslandWidgetState();
}

class _IslandWidgetState extends State<IslandWidget> with TickerProviderStateMixin {
  late AnimationController _characterController;
  late Animation<double> _characterAnimation;
  late AnimationController _objectController;
  late AnimationController _seaController;
  late AnimationController _sparkleController;

  bool _isAnimatingCharacter = false;
  bool _isShowingObject = false;

  @override
  void initState() {
    super.initState();

    // 1.5 — C) Entrée personnage (arc parabolique)
    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _characterAnimation = CurvedAnimation(
      parent: _characterController,
      curve: Curves.easeOutBack,
    );

    // 1.5 — A) Apparition reward (Spring)
    _objectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 1.6 — Mer animée
    _seaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // 1.5 — E) Sparkles de succès
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.showRewardAnimation) {
      _startRewardSequence();
    }
  }

  @override
  void didUpdateWidget(IslandWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showRewardAnimation && !oldWidget.showRewardAnimation) {
      _startRewardSequence();
    }
  }

  void _startRewardSequence() async {
    setState(() {
      _isAnimatingCharacter = true;
      _isShowingObject = false;
    });

    _sparkleController.forward(from: 0.0);
    await _characterController.forward();

    setState(() {
      _isShowingObject = true;
    });

    // Spring boing simulation 0.0 → 1.15 → 0.95 → 1.0
    await _objectController.animateTo(1.15, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    await _objectController.animateTo(0.95, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    await _objectController.animateTo(1.0, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);

    await Future.delayed(const Duration(milliseconds: 1000));

    await _characterController.reverse();

    setState(() {
      _isAnimatingCharacter = false;
      _isShowingObject = false;
    });

    widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _characterController.dispose();
    _objectController.dispose();
    _seaController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Mer animée
          AnimatedBuilder(
            animation: _seaController,
            builder: (context, child) {
              return CustomPaint(
                painter: SeaPainter(_seaController.value),
                size: Size.infinite,
              );
            },
          ),

          // L'Île (RepaintBoundary pour Bloc 5)
          RepaintBoundary(
            child: CustomPaint(
              painter: IslandPainter(),
              size: Size.infinite,
            ),
          ),

          // Objets statiques
          ...widget.objects.asMap().entries.map((entry) {
            final obj = entry.value;
            if (widget.showRewardAnimation && entry.key == widget.objects.length - 1 && _isShowingObject) {
              return const SizedBox.shrink();
            }
            return Positioned(
              left: obj.x.toDouble() * 3.5,
              top: obj.y.toDouble() * 3.5,
              child: Text(obj.icon, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),

          // Personnage animé
          if (_isAnimatingCharacter)
            AnimatedBuilder(
              animation: _characterAnimation,
              builder: (context, child) {
                double x = 100 + (100 * _characterAnimation.value);
                double y = 400 - (200 * sin(pi * _characterAnimation.value));
                return Positioned(
                  left: x,
                  top: y,
                  child: RepaintBoundary(
                    child: CharacterPainterWidget(isLoutre: widget.isLoutreActive),
                  ),
                );
              },
            ),

          // Objet en cours d'apparition
          if (_isShowingObject)
            AnimatedBuilder(
              animation: _objectController,
              builder: (context, child) {
                final lastObj = widget.objects.last;
                return Positioned(
                  left: lastObj.x.toDouble() * 3.5,
                  top: lastObj.y.toDouble() * 3.5,
                  child: Transform.scale(
                    scale: _objectController.value,
                    child: Text(lastObj.icon, style: const TextStyle(fontSize: 40)),
                  ),
                );
              },
            ),

          // Sparkles
          if (_sparkleController.isAnimating || _sparkleController.isCompleted)
             Positioned.fill(
               child: IgnorePointer(
                 child: AnimatedBuilder(
                   animation: _sparkleController,
                   builder: (context, child) {
                     return CustomPaint(
                       painter: SparklePainter(_sparkleController.value),
                     );
                   },
                 ),
               ),
             ),
        ],
      ),
    );
  }
}

class IslandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ACTheme.colorGrass
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = ACTheme.colorBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.15, size.width * 0.5, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.15, size.width * 0.9, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.85, size.width * 0.5, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.85, size.width * 0.1, size.height * 0.5)
      ..close();

    // Ombre portée plate
    canvas.drawPath(path.shift(const Offset(0, 8)), Paint()..color = const Color(0x265A3C1E));

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SeaPainter extends CustomPainter {
  final double animationValue;
  SeaPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      colors: const [ACTheme.colorWater, Color(0xFFD4F0FF), ACTheme.colorWater],
      stops: [0.0, animationValue, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant SeaPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}

class SparklePainter extends CustomPainter {
  final double progress;
  SparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final paint = Paint()
      ..color = ACTheme.colorAccentGold.withValues(alpha: 1.0 - progress)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    const starCount = 6;
    final radius = 60.0 * progress;

    for (int i = 0; i < starCount; i++) {
      double angle = (i * 2 * pi) / starCount;
      double x = center.dx + cos(angle) * radius;
      double y = center.dy + sin(angle) * radius;

      _drawStar(canvas, Offset(x, y), 8, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      double angle = (i * 4 * pi) / 5 - pi / 2;
      double x = center.dx + cos(angle) * size;
      double y = center.dy + sin(angle) * size;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) => oldDelegate.progress != progress;
}

class CharacterPainterWidget extends StatelessWidget {
  final bool isLoutre;
  const CharacterPainterWidget({super.key, required this.isLoutre});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 60),
      painter: AnimalPainter(isLoutre: isLoutre),
    );
  }
}

class AnimalPainter extends CustomPainter {
  final bool isLoutre;
  AnimalPainter({required this.isLoutre});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = isLoutre ? ACTheme.colorSecondary : ACTheme.colorSurface
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = ACTheme.colorBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Ombre plate
    canvas.drawCircle(center + const Offset(0, 4), size.width / 2, Paint()..color = const Color(0x265A3C1E));

    // Oreilles
    final earPaint = Paint()
      ..color = isLoutre ? ACTheme.colorSecondary : ACTheme.colorTextPrimary
      ..style = PaintingStyle.fill;

    if (isLoutre) {
      // Petites oreilles loutre
      canvas.drawCircle(center + Offset(-size.width * 0.3, -size.width * 0.35), 6, earPaint);
      canvas.drawCircle(center + Offset(size.width * 0.3, -size.width * 0.35), 6, earPaint);
      canvas.drawCircle(center + Offset(-size.width * 0.3, -size.width * 0.35), 6, borderPaint);
      canvas.drawCircle(center + Offset(size.width * 0.3, -size.width * 0.35), 6, borderPaint);
    } else {
      // Oreilles panda (noires)
      canvas.drawCircle(center + Offset(-size.width * 0.3, -size.width * 0.35), 10, earPaint);
      canvas.drawCircle(center + Offset(size.width * 0.3, -size.width * 0.35), 10, earPaint);
      canvas.drawCircle(center + Offset(-size.width * 0.3, -size.width * 0.35), 10, borderPaint);
      canvas.drawCircle(center + Offset(size.width * 0.3, -size.width * 0.35), 10, borderPaint);
    }

    // Corps (Cercle simple "Chibi")
    canvas.drawCircle(center, size.width / 2, bodyPaint);
    canvas.drawCircle(center, size.width / 2, borderPaint);

    // Yeux
    final eyePaint = Paint()..color = ACTheme.colorTextPrimary;

    if (isLoutre) {
      canvas.drawCircle(center + Offset(-size.width * 0.2, -2), 3, eyePaint);
      canvas.drawCircle(center + Offset(size.width * 0.2, -2), 3, eyePaint);
      // Museau
      canvas.drawCircle(center + const Offset(0, 5), 5, Paint()..color = Colors.white.withValues(alpha: 0.5));
      canvas.drawCircle(center + const Offset(0, 4), 2, eyePaint);
    } else {
      // Tâches panda
      final spotPaint = Paint()..color = ACTheme.colorTextPrimary.withValues(alpha: 0.15);
      canvas.drawOval(Rect.fromCenter(center: center + Offset(-size.width * 0.2, -2), width: 14, height: 18), spotPaint);
      canvas.drawOval(Rect.fromCenter(center: center + Offset(size.width * 0.2, -2), width: 14, height: 18), spotPaint);

      canvas.drawCircle(center + Offset(-size.width * 0.2, -2), 3, eyePaint);
      canvas.drawCircle(center + Offset(size.width * 0.2, -2), 3, eyePaint);
      // Nez
      canvas.drawCircle(center + const Offset(0, 6), 3, eyePaint);
    }

    // Joues
    final cheekPaint = Paint()..color = ACTheme.colorAccentWarm.withValues(alpha: 0.4);
    canvas.drawCircle(center + Offset(-size.width * 0.35, 8), 4, cheekPaint);
    canvas.drawCircle(center + Offset(size.width * 0.35, 8), 4, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant AnimalPainter oldDelegate) => false;
}
