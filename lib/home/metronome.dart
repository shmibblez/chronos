// todo: here will be metronome to show beats
// have cool idea for beat indicators
//  - component will be square, fills max width

import 'dart:math';

import 'package:chronos/cubits/chronos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// sun god Helios provides cool looking beat indicator
class Helios extends StatefulWidget {
  const Helios({super.key});

  @override
  State<StatefulWidget> createState() {
    return HeliosState();
  }
}

class HeliosState extends State with SingleTickerProviderStateMixin {
  // late final Chronos _chronos;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // _chronos = BlocProvider.of<Chronos>(context);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 50),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final chronos = BlocProvider.of<Chronos>(context);
    return Expanded(
      child: SizedBox(
        width: double.maxFinite,
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return CustomPaint(
                painter: _Rays(
                  beatsPerBar: chronos.beatsPerBar,
                  currentBeatNumber: chronos.state,
                  progress: chronos.progress,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _Rays extends CustomPainter {
  _Rays({
    required this.beatsPerBar,
    required this.currentBeatNumber,
    required this.progress,
  });

  final int beatsPerBar;
  final int currentBeatNumber;
  final double progress;

  // center space radius where bpm is displayed
  // static const double _cr = 8;
  static const double _sw = 16;
  static const double _2sw = _sw * 2;

  @override
  void paint(Canvas canvas, Size size) {
    // draws lines in circle with
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _sw;
    final bgCirclePaint = Paint()
      ..color = Colors.white38
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _sw;
    final bgPaint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _2sw;
    final activeBgPaint = Paint()
      ..color = Colors.white24
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _2sw;
    final double _cr = 6.0 * beatsPerBar + 6.0;
    final double w = size.width;
    final double h = size.height;
    // stroke width
    // center coordinates
    final double cx = w / 2;
    final double cy = h / 2;
    // line length
    final double l = cx - _cr - _2sw / 2;
    // changing variables
    double angle = 0;
    double angleOffset = 0;
    if (beatsPerBar == 2) {
      angleOffset = pi / 4;
    } else if (beatsPerBar % 2 == 0) {
      // if even
      if ((beatsPerBar / 2) % 2 == 0) {
        // if divisible by 2
        angleOffset = pi / beatsPerBar;
      } else {
        // if not divisible by 2
        angleOffset = 0;
      }
    } else {
      // if odd
      if ((beatsPerBar - 1) / 2 % 2 == 0) {
        // if divisible by 2
        angleOffset = pi / beatsPerBar / 2;
      } else {
        // if not divisible by 2
        angleOffset = -pi / beatsPerBar / 2;
      }
    }
    for (int i = 0; i < beatsPerBar; i++) {
      angle = -2 * pi * i / beatsPerBar + angleOffset;
      // circle / start line coordinates
      final double sx = cx + _cr * cos(angle);
      final double sy = cy - _cr * sin(angle); // minus since y is flipped
      // line end coordinates
      final double ex = sx + l * cos(angle);
      // minus since y is flipped
      final double ey = sy - l * sin(angle);

      // draw line backdrops
      if (i != currentBeatNumber) {
        canvas.drawLine(
          Offset(sx, sy),
          Offset(ex, ey),
          bgPaint,
        );
        canvas.drawCircle(Offset(ex, ey), _sw / 2, bgCirclePaint);
      } else {
        // draw line backdrops
        canvas.drawLine(
          Offset(sx, sy),
          Offset(ex, ey),
          activeBgPaint,
        );
        canvas.drawCircle(Offset(ex, ey), _sw / 2, linePaint);
      }

      // draw circles / lines
      if (i == beatsPerBar - 1 && currentBeatNumber == 0 ||
          i == currentBeatNumber - 1 ||
          i == currentBeatNumber) {
        // if current beat or beat before, draw line
        // percent is flipped for beat line before current
        final double percent = i == currentBeatNumber ? progress : 1 - progress;
        // progress line end coordinates
        final double pex = sx + l * percent * cos(angle);
        final double pey = sy - l * percent * sin(angle);
        canvas.drawLine(Offset(sx, sy), Offset(pex, pey), linePaint);
      } else {
        // else draw circle
        canvas.drawCircle(Offset(sx, sy), _sw / 2, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // always repaint since animating
    return true;
  }
}
