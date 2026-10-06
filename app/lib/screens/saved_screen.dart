import 'package:flutter/material.dart';

import '../models/place.dart';
import '../state/app_state.dart';
import '../util.dart';
import '../widgets/scene_painter.dart';
import 'detail_screen.dart';

const _bg = Color(0xFF14121F);

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.onBrowse});

  /// Called by the empty state's button to jump back to Explore.
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    final items = <(Trip, Place)>[];
    for (final t in s.trips.values) {
      final p = s.placeById(t.destinationId);
      if (p != null) items.add((t, p));
    }
    items.sort((a, b) => b.$1.updatedAt.compareTo(a.$1.updatedAt));

    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: items.isEmpty
            ? _Empty(onBrowse: onBrowse)
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: items.length + 1,
                    itemBuilder: (context, k) {
                      if (k == 0) {
                        return const Padding(
                          padding: EdgeInsets.fromLTRB(4, 4, 4, 18),
                          child: Text(
                            'Your trips',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      final (trip, place) = items[k - 1];
                      return _TripTile(
                        trip: trip,
                        place: place,
                        onOpen: () => openPlace(context, place),
                        onRemove: () => _remove(context, s, place),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, AppState s, Place p) async {
    final err = await s.removeTrip(p.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Removed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({
    required this.trip,
    required this.place,
    required this.onOpen,
    required this.onRemove,
  });

  final Trip trip;
  final Place place;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final packedCount = trip.packed.where(place.pack.contains).length;
    final packTotal = place.pack.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white.fade(0.06),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: CustomPaint(painter: ScenePainter(place, 0)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${trip.days} days in ${place.country}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: packTotal == 0 ? 0 : packedCount / packTotal,
                          minHeight: 6,
                          color: place.sun,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Packed $packedCount of $packTotal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      inr(trip.total),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: place.sun,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove trip',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white70,
                      ),
                      onPressed: onRemove,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.luggage_outlined, size: 56, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'No trips yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save a destination and it will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onBrowse, child: const Text('Browse places')),
          ],
        ),
      ),
    );
  }
}
