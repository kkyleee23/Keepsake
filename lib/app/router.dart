import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/enums.dart';
import '../data/providers.dart';
import '../data/remote/supabase.dart';
import '../features/auth/auth_screen.dart';
import '../features/creation/create_screen.dart';
import '../features/creation/recipient_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/home/home_screen.dart';
import '../features/keepsakes/keepsakes_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/preview/preview_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/publishing/delivery_screen.dart';
import '../features/publishing/published_screen.dart';
import '../features/receive/receive_screen.dart';
import 'home_shell.dart';

/// Notifies GoRouter to re-evaluate its redirect when auth or onboarding change.
class _RouterRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// Centralized routing with a gate: onboarding (once) then sign-in for creators.
/// Recipient links (`/receive/:token`) are always public.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();

  final client = supabaseClientOrNull;
  StreamSubscription<AuthState>? authSub;
  if (client != null) {
    authSub = client.auth.onAuthStateChange.listen((_) => refresh.bump());
  }
  ref.listen(onboardingSeenProvider, (_, _) => refresh.bump());
  ref.onDispose(() {
    authSub?.cancel();
    refresh.dispose();
  });

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Recipients open keepsakes without an account.
      if (loc.startsWith('/receive')) return null;

      final seenOnboarding = ref.read(onboardingSeenProvider);
      final user = supabaseClientOrNull?.auth.currentUser;
      // A leftover anonymous session doesn't count as a real account.
      final signedIn = user != null && !user.isAnonymous;
      final atOnboarding = loc == '/onboarding';
      final atAuth = loc == '/auth';

      if (!seenOnboarding) return atOnboarding ? null : '/onboarding';
      if (!signedIn) return atAuth ? null : '/auth';
      if (atOnboarding || atAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/create',
              builder: (context, state) => const CreateScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/keepsakes',
              builder: (context, state) => const KeepsakesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
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
      GoRoute(
        path: '/delivery/:id',
        builder: (context, state) =>
            DeliveryScreen(keepsakeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/published/:id',
        builder: (context, state) =>
            PublishedScreen(keepsakeId: state.pathParameters['id']!),
      ),

      // Recipient route group, deliberately outside the creator shell, no account.
      GoRoute(
        path: '/receive/:token',
        builder: (context, state) =>
            ReceiveScreen(token: state.pathParameters['token']!),
      ),
    ],
  );
});
