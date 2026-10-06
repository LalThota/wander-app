import 'package:flutter/material.dart';

import '../models/place.dart';
import '../util.dart';
import 'scene_painter.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.p, this.shift = 0});

  final Place p;
  final double shift;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${p.name}, ${p.country}. Opens details.',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: 'scene-${p.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: CustomPaint(
                    painter: ScenePainter(p, shift),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    p.country,
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Pill('${p.temp}°C'),
                      _Pill(p.season),
                    ],
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

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.fade(0.22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
}
