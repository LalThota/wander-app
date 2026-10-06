import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/place.dart';
import '../util.dart';

/// Paints sky, sun and three layers of land or sea.
///
/// [shift] slides each layer by a different amount. Think of looking out of a
/// train window: near hills rush past while far ones barely move.
class ScenePainter extends CustomPainter {
  ScenePainter(this.p, this.shift);

  final Place p;
  final double shift;

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.skyTop, p.skyBottom],
        ).createShader(rect),
    );

    final sunCenter = Offset(s.width * 0.68 + shift * 30, s.height * 0.26);
    canvas.drawCircle(
      sunCenter,
      s.width * 0.16,
      Paint()
        ..color = p.sun.fade(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );
    canvas.drawCircle(sunCenter, s.width * 0.08, Paint()..color = p.sun);

    for (var i = 0; i < p.layers.length; i++) {
      final depth = (i + 1) / p.layers.length;
      final base = s.height * (0.46 + 0.13 * i);
      final off = shift * 60 * depth;
      final path = Path()..moveTo(0, s.height);

      if (p.peaks) {
        final rnd = math.Random(p.id.hashCode + i);
        var x = -80.0 + off;
        path.lineTo(x, base);
        while (x < s.width + 80) {
          x += 36 + rnd.nextDouble() * 50;
          path.lineTo(
            x,
            base - 16 - rnd.nextDouble() * s.height * 0.24 * (1.25 - depth),
          );
        }
        path.lineTo(s.width + 80, s.height);
      } else {
        for (double x = 0; x <= s.width; x += 4) {
          final y = base +
              math.sin((x + off * 3) / (36 + i * 22) + i * 1.7) *
                  (7 + 6 * depth);
          path.lineTo(x, y);
        }
        path.lineTo(s.width, s.height);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = p.layers[i]);
    }

    // Soft shade at the bottom so white text stays readable.
    final scrim = Rect.fromLTWH(0, s.height * 0.5, s.width, s.height * 0.5);
    canvas.drawRect(
      scrim,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x99000000)],
        ).createShader(scrim),
    );
  }

  @override
  bool shouldRepaint(ScenePainter old) => old.shift != shift || old.p != p;
}
