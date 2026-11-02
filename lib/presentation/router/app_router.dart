// Configuración de enrutamiento de la aplicación PrediGeo
// usando GoRouter con las pantallas principales.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_screen.dart';
import '../screens/measure_screen.dart';
import '../screens/history_screen.dart';
import '../screens/measurement_detail_screen.dart';
import '../screens/evaluation_screen.dart';
import '../screens/gps_debug_screen.dart';
import '../screens/onboarding_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) async {
    // Onboarding: solo se muestra la primera vez (valor persistido en
    // SharedPreferences). Si ya fue visto, se navega directamente a la home.
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    if (!seen) {
      // Si no ha visto el onboarding, cualquier pantalla (incluida la home)
      // redirige a '/onboarding'.
      return state.matchedLocation == '/onboarding' ? '/' : '/onboarding';
    }
    if (state.matchedLocation == '/onboarding') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const OnboardingScreen());
      },
    ),
    GoRoute(
      path: '/',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const HomeScreen());
      },
    ),
    GoRoute(
      path: '/measure',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const MeasureScreen());
      },
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const HistoryScreen());
      },
    ),
    GoRoute(
      path: '/history/:id',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return _buildPage(state, MeasurementDetailScreen(id: id ?? 0));
      },
    ),
    GoRoute(
      path: '/evaluation',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const EvaluationScreen());
      },
    ),
    GoRoute(
      path: '/gps-debug',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const GpsDebugScreen());
      },
    ),
  ],
);

CustomTransitionPage<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
