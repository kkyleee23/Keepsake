import 'package:go_router/go_router.dart';

import '../data/models/enums.dart';
import '../features/creation/create_screen.dart';
import '../features/creation/recipient_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/home/home_screen.dart';
import '../features/keepsakes/keepsakes_screen.dart';
import '../features/preview/preview_screen.dart';
import '../features/profile/profile_screen.dart';
import 'home_shell.dart';

/// Centralized routing.
///
/// Creator routes live under the [HomeShell] (bottom nav). Recipient routes
/// (`/receive/:token`) will be added as a separate, shell-free route group so
/// the recipient never sees the creator chrome.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/create',
              builder: (context, state) => const CreateScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/keepsakes',
              builder: (context, state) => const KeepsakesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Focused creator flows, shown above the tab shell (no bottom nav).
    GoRoute(
      path: '/new/recipient',
      builder: (context, state) => RecipientScreen(
        occasion: state.extra as Occasion? ?? Occasion.custom,
      ),
    ),
    GoRoute(
      path: '/editor/:id',
      builder: (context, state) =>
          EditorScreen(keepsakeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/preview/:id',
      builder: (context, state) =>
          PreviewScreen(keepsakeId: state.pathParameters['id']!),
    ),

    // Recipient route group (/receive/:token) is added with publishing in the
    // next stage, deliberately outside the creator shell.
  ],
);
