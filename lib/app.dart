import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/zones/zone_list_screen.dart';
import 'screens/events/event_history_screen.dart';
import 'screens/geofence/geofence_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'utils/theme.dart';

/// App root with GoRouter navigation.
///
/// GoRouter is declarative routing for Flutter. Think of it like
/// React Router or Vue Router — you define routes as a tree,
/// and navigation is URL-based under the hood.
///
/// The redirect logic here checks auth state: if not logged in,
/// redirect to /login. If logged in and on /login, redirect to /.
class MiAlarmApp extends ConsumerWidget {
  const MiAlarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authState.valueOrNull != null;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/zones',
              builder: (context, state) => const ZoneListScreen(),
            ),
            GoRoute(
              path: '/events',
              builder: (context, state) => const EventHistoryScreen(),
            ),
            GoRoute(
              path: '/geofence',
              builder: (context, state) => const GeofenceScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'miAlarm',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Bottom navigation shell that wraps all authenticated screens.
///
/// ShellRoute in GoRouter lets you have persistent UI (like a bottom nav bar)
/// that stays while the inner content changes. The [child] is the current
/// route's screen.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Determine current index from location
    final location = GoRouterState.of(context).matchedLocation;
    final index = switch (location) {
      '/' => 0,
      '/events' => 1,
      '/geofence' => 2,
      '/settings' => 3,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          final routes = ['/', '/events', '/geofence', '/settings'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Geofence',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
