// Configuración de enrutamiento de PrediGeo con go_router.
// Incluye el flujo de primer uso (onboarding → consentimiento → permisos →
// Home) mediante redirect + StartupState, y las rutas principales.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';
import '../screens/consent_screen.dart';
import '../screens/evaluation_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/measure_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/permission_rationale_screen.dart';
import '../screens/results_screen.dart';
import '../screens/settings_screen.dart';

/// Rutas de arranque que no deben redirigirse entre sí.
const _startupRoutes = <String>{
  '/onboarding',
  '/consent',
  '/permission',
};

/// Proveedor del router con redirección de arranque.
///
/// Orden: onboarding si es la primera vez, luego consentimiento, luego
/// permisos y por último Home. Las rutas de ajustes y detalle son libres.
final routerProvider = Provider<GoRouter>((ref) {
  final startup = ref.watch(startupStateProvider);
  return GoRouter(
    initialLocation: startup.initialRoute,
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;
      // Flujo de primer uso: forzar el paso correspondiente.
      if (startup.showOnboarding && location != '/onboarding') {
        return '/onboarding';
      }
      if (!startup.showOnboarding &&
          startup.showConsent &&
          location != '/consent') {
        return '/consent';
      }
      if (!startup.showOnboarding &&
          !startup.showConsent &&
          startup.showPermission &&
          location != '/permission') {
        return '/permission';
      }
      // Si el arranque terminó y estamos en una ruta de arranque, ir a Home.
      if (startup.ready && _startupRoutes.contains(location)) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: '/consent',
        builder: (BuildContext context, GoRouterState state) {
          return const ConsentScreen();
        },
      ),
      GoRoute(
        path: '/permission',
        builder: (BuildContext context, GoRouterState state) {
          return const PermissionRationaleScreen();
        },
      ),
      GoRoute(
        path: '/measure',
        builder: (BuildContext context, GoRouterState state) {
          return const MeasureScreen();
        },
      ),
      GoRoute(
        path: '/history',
        builder: (BuildContext context, GoRouterState state) {
          return const HistoryScreen();
        },
      ),
      GoRoute(
        path: '/evaluation',
        builder: (BuildContext context, GoRouterState state) {
          return const EvaluationScreen();
        },
      ),
      GoRoute(
        path: '/results',
        builder: (BuildContext context, GoRouterState state) {
          return const ResultsScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
    ],
  );
});

/// Router estático de compatibilidad (sin redirección de arranque).
/// Se conserva para pruebas que instancian pantallas directamente.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingScreen();
      },
    ),
    GoRoute(
      path: '/consent',
      builder: (BuildContext context, GoRouterState state) {
        return const ConsentScreen();
      },
    ),
    GoRoute(
      path: '/permission',
      builder: (BuildContext context, GoRouterState state) {
        return const PermissionRationaleScreen();
      },
    ),
    GoRoute(
      path: '/measure',
      builder: (BuildContext context, GoRouterState state) {
        return const MeasureScreen();
      },
    ),
    GoRoute(
      path: '/history',
      builder: (BuildContext context, GoRouterState state) {
        return const HistoryScreen();
      },
    ),
    GoRoute(
      path: '/evaluation',
      builder: (BuildContext context, GoRouterState state) {
        return const EvaluationScreen();
      },
    ),
    GoRoute(
      path: '/results',
      builder: (BuildContext context, GoRouterState state) {
        return const ResultsScreen();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) {
    return null;
  },
);
