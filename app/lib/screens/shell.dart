import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'explore_screen.dart';
import 'saved_screen.dart';

/// Bottom bar on phones, side rail on wider screens.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final count = AppScope.of(context).trips.length;

    final body = IndexedStack(
      index: _tab,
      children: [
        const ExploreScreen(),
        SavedScreen(onBrowse: () => setState(() => _tab = 0)),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 700;
        final tripsIcon = Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: const Icon(Icons.favorite_border),
        );
        final tripsIconOn = Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: const Icon(Icons.favorite),
        );

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: Text('Explore'),
                    ),
                    NavigationRailDestination(
                      icon: tripsIcon,
                      selectedIcon: tripsIconOn,
                      label: const Text('Trips'),
                    ),
                  ],
                ),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: tripsIcon,
                selectedIcon: tripsIconOn,
                label: 'Trips',
              ),
            ],
          ),
        );
      },
    );
  }
}
