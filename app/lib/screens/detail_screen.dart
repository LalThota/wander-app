import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../models/place.dart';
import '../state/app_state.dart';
import '../util.dart';
import '../widgets/scene_painter.dart';

void openPlace(BuildContext context, Place p) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => DetailScreen(p: p),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.p});
  final Place p;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late double _days;
  late Set<String> _packed;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Start from the saved trip if there is one.
    final t = AppScope.read(context).trips[widget.p.id];
    _days = math.min(21, math.max(2, t?.days ?? 5)).toDouble();
    _packed = {...?t?.packed};
  }

  bool _isDirty(AppState s) {
    final t = s.trips[widget.p.id];
    if (t == null) return false;
    return t.days != _days.round() || !setEquals(t.packed.toSet(), _packed);
  }

  Future<void> _onSavePressed() async {
    final s = AppScope.read(context);
    final p = widget.p;
    final saved = s.trips.containsKey(p.id);
    final dirty = _isDirty(s);

    setState(() => _busy = true);
    String? err;
    String done;
    if (!saved) {
      err = await s.saveTrip(p, _days.round(), _packed);
      done = 'Saved';
    } else if (dirty) {
      err = await s.saveTrip(p, _days.round(), _packed);
      done = 'Updated';
    } else {
      err = await s.removeTrip(p.id);
      done = 'Removed';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? done),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = AppScope.of(context);
    final saved = s.trips.containsKey(p.id);
    final dirty = _isDirty(s);
    final label = !saved ? 'Save trip' : (dirty ? 'Update trip' : 'Saved');

    final bar = _SaveBar(
      p: p,
      label: label,
      filled: saved && !dirty,
      busy: _busy,
      onTap: _onSavePressed,
    );

    return Scaffold(
      backgroundColor: p.ink,
      body: LayoutBuilder(
        builder: (context, c) =>
            c.maxWidth >= 860 ? _wide(p, bar) : _narrow(p, bar),
      ),
    );
  }

  // Phone: scene on top, rounded sheet sliding over it.
  Widget _narrow(Place p, Widget bar) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final sheetTop =
                  math.min(320.0, math.max(220.0, c.maxHeight * 0.38));
              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: sheetTop + 100,
                    child: _scene(p),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    child: _back(),
                  ),
                  Positioned.fill(
                    top: sheetTop,
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.ink,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
                        children: _content(p),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bar,
      ],
    );
  }

  // Tablet / desktop: scene on the left, details on the right.
  Widget _wide(Place p, Widget bar) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Positioned.fill(child: _scene(p)),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: _back(),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
                      children: _content(p),
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: bar,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scene(Place p) => Hero(
        tag: 'scene-${p.id}',
        child: CustomPaint(
          painter: ScenePainter(p, 0),
          child: const SizedBox.expand(),
        ),
      );

  Widget _back() => IconButton.filled(
        tooltip: 'Back',
        style: IconButton.styleFrom(
          backgroundColor: Colors.black38,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      );

  List<Widget> _content(Place p) {
    final days = _days.round();
    final total = p.estimate(days);

    return [
      Text(
        p.name,
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: Colors.white,
        ),
      ),
      Text(p.country, style: TextStyle(fontSize: 15, color: p.sun)),
      const SizedBox(height: 12),
      Text(
        p.tagline,
        style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white70),
      ),
      const SizedBox(height: 22),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stat('Average', '${p.temp}°C'),
          _stat('Best time', p.season),
          _stat('Flight', p.flightTime),
        ],
      ),
      const SizedBox(height: 28),
      const Text(
        'How long are you staying?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: p.sun,
          thumbColor: p.sun,
          inactiveTrackColor: Colors.white24,
          overlayColor: p.sun.fade(0.2),
        ),
        child: Slider(
          value: _days,
          min: 2,
          max: 21,
          divisions: 19,
          label: '$days days',
          onChanged: (v) => setState(() => _days = v),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$days days',
            style: const TextStyle(fontSize: 15, color: Colors.white70),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: total.toDouble()),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, v, _) => Text(
              inr(v),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: p.sun,
              ),
            ),
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Rough total with return flight',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Text(
        'What to pack',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in p.pack)
            FilterChip(
              label: Text(item),
              selected: _packed.contains(item),
              showCheckmark: true,
              selectedColor: p.sun,
              checkmarkColor: p.ink,
              backgroundColor: Colors.white12,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: _packed.contains(item) ? p.ink : Colors.white,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (on) => setState(() {
                if (on) {
                  _packed.add(item);
                } else {
                  _packed.remove(item);
                }
              }),
            ),
        ],
      ),
      const SizedBox(height: 12),
    ];
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      );
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.p,
    required this.label,
    required this.filled,
    required this.busy,
    required this.onTap,
  });

  final Place p;
  final String label;
  final bool filled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? p.ink : Colors.white;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: busy ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 58,
              decoration: BoxDecoration(
                color: filled ? p.sun : Colors.white.fade(0.14),
                borderRadius: BorderRadius.circular(29),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  else
                    Icon(
                      filled ? Icons.favorite : Icons.favorite_border,
                      color: fg,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
