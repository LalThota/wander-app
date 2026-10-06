import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/place.dart';
import '../state/app_state.dart';
import '../util.dart';
import '../widgets/filter_bar.dart';
import '../widgets/place_card.dart';
import 'detail_screen.dart';

const _fallbackTop = Color(0xFF2B2358);
const _fallbackBottom = Color(0xFF14121F);

/// Picks a layout from the available width:
/// under 700px a swipeable carousel, wider a grid with hover colours.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.loading && s.places.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s.error != null && s.places.isEmpty) {
      return _ErrorView(message: s.error!, onRetry: s.load);
    }
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 700
          ? const _WideExplore()
          : const _PhoneExplore(),
    );
  }
}

// ───────────────────────── phone ─────────────────────────

class _PhoneExplore extends StatefulWidget {
  const _PhoneExplore();

  @override
  State<_PhoneExplore> createState() => _PhoneExploreState();
}

class _PhoneExploreState extends State<_PhoneExplore> {
  final _ctrl = PageController(viewportFraction: 0.78);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_ctrl.hasClients) return;
    final p = _ctrl.page;
    if (p != null) setState(() => _page = p);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _resetScroll() {
    _page = 0;
    if (_ctrl.hasClients) _ctrl.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.visible;
    final empty = list.isEmpty;
    final maxIdx = empty ? 0 : list.length - 1;
    final pg = clampD(_page, 0, maxIdx.toDouble());
    final i = pg.floor();
    final j = math.min(i + 1, maxIdx);
    final t = pg - i;
    final nearest = pg.round();

    var top = _fallbackTop;
    var bottom = _fallbackBottom;
    if (!empty) {
      top = Color.lerp(list[i].skyTop, list[j].skyTop, t)!;
      bottom = Color.lerp(list[i].skyBottom, list[j].skyBottom, t)!;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Where to next?',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchBox(
                key: ValueKey(s.filterEpoch),
                initial: s.query,
                onChanged: (v) {
                  s.setQuery(v);
                  _resetScroll();
                },
              ),
            ),
            const SizedBox(height: 12),
            MoodChips(
              selected: s.mood,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              onSelected: (m) {
                s.setMood(m);
                _resetScroll();
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: empty
                  ? _EmptyResults(onClear: s.clearFilters)
                  : PageView.builder(
                      controller: _ctrl,
                      itemCount: list.length,
                      itemBuilder: (context, k) {
                        final d = k - pg;
                        final scale = clampD(1 - d.abs() * 0.1, 0.85, 1.0);
                        return Transform.scale(
                          scale: scale,
                          child: GestureDetector(
                            onTap: () => openPlace(context, list[k]),
                            child: PlaceCard(
                              p: list[k],
                              shift: clampD(d, -1, 1),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (!empty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 54,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      list[nearest].tagline,
                      key: ValueKey(list[nearest].id),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var k = 0; k < list.length; k++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: 6 + 20 * clampD(1 - (k - pg).abs(), 0, 1),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .fade(0.4 + 0.6 * clampD(1 - (k - pg).abs(), 0, 1)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── tablet / desktop ─────────────────────────

class _WideExplore extends StatefulWidget {
  const _WideExplore();

  @override
  State<_WideExplore> createState() => _WideExploreState();
}

class _WideExploreState extends State<_WideExplore> {
  Place? _hover;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.visible;
    final focus = (_hover != null && list.contains(_hover))
        ? _hover!
        : (list.isEmpty ? null : list.first);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            focus?.skyTop ?? _fallbackTop,
            focus?.skyBottom ?? _fallbackBottom,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Where to next?',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 320,
                        child: SearchBox(
                          key: ValueKey(s.filterEpoch),
                          initial: s.query,
                          onChanged: s.setQuery,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MoodChips(
                  selected: s.mood,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  onSelected: s.setMood,
                ),
                Expanded(
                  child: list.isEmpty
                      ? _EmptyResults(onClear: s.clearFilters)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 340,
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, k) {
                            final p = list[k];
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) => setState(() => _hover = p),
                              child: AnimatedScale(
                                scale: _hover == p ? 1.03 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _hover = p);
                                    openPlace(context, p);
                                  },
                                  child: PlaceCard(p: p),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── states ─────────────────────────

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore, size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            const Text(
              'No places match that',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another word or switch the mood filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onClear,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fallbackBottom,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            "Couldn't load places",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
