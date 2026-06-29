import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class TimerCircle extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final bool isRunning;
  final Color themeColor;
  final String timeString;
  final String statusLabel;

  const TimerCircle({
    super.key,
    required this.progress,
    required this.isRunning,
    required this.themeColor,
    required this.timeString,
    required this.statusLabel,
  });

  @override
  State<TimerCircle> createState() => _TimerCircleState();
}

class _TimerCircleState extends State<TimerCircle> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // 2-second duration for one-way, looping back-and-forth gives a 4-second full pulse period
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _glowAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isRunning) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TimerCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.animateTo(0.25, duration: const Duration(milliseconds: 500));
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final opacity = widget.isRunning ? _glowAnimation.value : 0.25;
        final blurRadius = widget.isRunning ? 24.0 + (_glowAnimation.value * 12.0) : 12.0;

        return Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.themeColor.withValues(alpha: opacity),
                  blurRadius: blurRadius,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background circle
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
                // Painter for circular progress
                CustomPaint(
                  painter: _TimerProgressPainter(
                    progress: widget.progress,
                    color: widget.themeColor,
                    backgroundColor: AppColors.border,
                  ),
                ),
                // Timer numbers & label inside the circle
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.statusLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                        color: widget.themeColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.timeString,
                      style: const TextStyle(
                        fontSize: 58,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1.0,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.isRunning ? 'RUNNING' : 'PAUSED',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimerProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _TimerProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - strokeWidth / 2;

    // Draw background track
    final trackPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // We start from the top (-pi / 2) and draw clockwise
    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
