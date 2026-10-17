import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../shared/widgets/nav_icons.dart';

/// The creator-side shell: four familiar top-level destinations with one clear
/// active state (design system 1.6). Recipient-facing routes live outside this
/// shell so the two experiences never share a frame.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (NavGlyph.home, 'Home'),
    (NavGlyph.create, 'Create'),
    (NavGlyph.keepsakes, 'Keepsakes'),
    (NavGlyph.profile, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            for (final (glyph, label) in _destinations)
              NavigationDestination(
                icon: NavIcon(glyph),
                selectedIcon: NavIcon(glyph, filled: true),
                label: label,
                tooltip: '',
              ),
          ],
        ),
      ),
    );
  }
}
